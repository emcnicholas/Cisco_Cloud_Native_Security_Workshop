// Variables //
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
        default = "us-east-2"
}
variable "FTD_version" {
    default = "ftdv-6.7.0"
}
variable "ftd_user" {
    default = "admin"
}
variable "ftd_pass" {}
variable "lab_id" {}
variable "vpc_name" {
    default = "CNS_Lab"
}
//AWS Availability Zones
variable "aws_az1" {
    default = "us-east-2a"
}
variable "aws_az2" {
    default = "us-east-2b"
}
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}
//Subnet and IP addresses
variable "outside_subnet" {
    default = "10.0.0.0/24"
}
variable "ftd_outside_ip_list" {
    type = list(string)
    default = ["10.0.0.10","10.0.0.11"]
}
variable "ftd_outside_ip" {
    default = "10.0.0.10"
}
variable "eks_outside_ip" {
    default = "10.0.0.11"
}
variable "inside_subnet" {
    default = "10.0.1.0/24"
}
variable "ftd_inside_ip" {
    default = "10.0.1.10"
}
variable "mgmt_subnet" {
    default = "10.0.2.0/24"
}
variable "ftd_mgmt_ip" {
    default = "10.0.2.10"
}
variable "diag_subnet" {
    default = "10.0.3.0/24"
}
variable "inside2_subnet" {
    default = "10.0.4.0/24"
}
variable "ftd_size" {
  default = "c5.xlarge"
}
//  Existing SSH Key on the AWS
variable "key_name" {
  default = "ftd_key"
}
// EKS Cluster Name
variable "cluster-name" {
  default = "CNS_Lab"
}
// Remote Hosts //
variable "remote_hosts" {
    default = ["0.0.0.0/0"]
}

// Local Variables //
locals {
  eks_cluster_name = "${var.cluster-name}_${var.lab_id}"
  vpc_name = "${var.vpc_name}_${var.lab_id}"
  outside_ips = aws_network_interface.ftd_outside.private_ips
}