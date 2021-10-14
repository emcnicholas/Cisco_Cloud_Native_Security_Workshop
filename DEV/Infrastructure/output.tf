// Outputs //

output "dev_ftd_mgmt_ip" {
  value = module.Infrastructure.ftd_mgmt_ip
}
output "dev_eks_public_ip" {
  value = module.Infrastructure.eks_public_ip
}
output "dev_eks_cluster_name" {
  value = module.Infrastructure.eks_cluster_name
}