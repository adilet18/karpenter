
#~~~~~~~~~~~~~~~~~~~~~~~~ vpc variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "env" {
  type    = string
  default = "prod"
}


variable "my_ip" {
  default = "212.42.127.114/32"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  default = [
    "10.0.11.0/24",
    "10.0.22.0/24"
  ]
}

# variable "private_subnet_tags" {}

#~~~~~~~~~~~~~~~~~~~~~~~~ node_group variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# variable "node_security_group_tags" {}

# variable "enable_irsa" {
#   type    = bool
#   default = true
# }

# variable "node_group_iam_role_name" {
#   type = string
# }


variable "node_groups" {
  type = map(any)
  default = {
    first = {
      node_group_name = "node-group-1"
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      ami_type        = "AL2_x86_64"
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.medium"]
      disk_size       = 20

    },
    /*  second = {
      node_group_name = "node-group-2"
      desired_size    = 3
      max_size        = 6
      min_size        = 2
      ami_type        = "AL2_x86_64"
      instance_types  = ["t3.medium"]
    }
*/
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~ eks_cluster variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "cluster"
}

variable "cluster_version" {
  description = "EKS Cluster version."
  type        = string
  default     = "1.28"
}

variable "wait_for_cluster_timeout" {
  description = "A timeout (in seconds) to wait for cluster to be available."
  type        = number
  default     = 300
}


