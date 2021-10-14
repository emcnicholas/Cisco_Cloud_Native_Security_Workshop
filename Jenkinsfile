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
        GITHUB_TOKEN           = credentials('github_token')
        MY_REPO                = 'emcnicholas/Cisco_Cloud_Native_Security_Workshop.git' //ex: github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git'
        FTD_PASSWORD           = credentials('ftd-password')
        SCA_SERVICE_KEY        = credentials('sca-service-key')
        SW_API_KEY             = credentials('sw-api-key')
        SW_API_SEC             = credentials('sw-api-sec')
        SW_URL                 = 'https://tet-pov-rtp1.cpoc.co'
        SW_ROOT_SCOPE          = '605bacee755f027875a0eef3'
        DEV_EKS_HOST           = '<dev eks host ip>'
        PROD_EKS_HOST          = '<prod eks host ip>'
        REMOTE_HOSTS           = '["71.175.93.211/32","64.100.11.232/32","100.11.24.79/32"]' //ex: ["172.16.1.1", "192.168.2.2"]
    }
    tools {
        terraform 'Terraform 1.0.3'
        dockerTool 'Docker'
    }

    stages{
        stage('SCM Checkout'){
            steps{
                git branch: 'main', url: 'https://$GITHUB_TOKEN@github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git'
            }
        }
        stage('Build DEV Infrastructure'){
            steps{
                dir("DEV/Infrastructure"){
                    sh 'terraform get -update'
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve \
                    -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
                    -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
                    -var="lab_id=$DEV_LAB_ID" \
                    -var="region=$DEV_AWS_REGION" \
                    -var="aws_az1=$DEV_AWS_AZ1" \
                    -var="aws_az2=$DEV_AWS_AZ2" \
                    -var="ftd_pass=$FTD_PASSWORD" \
                    -var="key_name=ftd_key" \
                    -var="remote_hosts=$REMOTE_HOSTS"'
                    //sh 'docker run -v $(pwd)/Ansible:/ftd-ansible/playbooks -v $(pwd)/Ansible/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml'
                }
            }
        }
// Comment out if you are NOT deploying Secure Cloud Analytics or Secure Workload
        stage('Build DEV Cisco Secure Cloud Native Security'){
            steps{
                dir("DEV/Applications"){
                    sh 'terraform get -update'
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve \
                    -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
                    -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
                    -var="lab_id=$DEV_LAB_ID" \
                    -var="region=$DEV_AWS_REGION" \
                    -var="aws_az1=$DEV_AWS_AZ1" \
                    -var="aws_az2=$DEV_AWS_AZ2" \
                    -var="sca_service_key=$SCA_SERVICE_KEY" \
                    -var="secure_workload_api_key=$SW_API_KEY" \
                    -var="secure_workload_api_sec=$SW_API_SEC" \
                    -var="secure_workload_api_url=$SW_URL" \
                    -var="secure_workload_root_scope=$SW_ROOT_SCOPE"'
                }
            }
        }
//         stage('Test DEV Application'){
//             steps{
//                 httpRequest consoleLogResponseBody: true, ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://$DEV_EKS_HOST:30001', validResponseCodes: '200', wrapAsMultipart: false
//             }
//         }
//         stage('Deploy PROD Infrastructure'){
//             steps{
//                 dir("PROD/Infrastructure"){
//                     sh 'terraform init'
//                     sh 'terraform apply -auto-approve \
//                     -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
//                     -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
//                     -var="lab_id=$PROD_LAB_ID" \
//                     -var="region=$PROD_AWS_REGION" \
//                     -var="aws_az1=$PROD_AWS_AZ1" \
//                     -var="aws_az2=$PROD_AWS_AZ2" \
//                     -var="ftd_pass=$FTD_PASSWORD" \
//                     -var="key_name=ftd_key"
//                     -var="remote_hosts=$REMOTE_HOSTS"'
//                     //sh 'docker run -v $(pwd)/Ansible:/ftd-ansible/playbooks -v $(pwd)/Ansible/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml'
//                 }
//             }
//         }
// // Comment out if you are NOT deploying Secure Cloud Analytics or Secure Workload
//         stage('Deploy PROD Cisco Secure Cloud Native Security'){
//             steps{
//                 dir("PROD/Applications"){
//                     sh 'terraform init'
//                     sh 'terraform apply -auto-approve \
//                     -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
//                     -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
//                     -var="lab_id=$PROD_LAB_ID" \
//                     -var="region=$PROD_AWS_REGION" \
//                     -var="aws_az1=$PROD_AWS_AZ1" \
//                     -var="aws_az2=$PROD_AWS_AZ2" \
//                     -var="sca_service_key=$SCA_SERVICE_KEY" \
//                     -var="secure_workload_api_key=$SW_API_KEY" \
//                     -var="secure_workload_api_sec=$SW_API_SEC" \
//                     -var="secure_workload_api_url=$SW_URL" \
//                     -var="secure_workload_root_scope=$SW_ROOT_SCOPE"'
//                 }
//             }
//         }
//         stage('Test PROD Application'){
//             steps{
//                 httpRequest consoleLogResponseBody: true, ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://$PROD_EKS_HOST:30001', validResponseCodes: '200', wrapAsMultipart: false
//             }
//         }

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!CAUTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Terraform Destroy Stages for Testing - Only uncomment to destroy everything
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Destroy Infrastructure
//         stage('Destroy DEV Cisco Secure Cloud Native Security'){
//             steps{
//                 dir("DEV/Applications"){
//                     catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
//                         sh 'terraform state rm tetration_scope.scope'
//                         sh 'terraform state rm tetration_scope.yelb_app_scope'
//                         sh 'terraform state rm tetration_scope.nginx_app_scope'
//                         sh 'terraform destroy -auto-approve \
//                         -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
//                         -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
//                         -var="lab_id=$DEV_LAB_ID" \
//                         -var="region=$DEV_AWS_REGION" \
//                         -var="aws_az1=$DEV_AWS_AZ1" \
//                         -var="aws_az2=$DEV_AWS_AZ2" \
//                         -var="sca_service_key=$SCA_SERVICE_KEY" \
//                         -var="secure_workload_api_key=$SW_API_KEY" \
//                         -var="secure_workload_api_sec=$SW_API_SEC" \
//                         -var="secure_workload_api_url=$SW_URL" \
//                         -var="secure_workload_root_scope=$SW_ROOT_SCOPE"'
//                     }
//                 }
//             }
//         }
//         stage('Destroy PROD Cisco Secure Cloud Native Security'){
//             steps{
//                 dir("PROD/Applications"){
//                     catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
//                         sh 'terraform state rm tetration_scope.scope'
//                         sh 'terraform state rm tetration_scope.yelb_app_scope'
//                         sh 'terraform state rm tetration_scope.nginx_app_scope'
//                         sh 'terraform destroy -auto-approve \
//                         -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
//                         -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
//                         -var="lab_id=$PROD_LAB_ID" \
//                         -var="region=$PROD_AWS_REGION" \
//                         -var="aws_az1=$PROD_AWS_AZ1" \
//                         -var="aws_az2=$PROD_AWS_AZ2" \
//                         -var="sca_service_key=$SCA_SERVICE_KEY" \
//                         -var="secure_workload_api_key=$SW_API_KEY" \
//                         -var="secure_workload_api_sec=$SW_API_SEC"'
//                     }
//                 }
//             }
//         }
//         stage('Destroy DEV Infrastructure'){
//             steps{
//                 dir("DEV/Infrastructure"){
//                     sh 'terraform destroy -auto-approve \
//                     -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
//                     -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
//                     -var="lab_id=$DEV_LAB_ID" \
//                     -var="region=$DEV_AWS_REGION" \
//                     -var="aws_az1=$DEV_AWS_AZ1" \
//                     -var="aws_az2=$DEV_AWS_AZ2" \
//                     -var="ftd_pass=$FTD_PASSWORD" \
//                     -var="key_name=ftd_key"'
//                 }
//             }
//         }
//         stage('Destroy PROD Infrastructure'){
//             steps{
//                 dir("PROD/Infrastructure"){
//                     sh 'terraform destroy -auto-approve \
//                     -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
//                     -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
//                     -var="lab_id=$PROD_LAB_ID" \
//                     -var="region=$PROD_AWS_REGION" \
//                     -var="aws_az1=$PROD_AWS_AZ1" \
//                     -var="aws_az2=$PROD_AWS_AZ2" \
//                     -var="ftd_pass=$FTD_PASSWORD" \
//                     -var="key_name=ftd_key"'
//                 }
//             }
//         }
        // End of Destroy //
    }
}