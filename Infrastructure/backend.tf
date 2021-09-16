terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    token = "bEXJPLIp7THOw.atlasv1.rsZdq09aOVUvwz2qkYzWSToE6GVLWYqiA95oS8ZaieyyvjpaJtOBN5cy9zyKykW79zY"
    organization = "edmcnich"

    workspaces {
      name = "CNS_Infrastructure"
    }
  }
}
