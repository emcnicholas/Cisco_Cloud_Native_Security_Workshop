// Pipeline

pipeline{
    agent any
    environment {
        LAB_NAME               = 'CNS_Lab'
        DEV_LAB_ID             = 'Dev'
        PROD_LAB_ID            = 'Prod'
        AWS_ACCESS_KEY_ID      = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY  = credentials('aws-secret-key')
        DEV_AWS_REGION         = 'us-east-2'
        PROD_AWS_REGION        = 'us-east-1'
        DEV_AWS_AZ1            = 'us-east-2a'
        DEV_AWS_AZ2            = 'us-east-2b'
        PROD_AWS_AZ1           = 'us-east-1a'
        PROD_AWS_AZ2           = 'us-east-1b'
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
                git branch: 'main', url: 'https://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@github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git'
            }
        }
//         stage('Build Infrastructure'){
//             steps{
//                 dir("Infrastructure"){
//                     sh 'terraform init'
//                     sh 'terraform apply -auto-approve -var="aws_access_key=$AWS_ACCESS_KEY_ID" -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="lab_id=$DEV_LAB_ID" -var="region=$DEV_AWS_REGION" -var="aws_az1=$DEV_AWS_AZ1" -var="aws_az2=$DEV_AWS_AZ2" -var="ftd_pass=$FTD_PASSWORD" -var="key_name=ftd_key"'
//                 }
//             }
//         }
//         stage('Deploy Secure Cloud Analytics'){
//             steps{
//                 dir("Applications"){
//                     sh 'terraform init'
//                     sh 'terraform apply -auto-approve -var="aws_access_key=$AWS_ACCESS_KEY_ID" -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="lab_id=333" -var="region=us-east-2" -var="sca_service_key=$SCA_SERVICE_KEY" -var="secure_workload_api_key=$SW_API_KEY" -var="secure_workload_api_sec=$SW_API_SEC"'
//                 }
//             }
//         }
//         stage('Deploy Secure Firewall'){
//             steps{
//                 dir("Infrastructure"){
//                     sh 'docker run -v $(pwd)/Ansible:/ftd-ansible/playbooks -v $(pwd)/Ansible/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml'
//                 }
//             }
//         }
//         stage('Test Application'){
//             steps{
//                 httpRequest ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://3.18.251.162:30001', wrapAsMultipart: false
//             }
//         }
        stage('Destroy'){
            steps{
                dir("Infrastructure"){
                    sh 'terraform init'
                    sh 'terraform destroy -auto-approve -var="aws_access_key=$AWS_ACCESS_KEY_ID" -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="lab_id=$LAB_ID" -var="ftd_pass=$FTD_PASSWORD" -var="region=us-east-2" -var="key_name=ftd_key"-var="region=$DEV_AWS_REGION" -var="aws_az1=$DEV_AWS_AZ1" -var="aws_az2=$DEV_AWS_AZ2"'
                }
            }
        }
    }
}