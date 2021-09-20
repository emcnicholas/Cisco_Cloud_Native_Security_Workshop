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

data "template_file" "jenkinsfile" {
  template = file("${path.root}/../Jenkinsfile")
  vars = {
    eks_public_ip = aws_eip.eks_outside_EIP.public_ip
  }
}