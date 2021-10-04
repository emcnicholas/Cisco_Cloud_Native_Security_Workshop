// Variables //
variable "aws_access_key" {
  description = "AWS Access Key"
}
variable "aws_secret_key" {
  description = "AWS Secret Key"
}
variable "region" {
  description = "AWS Region ex: us-east-1"
}

//AWS Availability Zones
variable "aws_az1" {
  description = "AWS Availability Zone 1 ex: us-east-1a"
}
variable "aws_az2" {
  description = "AWS Availability Zone 2 ex: us-esst-2b"
}

// EKS Cluster Name
variable "cluster-name" {
  description = "AWS EKS Cluster name"
  default = "CNS_Lab"
}
variable "lab_id" {
  description = "ID associated with this lab instance"
}

// Secure Cloud Analytics Service Key //
// Uncomment the variable below if deploying Secure Cloud Analytics
variable "sca_service_key" {
  description = "Secure Cloud Analytics Service Key"
}

// Secure Cloud Workload API Key and Secret//
// Uncomment the 3 variables below if deploying Secure Workload
variable "secure_workload_api_key" {
  description = "Secure Workload API Key"
}
variable "secure_workload_api_sec" {
  description = "Secure Workload API Secret"
}
variable "secure_workload_api_url" {
  description = "Secure Workload URL ex: https://FQDN"
}
variable "secure_workload_root_scope" {
  description = "The ID of the Secure Workload Root Scope"
}

// Secure Cloud Native Access and Secret Key //
// Uncomment the 2 variables below if deploying Secure Cloud Native
//variable "securecn_access_key" {}
//variable "securecn_secret_key" {}

// Local Variables //
locals {
  eks_cluster_name = "${var.cluster-name}_${var.lab_id}"
}