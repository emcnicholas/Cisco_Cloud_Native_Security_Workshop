terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    token = var.tf_cloud_token
    organization = var.tf_cloud_org

    workspaces {
      name = var.tf_cloud_ws
    }
  }
}
