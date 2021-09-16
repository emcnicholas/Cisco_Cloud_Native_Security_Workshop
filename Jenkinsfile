// Pipeline

pipeline{
    agent any
    tools {
        terraform 'Terraform 1.0.3'
        dockerTool 'Docker'
    }
    environment {
        AWS_ACCESS_KEY_ID      = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY  = credentials('aws-secret-key')
        TERRAFORM_ACCESS_TOKEN = credentials('tf-cloud-token')
        GITHUB_ACCESS_TOKEN    = credentials('github-access-token')
    }

    stages{
        stage('SCM Checkout'){
            steps{
                git branch: 'main', url: 'https://${GITHUB_ACCESS_TOKEN}@github.com/emcnicholas/Cisco_Cloud_Native_Security_Part2.git'
            }
        }
    }
}