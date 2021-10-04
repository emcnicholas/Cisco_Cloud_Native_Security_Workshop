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
variable "ftd_user" {
  description = "Secure Firewall Username"
  default = "admin"
}
variable "ftd_pass" {
  description = "Secure Firewall Password"
}
variable "lab_id" {
  description = "ID associated with this lab instance"
}
variable "vpc_name" {
  description = "VPC Name"
  default = "CNS_Lab"
}
//AWS Availability Zones
variable "aws_az1" {
  description = "AWS Availability Zone 1 ex: us-east-1a"
}
variable "aws_az2" {
  description = "AWS Availability Zone 2 ex: us-east-1b"
}
variable "key_name" {
  description = "SSH key created in AWS region this deployment is being deployed to"
}
