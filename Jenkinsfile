// Pipeline

pipeline{
    agent any
    environment {
        AWS_ACCESS_KEY_ID      = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY  = credentials('aws-secret-key')
        TERRAFORM_ACCESS_TOKEN = credentials('tf-cloud-token')
        GITHUB_ACCESS_TOKEN    = credentials('github-access-token')
        FTD_PASSWORD           = credentials('ftd-password')
    }
    tools {
        terraform 'Terraform 1.0.3'
        dockerTool 'Docker'
    }

    stages{
        stage('SCM Checkout'){
            steps{
                git branch: 'main', url: 'https://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@github.com/emcnicholas/Cisco_Cloud_Native_Security_Part2.git'
            }
        }
        stage('Build Infrastructure'){
            steps{
                dir("Infrastructure"){
                    sh 'pwd'
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve -var="aws_access_key=$AWS_ACCESS_KEY_ID" -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="lab_id=333" -var="ftd_pass=$FTD_PASSWORD" -var="region=us-east-2" -var="key_name=ftd_key"'
                }
            }
        }
    }
}