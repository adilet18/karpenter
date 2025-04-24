locals {
  node_groups = {
    for x in var.node_groups :
    "${x.max_size}/${x.min_size}" => x
  }
}
