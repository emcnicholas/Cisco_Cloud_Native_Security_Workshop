

// Install the Secure Workload Daemonset //
resource "null_resource" "update-kubeconfig" {
  depends_on = []
  provisioner "local-exec" {
      working_dir = path.root
      command = "aws eks --region ${var.region} update-kubeconfig --name ${local.eks_cluster_name}"
  }
}