// Main

module "Infrastructure" {
  source = "github.com/emcnicholas/Cisco_Cloud_Native_Security_Infrastructure"
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  region         = var.region
  ftd_user       = var.ftd_user
  ftd_pass       = var.ftd_pass
  lab_id         = var.lab_id
  aws_az1        = var.aws_az1
  aws_az2        = var.aws_az2
  key_name       = var.key_name
  remote_hosts   = ["71.175.93.211/32","64.100.11.232/32","100.11.24.79/32"]
}
