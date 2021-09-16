terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    token = "xHMxcpe2UCVsOQ.atlasv1.5Fa6TA80N2ZlWHoyB6zI0fWPEBTm9jwYaHubC6f2o6AVYVDLMBhjpvu5HalyqQsL1Fk"
    organization = "edmcnich"

    workspaces {
      name = "CNS_Applications"
    }
  }
}