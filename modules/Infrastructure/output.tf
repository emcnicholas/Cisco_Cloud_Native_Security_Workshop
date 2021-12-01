/////////////
// Outputs //
/////////////

// FTD management IP address to access UI //
output "ftd_mgmt_ip" {
  value = aws_eip.ftd_mgmt_EIP.public_ip
}

// Public IP address of EKS node to access web apps //
output "eks_public_ip" {
  value = aws_eip.eks_outside_EIP.public_ip
}

// EKS Cluster name
output "eks_cluster_name" {
  value = "${var.vpc_name}_${var.lab_id}"
}

// EKS Cluster API Endpoint
output "eks_cluster_api_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}