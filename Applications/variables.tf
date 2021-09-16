// Variables //
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
        default = "us-east-2"
}

//AWS Availability Zones
variable "aws_az1" {
    default = "us-east-2a"
}
variable "aws_az2" {
    default = "us-east-2b"
}

// EKS Cluster Name
variable "cluster-name" {
  default = "CNS_Lab"
}
variable "lab_id" {
  default = "1"
}
variable "vpc_name" {
    default = "CNS_Lab"
}
// Secure Cloud Analytics Service Key //
// Uncomment the variable below if deploying Secure Cloud Analytics
variable "sca_service_key" {}

// Secure Cloud Workload API Key and Secret//
// Uncomment the 3 variables below if deploying Secure Workload
variable "secure_workload_api_key" {}
variable "secure_workload_api_sec" {}
variable "secure_workload_api_url" {
  default = "https://tet-pov-rtp1.cpoc.co"
}

// Secure Cloud Native Access and Secret Key //
// Uncomment the 2 variables below if deploying Secure Cloud Native
//variable "securecn_access_key" {}
//variable "securecn_secret_key" {}

// Local Variables //
locals {
  eks_cluster_name = "${var.cluster-name}_${var.lab_id}"
  vpc_name = "${var.vpc_name}_${var.lab_id}"
}