// Create inventory file with AWS IP address variables //

data "aws_instance" "eks_node_instance" {
  depends_on = [aws_autoscaling_group.eks-node-autoscaling-group]
  filter {
    name = "tag:Name"
    values = ["${local.eks_cluster_name}_node"]
  }
}
resource "local_file" "host_file" {
  depends_on = [aws_autoscaling_group.eks-node-autoscaling-group, aws_instance.ftdv]
    content     = <<-EOT
    ---
    all:
      hosts:
        ftd:
          ansible_host: ${aws_eip.ftd_mgmt_EIP.public_ip}
          ansible_network_os: ftd
          ansible_user: ${var.ftd_user}
          ansible_password: ${var.ftd_pass}
          ansible_httpapi_port: 443
          ansible_httpapi_use_ssl: True
          ansible_httpapi_validate_certs: False
          eks_inside_ip: ${data.aws_instance.eks_node_instance.private_ip}
          eks_outside_ip: ${aws_eip_association.eks_outside_ip_association.private_ip_address}
    EOT
    filename = "${path.module}/Ansible/hosts.yaml"
}