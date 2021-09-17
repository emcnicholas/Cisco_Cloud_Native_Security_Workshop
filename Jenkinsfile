// Pipeline

pipeline{
    agent any
    environment {
        LAB_NAME               = 'CNS_Lab'
        LAB_ID                 = '333'
        AWS_ACCESS_KEY_ID      = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY  = credentials('aws-secret-key')
        AWS_REGION             = 'us-east-2'
        TERRAFORM_ACCESS_TOKEN = credentials('tf-cloud-token')
        GITHUB_ACCESS_TOKEN    = credentials('github-access-token')
        FTD_PASSWORD           = credentials('ftd-password')
        SCA_SERVICE_KEY        = credentials('sca-service-key')
        SW_API_KEY             = credentials('sw-api-key')
        SW_API_SEC             = credentials('sw-api-sec')
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
                    sh 'terraform apply -auto-approve -var="aws_access_key=$AWS_ACCESS_KEY_ID" -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="lab_id=$LAB_ID" -var="ftd_pass=$FTD_PASSWORD" -var="region=us-east-2" -var="key_name=ftd_key"'
                }
            }
        }
        stage('Deploy Secure Cloud Analytics'){
            steps{
                dir("Applications"){
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve -var="aws_access_key=$AWS_ACCESS_KEY_ID" -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="lab_id=333" -var="region=us-east-2" -var="sca_service_key=$SCA_SERVICE_KEY" -var="secure_workload_api_key=$SW_API_KEY" -var="secure_workload_api_sec=$SW_API_SEC"'
                }
            }
        }
        stage('Deploy Secure Workload'){
            steps{
                dir("Applications"){
                    sh 'aws eks --region us-east-2 update-kubeconfig --name CNS_Lab_333'
                }
            }
        }
    }
}