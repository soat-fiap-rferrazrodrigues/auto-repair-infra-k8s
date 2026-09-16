output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

# Consumed by the database stack through terraform_remote_state.
output "vpc_id" {
  description = "VPC id shared with the database and Lambda stacks"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet ids used by RDS and the auth Lambda"
  value       = module.vpc.private_subnets
}

output "node_security_group_id" {
  description = "Security group of the EKS worker nodes (allowed into RDS)"
  value       = module.eks.node_security_group_id
}
