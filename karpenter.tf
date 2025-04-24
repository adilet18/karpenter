locals {
  capacity_type = ["on-demand"]
  allowed_instance_types = [
    "m5.xlarge",
    "m5.2xlarge",
    "c5.large",
    "c5.xlarge",
    "c5.2xlarge",
    "m5.large",
  ]
  allowed_instance_type_java = [
    "m5.large",
    "m5.xlarge",
    "m5.2xlarge",
    "m5.4xlarge",
  ]
  allowed_instance_type_golang = [
    "c5.large",
    "c5.xlarge",
    "c5.2xlarge"
  ]
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.cluster.name
}

data "aws_region" "current" {}




resource "local_file" "karpenter_provisioner_golang" {
  filename = "${path.module}/karpenter_provisioner_golang.yaml"
  content = templatefile("${path.module}/karpenter_provisioner_golang.tpl", {
    cluster_name = aws_eks_cluster.cluster.name
  })
}


resource "local_file" "karpenter_provisioner_java" {
  filename = "${path.module}/karpenter_provisioner_java.yaml"
  content = templatefile("${path.module}/karpenter_provisioner_java.tpl", {
    cluster_name = aws_eks_cluster.cluster.name
  })
}




resource "kubernetes_namespace" "karpenter" {
  depends_on = [aws_eks_cluster.cluster]
  metadata {
    name = "karpenter"
  }
}

# Configure the OIDC-backed identity provider to allow the Karpenter
# ServiceAccount to assume the role. This will actually create the role
# for us too.
module "iam_assumable_role_karpenter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.7.0"
  create_role                   = true
  role_name                     = "karpenter-controller"
  provider_url                  = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_fully_qualified_subjects = ["system:serviceaccount:${kubernetes_namespace.karpenter.id}:karpenter"]
}

resource "aws_iam_role_policy" "karpenter_contoller" {
  name = "karpenter-policy"
  role = module.iam_assumable_role_karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${aws_eks_cluster.cluster.name}"
  role = aws_iam_role.eks_node.name
}

resource "helm_release" "karpenter" {
  depends_on = [kubernetes_namespace.karpenter, module.iam_assumable_role_karpenter]
  namespace  = kubernetes_namespace.karpenter.id
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.9.0"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_karpenter.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.name
  }

  set {
    name  = "clusterEndpoint"
    value = aws_eks_cluster.cluster.endpoint
  }
  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}

# data "kubectl_path_documents" "provisioner_manifests" {
#   pattern = "./karpenter_provisioner_*.yaml"
#   vars = {
#     cluster_name = aws_eks_cluster.cluster.name
#   }
#   depends_on = [local_file.karpenter_provisioner_golang, local_file.karpenter_provisioner_java]
# }

# resource "kubectl_manifest" "provisioners" {
#   for_each  = data.kubectl_path_documents.provisioner_manifests.manifests
#   yaml_body = each.value
# }

locals {
  provisioner_files = fileset("./karpenter_provisioner_", "*.yaml")
}

resource "kubectl_manifest" "provisioners" {
  depends_on = [local_file.karpenter_provisioner_golang, local_file.karpenter_provisioner_java]
  for_each   = local.provisioner_files
  yaml_body  = file("./karpenter-provisioner-manifests/${each.value}")
}

