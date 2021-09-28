// Global Variables

// AWS Environment
aws_access_key     = ""
aws_secret_key     = ""
lab_id             = "" // Lab ID (can be anything, but needs to be unique
remote_hosts       = ["10.10.10.10", "172.16.12.12"] //Remote hosts that will have access to environment
region             = ""
aws_az1            = ""
aws_az2            = ""

// FTD Variables
FTD_version        = "ftdv-6.7.0" //Allowed Values = ftdv-6.7.0, ftdv-6.6.0,
ftd_user           = "admin"
ftd_pass           = ""
key_name           = "" //SSH key created in AWS Region

// Secure Cloud Analytics
// Uncomment the line below and add service key if deploying Secure Cloud Analytics
//sca_service_key    = ""

// Secure Cloud Workload
// Uncomment the 3 variables below if deploying Secure Workload
//secure_workload_api_key = ""
//secure_workload_api_sec = ""
//secure_workload_api_url = "https://<secure_workload_host>"
//secure_workload_root_scope = ""

// Secure Cloud Native
// Uncomment the 2 lines below and add access key and secret key if deploying Secure Cloud Native
//securecn_access_key = ""
//securecn_secret_key = ""