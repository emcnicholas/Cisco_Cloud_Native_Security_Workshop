// Run Ansible Playbook to configure FTD //

// Check Status of FTD Management - Make sure it is responding //
resource "null_resource" "ftd_status" {
  depends_on = [local_file.host_file]
  provisioner "local-exec" {
      working_dir = "${path.module}/Ansible"
      command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_status.yaml"
  }
}

// Initial FTP provisioning //
resource "null_resource" "ftd_init_prov" {
  depends_on = [null_resource.ftd_status]
  provisioner "local-exec" {
      working_dir = "${path.module}/Ansible"
      command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_initial_provisioning.yaml"
  }
}

// FTD Configuration //
resource "null_resource" "ftd_conf" {
  depends_on = [null_resource.ftd_init_prov]
  provisioner "local-exec" {
      working_dir = "${path.module}/Ansible"
      command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml"
  }
}