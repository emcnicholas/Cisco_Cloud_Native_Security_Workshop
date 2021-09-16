// Providers //

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.4.1"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.11.3"
    }
//    portshift = {
//      source  = "localdomain/provider/portshift"
//      version = ">= 1.0.2"
//    }

    tetration = {
      source = "CiscoDevNet/tetration"
      version = "0.1.0"
    }
  }
}
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region     =  var.region
}
// Kubernetes Configuration
data "aws_eks_cluster" "eks_cluster" {
  name = "CNS_Lab_${var.lab_id}"
}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = "CNS_Lab_${var.lab_id}"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
  //load_config_file       = false
}
//provider "kubernetes" {
//  config_path = "~/.kube/config"
//}

provider "kubectl" {
  host = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.eks_cluster_auth.token
  load_config_file       = false
}

//provider "portshift" {
//  portshift_server_url = "securecn.cisco.com"
//  access_key = var.securecn_access_key
//  secret_key = var.securecn_secret_key
//}

provider "tetration" {
  api_key = var.secure_workload_api_key
  api_secret = var.secure_workload_api_sec
  api_url = var.secure_workload_api_url
  disable_tls_verification = false
}