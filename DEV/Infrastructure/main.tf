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
  remote_hosts   = [""] //ex:["172.16.1.1", "192.168.2.2"]
}
