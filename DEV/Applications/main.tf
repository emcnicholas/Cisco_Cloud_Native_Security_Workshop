// Application Module to deploy Cisco Secure Cloud Analytics and Secure Workload

module "Applications" {
  source = "github.com/emcnicholas/Cisco_Cloud_Native_Security_Applications"
  aws_access_key             = var.aws_access_key
  aws_secret_key             = var.aws_secret_key
  region                     = var.region
  lab_id                     = var.lab_id
  aws_az1                    = var.aws_az1
  aws_az2                    = var.aws_az2
  sca_service_key            = var.sca_service_key
  secure_workload_api_key    = var.secure_workload_api_key
  secure_workload_api_sec    = var.secure_workload_api_sec
  secure_workload_api_url    = var.secure_workload_api_url
  secure_workload_root_scope = var.secure_workload_root_scope
}