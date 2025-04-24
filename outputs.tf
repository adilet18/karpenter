#=========================== vpc-outputs ===============================

output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

#=========================== eks-outputs ===============================

# output "eks_name" {
#   value = module.eks.cluster_name
# }

# output "eks_certificate_authority" {
#   value = module.eks.cluster_certificate_authority_data
# }

# output "eks_endpoint" {
#   value = module.eks.cluster_endpoint
# }

# output "eks_arn" {
#   value = module.eks.cluster_arn
# }

output "eks_name" {
  value = aws_eks_cluster.cluster.name
}

output "eks_arn" {
  value = aws_eks_cluster.cluster.arn
}

output "eks_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "eks_certificate_authority" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "alb_role_arn" {
  value = aws_iam_role.aws_lb_controller_role.arn
}


output "node_group_names" {
  value = local.node_groups
}

