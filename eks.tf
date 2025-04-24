#=========================== EKS Cluster ==============================
resource "aws_eks_cluster" "cluster" {
  name     = "${var.env}-${var.cluster_name}"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    security_group_ids      = flatten([aws_security_group.cluster.id, aws_security_group.worker_group_mgmt.id])
    subnet_ids              = aws_subnet.private_subnet[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_security_group_rule.cluster_egress_internet,
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy
  ]

  lifecycle {
    create_before_destroy = false
    #ignore_changes        = [vpc_config]
  }
}

#==================== EKS Cluster's Security Group ====================
resource "aws_security_group" "cluster" {
  name_prefix = "${var.env}-${var.cluster_name}"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "SG-${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  description       = "Allow cluster egress access to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "${var.env}-worker-sg-mgmt"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Ingress rule for Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Ingress rule for Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                     = "eks-worker-sg"
    "karpenter.sh/discovery" = "prod-cluster"
  }
}


#======================= EKS Cluster's IAM Roles ========================
resource "aws_iam_role" "cluster" {
  name = "${var.env}-${var.cluster_name}-iam"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterAssumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceControllerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# module "eks" {
#   source = "terraform-aws-modules/eks/aws"

#   version                         = "~> 19.0"
#   cluster_name                    = "prod-cluster"
#   cluster_version                 = "1.28"
#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   vpc_id     = aws_vpc.main.id
#   subnet_ids = aws_subnet.private_subnet[*].id

#   cluster_addons = {
#     coredns = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#     }
#     aws-ebs-csi-driver = {
#       most_recent = true
#     }
#   }

#   node_security_group_additional_rules = {
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       self        = true
#     }
#     egress_all = {
#       description      = "Node all egress"
#       protocol         = "-1"
#       from_port        = 0
#       to_port          = 0
#       type             = "egress"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["::/0"]
#     }
#   }

#   ## Type of VMs by defaults
#   eks_managed_node_group_defaults = {
#     ami_type       = "AL2_x86_64"
#     instance_types = ["t3.large", "m5.large", "t3a.large"]
#     iam_role_additional_policies = {
#       additional = aws_iam_policy.additional.arn
#     }
#     autoscaling_group_tags = {
#       "k8s.io/cluster-autoscaler/enabled" : true,
#       "k8s.io/cluster-autoscaler/prod-cluster" : "owned",
#     }
#     iam_role_attach_cni_policy = true
#   }

#   ### Node Groups configuration

#   eks_managed_node_groups = {
#     spot = {
#       name            = "spot-v2"
#       use_name_prefix = false

#       subnet_ids = aws_subnet.private_subnet[*].id

#       min_size     = 1
#       max_size     = 5
#       desired_size = 3


#       # capacity_type        = "SPOT"
#       force_update_version = true
#       instance_types       = ["t3.medium"]

#       update_config = {
#         max_unavailable_percentage = 25
#       }
#     }
#     on_demand_1 = {
#       name            = "on-demand-1-v3"
#       use_name_prefix = false

#       subnet_ids = aws_subnet.private_subnet[*].id

#       min_size     = 1
#       max_size     = 5
#       desired_size = 1

#       force_update_version = true
#       instance_types       = ["t3.medium"]

#       update_config = {
#         max_unavailable_percentage = 25
#       }
#     }
#     on_demand_2 = {
#       name            = "on-demand-2-v3"
#       use_name_prefix = false

#       subnet_ids = aws_subnet.private_subnet[*].id

#       min_size     = 1
#       max_size     = 5
#       desired_size = 1

#       force_update_version = true
#       instance_types       = ["t3.medium"]

#       update_config = {
#         max_unavailable_percentage = 25
#       }
#     }
#   }
#   # manage_aws_auth_configmap = true

#   ## User management self-managed nodes

#   aws_auth_users = [

#   ]

#   tags = {}
# }
