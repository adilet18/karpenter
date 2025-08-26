

# data "aws_eks_node_group" "eks-node-group" {
#   cluster_name    = aws_eks_cluster.cluster.name
#   for_each        = aws_eks_node_group.workers
#   node_group_name = each.value.node_group_name
# }


# resource "time_sleep" "wait_for_kubernetes" {

#   depends_on = [aws_eks_cluster.cluster]

#   create_duration = "20s"
# }

# resource "kubernetes_namespace" "kube-namespace" {
#   depends_on = [data.aws_eks_node_group.eks-node-group, time_sleep.wait_for_kubernetes]
#   metadata {

#     name = "prometheus"
#   }
# }

# resource "helm_release" "prometheus" {
#   depends_on       = [kubernetes_namespace.kube-namespace, time_sleep.wait_for_kubernetes]
#   name             = "prometheus"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-prometheus-stack"
#   namespace        = kubernetes_namespace.kube-namespace.id
#   create_namespace = true
#   version          = "45.7.1"
#   values = [
#     file("~/karpenter/eks/values.yaml")
#   ]
#   timeout = 2000


#   set {
#     name  = "podSecurityPolicy.enabled"
#     value = true
#   }

#   set {
#     name  = "server.persistentVolume.enabled"
#     value = false
#   }

#   set {
#     name = "server\\.resources"
#     value = yamlencode({
#       limits = {
#         cpu    = "200m"
#         memory = "50Mi"
#       }
#       requests = {
#         cpu    = "100m"
#         memory = "30Mi"
#       }
#     })
#   }
# }



