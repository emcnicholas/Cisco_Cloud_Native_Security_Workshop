# Cisco Cloud Native Security Workshop
This repository will give detailed instructions on how to deploy Cisco Security solutions in a cloud native environment.
The instructions will walk through deploying infrastructure and applications in AWS using Terraform and Ansible while 
securing them using Cisco Secure Firewall, Secure Cloud Analytics, Secure Workload, and Secure CN.
In part 1 of this 2 part series we will develop our Infrastructure as Code (IoC) using a local development environment.
We will build out and deploy the Terraform and Ansible code to instantiate an AWS Virtual Private Cloud (VPC),
Elastic Kubernetes Service (EKS) cluster, and a Cisco Secure Firewall instance. We will then deploy Cisco Secure Cloud Analytics,
Secure Workload, and Secure CN to provide security monitoring, policy, and controls to the cloud native environment.
In part 2 of series, we will take what we learned in part 1 and integrate the code into a continuous delivery pipeline
using Jenkins and Github.

![Cisco Cloud Native Security](/images/cns-diagram.png)

**We are in process of building a DevNet Sandbox for this environment, but for now you will need to have the following
prerequisites installed.**

## Prerequisites
The following software is mandatory to run this code successfully. Cisco Secure Firewall will be deployed using an eval 
license on AWS.
All other solutions, such as Cisco Secure Cloud Analytic, Secure Workload, and Secure CN are **Optional**.
* **Terraform** >= v1.0t (https://www.terraform.io/downloads.html)
* **Ansible** >= 2.9 (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* **AWS Environment** (Need admin access to API, IAM, VPC, EC2, EKS)
* **AWS CLI** >= 2.1.# (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
* **Git** >= 2.# (https://git-scm.com/downloads)
* **Github Account** (https://github.com/join)
* **Kubernetes command-line tool (kubectl)** >= 1.21 https://kubernetes.io/docs/tasks/tools/
* **Docker** >= 20.10.# (https://docs.docker.com/get-docker/)
* **(Optional) Jenkins**  (https://www.jenkins.io/doc/book/installing/)
* **(Optional) Integrated Development Environment** (IDE)  
* **(Optional) Cisco Secure Cloud Analytics Account** (https://www.cisco.com/c/en/us/products/security/stealthwatch/stealthwatch-cloud-free-offer.html)
* **(Optional) Cisco Secure Workload Account**
* **(optional) Cisco Secure CN Account**

## Part 1

## Instructions

### Set up the Terraform project
1. First thing to do is to set up a project on your local environment. From your IDE or the CLI create a project 
   directory to work in.
   You can name the directory whatever you would like. Clone
   [This Repository](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git)
   to your project directory and move into the /Cisco_Cloud_Native_Security_Workshop directory. Take a look inside the 
   directory.
   
   ```
   [devbox] $ git clone https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git
   Cloning into 'Cisco_Cloud_Native_Security_Workshop'...
   remote: Enumerating objects: 373, done.
   remote: Counting objects: 100% (373/373), done.
   remote: Compressing objects: 100% (264/264), done.
   remote: Total 373 (delta 191), reused 288 (delta 106), pack-reused 0
   Receiving objects: 100% (373/373), 26.65 MiB | 18.84 MiB/s, done.
   Resolving deltas: 100% (191/191), done.
   [devbox Cisco_Cloud_Native_Security_Workshop]$ ls
   DEV  images  Jenkinsfile  Lab_Build  LICENSE  PROD  README.md
   ```


2. We will be building out this environment locally using the **`Lab_Build`** directory. If you take a look into the 
   directory we will have all the terraform, and ansible files need to deploy our infrastructure. 
   
   Open the 
   [terraform.tfvars](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/terraform.tfvars)
   file first. We need to create a few global variables in our project. Terraform uses a *variable definitions file* to 
   set these global variables. The file must be named **`terraform.tfvars`** or any name ending in **`.auto.tfvars`**. 
   In this case we created a file called **`terraform.tfvars`**. Let's take a look at the file:
   
   ```
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
   ```

   These variables are defined globally, so they will be passed to any variables declared in any other terraform files 
   in this project. 
   
   **These variables must be assigned!** 
   
   Here we configure the: 
   * **`aws_access_key`** and **`aws_secret_key`** to authenticate to the AWS API
   * VPC **`region`** and availability zone (**`aws_az1`** and **`aws_az2`**)
   * **`lab_id`** which is appended to the end of all the resources that will be created
   * **`remote_hosts`** which is used to permit access inbound to the FTD mgmt interface and EKS API (Add you public IP address here)
   * **`FTD_version`** is the version of FTDv we use from the AWS Marketplace
   * **`ftd_user`** and `ftd_pass` is the username and password we configure on the FTD instance
   * **`key_name`** is the ssh key created on AWS to access EC2 instances. This must be created previous to running terraform 
     ([Create SSH Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)).

3. Next we create a variables file to use in our terraform module. If you are asking "didn't we just create a variables
   file", we did but at a global level. Now we need to configure the variables at the module level. A module is a 
   container for multiple resources that are used together. Modules can be used to create lightweight abstractions, 
   so that you can describe your infrastructure in terms of its architecture, rather than directly in terms of physical 
   objects. The **`.tf`** files in your working directory when you run terraform plan or terraform apply together form the 
   root module. That module may call other modules and connect them together by passing output values from one to input 
   values of another.
   The top directory, in this case **`Lab_Build`** is assigned to the **Root** module. We can create multiple directories 
   under the root module that would be defined as **Nested Modules**. In part 1 we will only be using the **Root**
   module to develop our IaC, but in part 2 we will use **Nested Modules** to partition our code.
   Open the [variables.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/variables.tf).
   The **`variables.tf`** file will define all the variables used in the 
   **Root** module. Like I said above, the **`terraform.tfvars`** file sets global variables for all modules, but this
   **`variables.tf`** file sets variables just for the root module. The cool thing about the variables set in this file is 
   that we can now set defaults. What this allows us to do is only set variables in the **`terraform.tfvars`** files that
   we need to change for our environment and leave all the other variables in the **`variables.tf`** file as default.
   
   ```
   // Variables //
   variable "aws_access_key" {
     description = "AWS Access Key"
   }
   variable "aws_secret_key" {
     description = "AWS Secret Key"
   }
   variable "region" {
     description = "AWS Region ex: us-east-1"
   }
   variable "FTD_version" {
     description = "Secure Firewall Version"
     default = "ftdv-6.7.0"
   }
   variable "ftd_user" {
     description = "Secure Firewall Username"
     default = "admin"
   }
   variable "ftd_pass" {
     description = "Secure Firewall Password"
   }
   variable "lab_id" {
     description = "ID associated with this lab instance"
   }
   ...data omitted
   ```

   In the **`variables.tf`** file we have a bunch of additional variables that are defined for the VPC such as subnets, 
   network addresses, eks cluster info, and a lot more. If you noticed, some variables have defaults assigned, and some 
   don't. We can assign any of these variables in the **`terraform.tfvars`** and it will take precedence over the defaults. 
   The variables that **Do Not** have defaults need to be assigned in **`terraform.tfvars`**. For example, lets say we wanted
   to use a different IP address for **`variable "ftd_outside_ip"`**. All we need to do is assign that variable in the 
   **`terraform.tfvars`** as such:
   >ftd_outside_ip = 10.0.0.99
   
   This will declare the **`ftd_outside_ip`** as **`10.0.0.99`** instead of the default **`10.0.0.10`** when we apply our terraform
   files. Now that we have all the variables defined lets start building some Infrastructure as Code.
   
### Building the Infrastructure as Code
In the following steps we configure code to deploy a VPC, EKS Cluster, and FTDv instance.

1. When using Terraform to deploy IaC the first thing we need are providers. A Terraform Provider represents an 
   integration that is responsible for understanding API interactions with the underlying infrastructure, such as a 
   public cloud service (AWS, GCP, Azure), a PaaS service (Heroku), a SaaS service (DNSimple, CloudFlare), or on-prem 
   resources (vSphere). The Provider then exposes these as resources that Terraform users can interface with, from 
   within Terraform a configuration.
   
   We can add these providers to any of our terraform files, but in our case we added them to the **`main.tf`**
   file. Open the 
   [main.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/main.tf) file and
   take a look.

   ```
   // Providers //
   
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 3.0"
       }
       kubernetes = {
         source = "hashicorp/kubernetes"
         version = "2.4.1"
       }
       kubectl = {
         source = "gavinbunney/kubectl"
         version = "1.11.3"
       }
     }
   }
   provider "aws" {
       access_key = var.aws_access_key
       secret_key = var.aws_secret_key
       region     =  var.region
   }
   // Kubernetes Configuration
   data "aws_eks_cluster" "eks_cluster" {
     depends_on = [aws_eks_cluster.eks_cluster]
     name = "CNS_Lab_${var.lab_id}"
   }
   ...data omitted
   ```

   We will discuss the additional providers later in this document, but for now let's go over the AWS provider. This
   provider will download all the resources we need to configure zones, CIDRs, subnets, addresses, VPCs, Internet
   Gateways, EKS Clusters, EC2 instance, etc.... All we need to provide is the **`access_key`**, **`secret_key`** and 
   **`region`**.
   Each AWS region has its own provider. 

   
2. Now that we have the AWS provider we can configure AWS resources. We created a file named **`vpc.tf`** just for the VPC
   configuration. We could stick all of our resources in one file, such as **`main.tf`**, but this becomes hard to manage 
   once our configuration grows to thousands of lines. So we segment our code into smaller manageable files. The **`vpc.tf`**
   has a lot of configuration, such as: 
   * VPC configuration
   * Subnets
   * Security Groups
   * Network Interfaces
   * Internet gateway
   * Routes
   * Elastic IP address (public IP addresses)
   
   All these resources deploy the AWS network infrastructure. Open file  
   [vpc.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/vpc.tf) file and
   take a look.

   
3. Now that there is a network, next we created a file for the Cisco Secure Firewall (FTDv) instance called **`ftdv.tf`**. 
   The FTDv will attach to all the network interfaces and subnets assigned in the **`vpc.tf`** file. Let's take a look at 
   the [ftdv.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/ftdv.tf) file.
   
   First we pull the AWS AMI data source 
   ([what's a data source?](https://www.terraform.io/docs/language/data-sources/index.html))
   from the AWS Marketplace:

   ```
   data "aws_ami" "ftdv" {
     #most_recent = true      // you can enable this if you want to deploy more
     owners      = ["aws-marketplace"]
   
    filter {
       name   = "name"
       values = ["${var.FTD_version}*"]
     }
   
     filter {
       name   = "product-code"
       values = ["a8sxy6easi2zumgtyr564z6y7"]
     }
   
     filter {
       name   = "virtualization-type"
       values = ["hvm"]
     }
   }
   ```
   Then we create our instance using the AMI data we collected and assign network interfaces to it using the interface
   IDs we created in the VPC. 
   
   ```
   // Cisco NGFW Instances //
   
   data "template_file" "startup_file" {
   template = file("${path.root}/startup_file.json")
   vars = {
     ftd_pass = var.ftd_pass
     lab_id = var.lab_id
   }
   
   resource "aws_instance" "ftdv" {
       ami                 = data.aws_ami.ftdv.id
       instance_type       = var.ftd_size
       key_name            = var.key_name
       availability_zone   = var.aws_az1
   
   
     network_interface {
       network_interface_id = aws_network_interface.ftd_mgmt.id
       device_index         = 0
   
     }
   
     network_interface {
       network_interface_id = aws_network_interface.ftd_diag.id
       device_index         = 1
     }
      network_interface {
       network_interface_id = aws_network_interface.ftd_outside.id
       device_index         = 2
     }
   
       network_interface {
       network_interface_id = aws_network_interface.ftd_inside.id
       device_index         = 3
     }
   
     user_data = data.template_file.startup_file.rendered
   
     tags = {
     Name = "${local.vpc_name} FTDv"
     }
   }
   ```
   
   Also notice the **`"template_file" "startup_file"`** data source. This refers to a **`startup_file.json`** file
   we want to bootstrap the AWS instance. In this case the 
   [startup_file.json](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/startup_file.json) 
   contains the FTDv admin password, hostname, and management type:
   ```
   {
       "AdminPassword": "${ftd_pass}",
       "Hostname": "FTD-${lab_id}",
       "ManageLocally": "Yes"
   }
   ```

4. Now we add AWS EKS to deploy are application on. In this use case we are only using 1 worker node with no load
   balancing instance (just to save some money). We created the **`eks.tf`** file which deploys our EKS cluster and worker nodes.
   In addition to the snippet below there are other resources created such as AWS IAM Roles, Policies, and 
   Security Groups.
   
   Check out the [eks.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/eks.tf) 
   file.
   ```
   ...data omitted
   
   // Kubernetes Master Cluster //
   resource "aws_eks_cluster" "eks_cluster" {
     name            = local.eks_cluster_name
     role_arn        = aws_iam_role.eks-cluster-role.arn
   
     vpc_config {
       security_group_ids = [aws_security_group.eks-cluster-sg.id]
       subnet_ids         = [aws_subnet.inside_subnet.id, aws_subnet.inside2_subnet.id]
     }
   
     depends_on = [
       aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
       aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
     ]
   }
   
   ...data omitted
   
   resource "aws_launch_configuration" "eks-node-launch-config" {
     associate_public_ip_address = false
     iam_instance_profile        = aws_iam_instance_profile.eks-iam-instance-profile.name
     image_id                    = data.aws_ami.eks-worker.id
     instance_type               = "m4.large"
     name_prefix                 = local.eks_cluster_name
     security_groups             = [
       aws_security_group.eks-node-sg.id]
     user_data_base64            = base64encode(local.eks-node-userdata)
   
     lifecycle {
       create_before_destroy = true
     }
   }
   
   // Create an AutoScaling Group that actually launches EC2 instances based on the AutoScaling Launch Configuration
   resource "aws_autoscaling_group" "eks-node-autoscaling-group" {
     desired_capacity     = 1
     launch_configuration = aws_launch_configuration.eks-node-launch-config.id
     max_size             = 2
     min_size             = 1
     name                 = local.eks_cluster_name
     vpc_zone_identifier  = [aws_subnet.inside_subnet.id]
   
     tag {
       key                 = "Name"
       value               = "${local.eks_cluster_name}_node"
       propagate_at_launch = true
     }
   
     tag {
       key                 = "kubernetes.io/cluster/${local.eks_cluster_name}"
       value               = "owned"
       propagate_at_launch = true
     }
   }
   
   ...data omitted
   
   ```
   
   We configured all our variables, VPC, Cisco Secure Firewall (FTDv), and
   an EKS cluster for AWS. Now it is time to start working with **Ansible** to configure the FTDv Policy. 
   

### Using Ansible for Configuration Management
We will use Ansible to configure the Cisco Secure Firewall (FTDv) policy. We will initialize and provision the FTDv by 
accepting the EULA, configuring the Interfaces, Security zones, NAT, Access Control Policy, Routes, and Network/Service
objects.

1. After the infrastructure gets built, and we need to start putting some policy in place. To do this we need some information 
   from Terraform such as the FTDv management, EKS internal, and EKS external IP addresses. To get this info we created a 
   terraform file named **`ftd_host_file.tf`**. This file will pull this information from Terraform and create an Ansible
   hosts (inventory) file. Let's take a look at the 
   [ftd_host_file.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/ftd_host_file.tf).
   
   ```
   // Create inventory file with AWS IP address variables //
   
   data "aws_instance" "eks_node_instance" {
     depends_on = [aws_autoscaling_group.eks-node-autoscaling-group]
     filter {
       name = "tag:Name"
       values = ["${local.eks_cluster_name}_node"]
     }
   }
   resource "local_file" "host_file" {
     depends_on = [aws_autoscaling_group.eks-node-autoscaling-group, aws_instance.ftdv]
       content     = <<-EOT
       ---
       all:
         hosts:
           ftd:
             ansible_host: ${aws_eip.ftd_mgmt_EIP.public_ip}
             ansible_network_os: ftd
             ansible_user: ${var.ftd_user}
             ansible_password: ${var.ftd_pass}
             ansible_httpapi_port: 443
             ansible_httpapi_use_ssl: True
             ansible_httpapi_validate_certs: False
             eks_inside_ip: ${data.aws_instance.eks_node_instance.private_ip}
             eks_outside_ip: ${aws_eip_association.eks_outside_ip_association.private_ip_address}
       EOT
       filename = "${path.module}/Ansible/hosts.yaml"
   }
   ```
   
   Once again we use another data source to get the IP address of the EKS worker node. Then we grabbed the IP address 
   of the FTDv management interface, added the FTD username and password from our variables, and the EKS outside IP 
   address. We create this file in the **`/Ansible`** directory, so it can be used with the Ansible playbooks we will discuss
   next.
   

2. Now let's take a look into the **`/Ansible`** directory to review the playbooks we will run on our FTDv instance. There 
   are 3 files located in this directory, **`ftd_status.tf`**, **`ftd_initial_provisioning.yaml`** and 
   **`ftd_configuration.yaml`**. 
   There is a 4th file that will be generated by **`ftd_host_file.tf`**, which will be `hosts.yaml` (this won't be visible 
   until after the terraform apply). 
   
   First let's open the 
   [ftd_status.yaml](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/Ansible/ftd_status.yaml)
   . This playbook just polls the FTD Management interface until it gets a response code of 200. This way the other 
   playbooks won't run until the API is available. 
   
   ```
   - hosts: ftd
     connection: local
     tasks:
       - name: Pause play until the FTD mgmt interface is reachable from this host
         uri:
           url: "https://{{ ansible_host }}"
           follow_redirects: none
           method: GET
           validate_certs: false
         register: _result
         until: _result.status == 200
         retries: 120 # 120 * 10 seconds = 20 minutes
         delay: 10 # Every 5 seconds
       - debug:
           var: _result
   ```
   
   The next file, 
   [ftd_initial_provisioning.yaml](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/Ansible/ftd_initial_provisioning.yaml), 
   is used for to take care of the initial provisioning of the FTD. 
   When an FTDv gets spun up there is an End User License Agreement (EULA) that needs to be accepted, and an evaluation 
   license (90 days) for all its features needs to be enabled. The `ftd_initial_provisioning.yaml` takes care of this 
   for us.
   
   ```
   #NGFW Initial Configuration File
   
   - hosts: ftd
     connection: httpapi
     tasks:
   
       # The following tasks check the current state of device provisioning, displays the EULA text,
       # and asks the user to accept it:
   
       - name: Get provisioning info
         ftd_configuration:
           operation: getInitialProvision
           path_params:
             objId: default
           register_as: provisionInfo
   
       - name: Show EULA text
         debug:
           msg: 'EULA details: {{ provisionInfo.eulaText }}'
   
       - name: Confirm EULA acceptance
         pause:
           prompt: Please confirm you want to accept EULA. Press Return to continue. To abort,
             press Ctrl+C and then "A"
   
       # This task sends a request to the device to unlock it.
   
       - name: Complete initial provisioning
         ftd_configuration:
           operation: addInitialProvision
           data:
             acceptEULA: true
             eulaText: '{{ provisionInfo.eulaText }}'
             type: initialprovision
         vars:
           ansible_command_timeout: 30
   ```

3. After the initial provisioning of the FTDv is completed we will run the `ftd_configuration.yaml` to configure the FTDv
   policies. This playbook will configure interfaces, network objects, service objects, NAT, security zones, access
   control policies, and deploy the configuration to the FTDv instance. This configuration is too large to take a 
   snippet on this doc, but you can take a look at it at 
   [ftd_configuration.yaml](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/Ansible/ftd_configuration.yaml).
   As you can see this ansible playbook creates access rules, NATs, network and service objects for two applications,
   YELB and NGINX. We will dive a little deeper into them applications later in this doc, but these are the 2 apps that
   we will be securing!!!
   

4. In the real world when we are deploying our IaC we use a CI/CD tool to do so, such as Jenkins, GitHub Actions, or 
   AWS CodePipeline, but since we are just developing our code in this Part 1 doc, we are going to "stitch" a few stages
   together to make sure our code works before integrating into a pipeline tool in Part 2. We created an `ansible_deploy.tf`
   file that will run our Ansible playbooks as a terraform resource after our infrastructure has been brought up. 
   Let's take a look at the 
   [ansible_deploy.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/ansible_deploy.tf) 
   file.
   
   ```
   // Check Status of FTD Management - Make sure it is responding //
   resource "null_resource" "ftd_status" {
     depends_on = [local_file.host_file]
     provisioner "local-exec" {
         working_dir = "${path.module}/Ansible"
         command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_status.yaml"
     }
   }
   
   // Initial FTP provisioning //
   resource "null_resource" "ftd_init_prov" {
     depends_on = [null_resource.ftd_status]
     provisioner "local-exec" {
         working_dir = "${path.module}/Ansible"
         command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_initial_provisioning.yaml"
     }
   }
   
   // FTD Configuration //
   resource "null_resource" "ftd_conf" {
     depends_on = [null_resource.ftd_init_prov]
     provisioner "local-exec" {
         working_dir = "${path.module}/Ansible"
         command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml"
     }
   }
   ```
   
   Here we are just running these playbooks from a terraform provisioner. As you can see we are running these commands
   from **Docker**. *"Why Docker?"* you may ask. Well the kind fellas in the Cisco Secure Firewall Product Engineering
   department were awesome enough to create a **[FTD Ansible Docker Image](https://hub.docker.com/r/ciscodevnet/ftd-ansible)**, 
   where all we have to do is pass our host and playbooks files to it, and **KABOOM!!** everything is configured.
   

### Working with Kubernetes using Terraform

In this section we configure Kubernetes resources using Terraform.

1. First lets take a look at the Kubernetes providers we will initialize. At the beginning of the code we tell terraform 
   what version of the provider is required. This is very important because some features we use in our IaC may be 
   version specific. Next we add a couple data sources which we will fetch the EKS cluster CA Cert and Token. We use
   the data sources to configure authentication for the Kubernetes and kubectl providers. Why are there two providers
   for K8s? The first, `provider "kubernetes"` is the official Kubernetes provider and has resources and data sources
   built for almost anything you want to create via the K8s API. The second, `provider "kubectl"` allows us to apply
   native YAML files like we would if we were using the kubectl CLI. So for example, if we had a yaml file and we just
   wanted to apply it as one resource instead of a bunch of resources, we can use the 
   [Kubectl Provider](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs). 
   If we can build the resource out, we can use the 
   [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs). 
   You will see this in the next few steps where we use the kubectl provider to apply a config map, but use the 
   kubernetes provider to apply manifest.

   ```
   terraform {
     required_providers { 
       kubernetes = {
         source = "hashicorp/kubernetes"
         version = "2.4.1"
       }
       kubectl = {
         source = "gavinbunney/kubectl"
         version = "1.11.3"
       }
     }
   }
   
   // Kubernetes Configuration
   data "aws_eks_cluster" "eks_cluster" {
     name = "CNS_Lab_${var.lab_id}"
   }
   
   data "aws_eks_cluster_auth" "eks_cluster_auth" {
     name = "CNS_Lab_${var.lab_id}"
   }
   
   provider "kubernetes" {
     host                   = data.aws_eks_cluster.eks_cluster.endpoint
     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
     token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
     //load_config_file       = false
   }
   
   provider "kubectl" {
     host = data.aws_eks_cluster.eks_cluster.endpoint
     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
     token = data.aws_eks_cluster_auth.eks_cluster_auth.token
     load_config_file       = false
   }
   ```
      
2. For our EKS cluster to work correctly we need to allow the EKS worker node to communicate with the Cluster API. To 
   do this we need to apply a [Config Map](https://kubernetes.io/docs/concepts/configuration/configmap/) in 
   kubernetes. It is initially created to allow your nodes to join your cluster, but you also use this ConfigMap to add 
   RBAC access to IAM users and roles. Here we created a file called **`config_map_aws_auth.tf`**. Lets talk a look at 
   [config_map_aws_auth.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/config_map_aws_auth.tf)
   file.
   
   ```
   // Apply Config Map AWS Auth //
   
   resource "kubectl_manifest" "config_map_aws_auth" {
     depends_on = []
     yaml_body = <<YAML
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: aws-auth
     namespace: kube-system
   data:
     mapRoles: |
       - rolearn: ${aws_iam_role.eks_node_role.arn}
         username: system:node:{{EC2PrivateDNSName}}
         groups:
           - system:bootstrappers
           - system:nodes
   YAML
   }
   ```
   
   We use the `kubectl_manifest` resource here to apply the config map using YAML. Notice the **`rolearn`** has a value 
   of the role we created in our **`eks.tf`** file. This will allow our worker node to talk to the Cluster API.
   

### Provision the Infrastructure as Code
At this point you are ready to provision all the code in the **`/Lab_Build`** directory. The code at this point will 
provision a VPC, FTDv Instance, EKS Cluster and EKS Node *(the provisioning of Cisco Secure Cloud Analytics,
Secure Workload, and Secure Cloud Native are adding in later steps that are optional but recommended)*.
This means running the *terraform init, plan, and apply* commands in the directory we are working in. The **`terraform
plan`** command creates an execution plan by reading the current state of any already-existing remote objects to make sure 
that the Terraform state is up-to-date, comparing the current configuration to the prior state and noting any 
differences, and proposing a set of change actions that should, if applied, make the remote objects match the 
configuration. The **`terraform apply`** command executes the actions proposed in a Terraform plan.
For more information about terraform provisioning, see 
[Provisioning Infrastructure with Terraform](https://www.terraform.io/docs/cli/run/index.html).

1. Make sure you are in the **`/Lab_Build`** directory. Run the **`terraform init`** command. The 
   [terraform init](https://www.terraform.io/docs/cli/commands/init.html) command is used
   to initialize a working directory containing Terraform configuration files. This is the first command that should be 
   run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run 
   this command multiple times. This will initialize all the providers and version that we declared in
   the **`main.tf`** file.
   
   ```
   Terraform % terraform init

   Initializing the backend...
   
   Initializing provider plugins...
   - Finding hashicorp/aws versions matching "~> 3.0"...
   - Finding hashicorp/kubernetes versions matching "2.4.1"...
   - Finding latest version of hashicorp/null...
   - Finding latest version of hashicorp/local...
   - Finding latest version of hashicorp/template...
   - Finding gavinbunney/kubectl versions matching "1.11.3"...
   - Installing gavinbunney/kubectl v1.11.3...
   - Installed gavinbunney/kubectl v1.11.3 (self-signed, key ID AD64217B5ADD572F)
   - Installing hashicorp/aws v3.57.0...
   - Installed hashicorp/aws v3.57.0 (signed by HashiCorp)
   - Installing hashicorp/kubernetes v2.4.1...
   - Installed hashicorp/kubernetes v2.4.1 (signed by HashiCorp)
   - Installing hashicorp/null v3.1.0...
   - Installed hashicorp/null v3.1.0 (signed by HashiCorp)
   - Installing hashicorp/local v2.1.0...
   - Installed hashicorp/local v2.1.0 (signed by HashiCorp)
   - Installing hashicorp/template v2.2.0...
   - Installed hashicorp/template v2.2.0 (signed by HashiCorp)
   
   ...

   ```  
   
2. Run the **`terraform plan`** using an output file, **`terraform plan -out 
   tfplan`**. This writes the generated plan to the given filename in an opaque file format that you can later pass to
   terraform apply to execute the planned changes. Here we see that we are planning to deploy 48 new resources. We 
   omitted the data in the snippet below because it was too much, but you should always double check the full plan before
   you apply it.
   
   ```
   Terraform % terraform plan -out tfplan
   
   Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
     + create
    <= read (data resources)
   
   Terraform will perform the following actions:
   
   ... data omitted
   
   Plan: 48 to add, 0 to change, 0 to destroy.

   Changes to Outputs:
      + eks_cluster_name = "CNS_Lab_Test"
      + eks_public_ip    = (known after apply)
      + ftd_mgmt_ip      = (known after apply)
   
   ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
   
   Saved the plan to: tfplan
   
   To perform exactly these actions, run the following command to apply:
       terraform apply "tfplan"
   
   ```

3. Apply the plan using the **`terraform apply "tfplan"`** command. 
   The [terraform apply](https://www.terraform.io/docs/cli/commands/apply.html) command executes the actions proposed 
   in a Terraform plan. Once again below we omitted a lot of the output data, but you can see we start building the 
   infrastructure. At the end you should see 48 resources added, and some **Outputs:** we can use to access the 
   resources. Save these outputs as we will need them in the next step.

   ```
   Terraform % terraform apply "tfplan"
   aws_vpc.cns_lab_vpc: Creating...
   aws_iam_role.eks_node_role: Creating...
   aws_iam_role.eks-cluster-role: Creating...
   aws_iam_role.eks-cluster-role: Creation complete after 1s [id=CNS_Lab_99_cluster]
   aws_iam_role.eks_node_role: Creation complete after 1s [id=CNS_Lab_99_eks_node_role]
   aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy: Creating...
   aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy: Creating...
   aws_iam_role_policy_attachment.eks-node-AmazonEKSWorkerNodePolicy: Creating...
   aws_iam_role_policy_attachment.eks-node-AmazonEC2ContainerRegistryReadOnly: Creating...
   
   ... data omitted
   
   Apply complete! Resources: 48 added, 0 changed, 0 destroyed.
   
   Outputs:
   
   eks_public_ip = "18.216.235.214"
   ftd_mgmt_ip = "3.136.174.54"
   eks_cluster_name = CNS_Lab_55
   ```

### Access the Environment
Use the outputs generated from the **`output.tf`** file to access the environment. The IP addresses and ports above may 
be different, so make sure to use the outputs from your **`terraform apply`**.

1. Access the Secure Firewall (FTDv) management interface by going to `https://<ftd_mgmt_ip>` where <ftd_mgmt_ip> is
   the IP from the `ftd_mgmt_ip` output. This will bring you to a logon page. Enter the username and password you defined
   in the **`terraform.tfvars`** file.
   
   ![FTDv Logon Page](/images/ftd-login.png)

2. Once logged in poke around and make sure everything was configured correctly from the ansible playbooks.
   Check the Policies, where you can see the Access Control and NAT rules.
   
   ![FTDv Access Control](/images/ftd-pol.png)

   ![FTDv NAT](/images/ftd-nat.png)

   Check out the Objects and Interfaces.

   ![FTDv Objects](/images/ftd-obj.png)

   ![FTDv Interfaces](/images/ftd-int.png)
 
3. Access your AWS account portal and select **Services** > **Compute** > **EC2**. There will be two instances running
   named **`CNS_Lab_<lab_id>_FTDv`** and **`CNS_Lab_<lab_id>_node`**. The **`CNS_Lab_<lab_id>_FTDv`** is obviously the 
   firewall and the **`CNS_Lab_<lab_id>_node`** is the EKS worker node where we will deploy our applications.
   
   ![AWS Compute](/images/aws-ec2.png)

4. Next lets go to **Services** > **Containers** > **Elastic Kubernetes Service**. Under **Amazon EKS** select 
   **Clusters**. There will be EKS cluster named **`CNS_Lab_<lab_id>`**. 
   
   ![AWS EKS Cluster](/images/eks-cluster.png)
   
   Select the cluster, and you will see the EC2 instance assigned as a worker node for the cluster.

   ![AWS EKS Node](/images/eks-node.png)

5. Finally, select to **Services** > **Networking & Content Delivery** > **VPC**. Select **Your VPC**. On the left
   hand menu bar click through VPCs, Subnets, Route Tables, Internet Gateways, and Elatic IPs. You will see resources 
   with the **`CNS_Lab_<lab_id>`** appended to the name of the resources.
   
   ![AWS VPC](/images/aws-vpc.png)

6. To access the EKS environment locally using the kubectl client, we need to 
   [Update Kube Config](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/eks/update-kubeconfig.html).
   Make sure your AWS CLI Configuration is updated and run the following command where `<aws-region>` is the region 
   the EKS cluster is deployed and where `<cluster-name>` in the EKS cluster name.
   
   **`aws eks --region <aws-region> update-kubeconfig --name <cluster-name>`**

   For example **`aws eks --region us-east-2 update-kubeconfig --name CNS_LAB_Test`**


The infrastructure is now deployed and being secured by Cisco Secure Firewall. This provides us protections for inbound 
and outbound traffic (North/South), which is great, but how do we protect laterally between workloads and applications 
behind the Firewall.
That is what we are going to dive into in the next few sections, but first we need some cloud native applications to 
secure.

### Deploy Applications
There are a couple ways we can deploy the applications that will reside in the kubernetes cluster. We can use the 
**Kubernetes Provider** to deploy resources such as namaspaces, services, and deployments. We can use the **Kubectl
Provider** to deploy a YAML manifest file, or we can use the **Local Provisioner** to run the *kubectl create* commands.
Each option has their pluses and minuses. For example, if we deploy resources using the Kubernetes Provider, than 
everything about that deployment needs to be managed by Terraform. The good thing is we can easily deploy any 
kubernetes resource using Terraform, but any changes outside the terraform file will be removed. If we use the Kubectl 
Provider, it will deploy a resource using native YAML file, which makes it easier to use community writen manifests,
but now this resource is tracked as a full manifest, and not each service like the Kubernetes Provider. Using the 
Local Provisioner should always be a last resort, but it is a quick and easy way to get up and going if you are a *kubectl*
cli user. There is no state in Terraform when using the Local Provisioner, so Terraform will not track and changes.

1. In Part 1 we will deploy our applications using the Kubernetes Provider. In the **`Lab_Build`** directory there are two 
   files named **`yelb_app`** and **`nginx.app`**. Change the names to use the **`.tf`** extension, **`yelb_app.tf`**
   and **`nginx_app.tf`**.
   

2. Yelb is a cool 3 tier demo app that allows users to vote on a set of alternatives 
   (restaurants) and dynamically updates pie charts based on number of votes received. If you want some more details
   about this app check out the [Yelb GitHub](https://github.com/mreferre/yelb). For this app we built a terraform file
   named **`yelb_app.tf`**. In this file we create kubernetes resources such as **`kubernetes_namespace`**, 
   **`kubernetes_service`**, and **`kubernetes_deployment`**. Below is an example for just the Yelb web server resources. 
   Take a look at the full manifest at 
   [yelb_app](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/yelb_app) for 
   all the services and pods that are created for the Yelb application.
   
   ```
   resource "kubernetes_namespace" "yelb_ns" {
     depends_on = [kubectl_manifest.config_map_aws_auth]
     metadata {
       name = "yelb"
     }
   }
   resource "kubernetes_service" "yelb_ui" {
     depends_on = [kubernetes_namespace.yelb_ns]
     metadata {
       name = "yelb-ui"
       namespace = "yelb"
       labels = {
         app = "yelb-ui"
         tier = "frontend"
         environment = "cns_lab"
       }
     }
     spec {
       type = "NodePort"
       port {
         port = "80"
         protocol = "TCP"
         target_port = "80"
         node_port = "30001"
       }
       selector = {
         app = "yelb-ui"
         tier = "frontend"
       }
     }
   }
   resource "kubernetes_deployment" "yelb_ui" {
     metadata {
       name = "yelb-ui"
       namespace = "yelb"
     }
     spec {
       replicas = 1
       selector {
         match_labels = {
           app = "yelb-ui"
           tier = "frontend"
         }
       }
       template {
         metadata {
           labels = {
             app = "yelb-ui"
             tier = "frontend"
             environment = "cns_lab"
           }
         }
         spec {
           container {
             name = "yelb-ui"
             image = "mreferre/yelb-ui:0.7"
             port {
               container_port = 80
             }
           }
         }
       }
     }
   }
   ```


3. We also configure a second app using the **`nginx_app.tf`** file. This app is just a NGINX test page that we can play
   with when testing out security controls. Check out the configuration of that app at 
   [nginx_app.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/nginx_app).
   
4. Run the **`terraform plan -out tfplan`** and **`terraform apply "tfplan"`** again to deploy these applications.

   ```
   Plan: 9 to add, 0 to change, 1 to destroy.
   
   ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
   
   Saved the plan to: tfplan
   
   To perform exactly these actions, run the following command to apply:
       terraform apply "tfplan"
   [devbox Lab_Build]$ terraform apply "tfplan"
   null_resource.deploy_yelb_app: Destroying... [id=5942784377980066240]
   null_resource.deploy_yelb_app: Destruction complete after 0s
   kubernetes_namespace.yelb_ns: Creation complete after 0s [id=yelb]
   kubernetes_service.yelb_ui: Creation complete after 0s [id=yelb/yelb-ui]
   kubernetes_service.yelb_appserver: Creation complete after 0s [id=yelb/yelb-appserver]
   kubernetes_service.yelb_redis_service: Creation complete after 0s [id=yelb/redis-server]
   kubernetes_service.yelb_db_service: Creation complete after 0s [id=yelb/yelb-db]
   kubernetes_deployment.redis_server: Creation complete after 46s [id=yelb/redis-server]
   kubernetes_deployment.yelb_ui: Creation complete after 46s [id=yelb/yelb-ui]
   kubernetes_deployment.yelb_db: Creation complete after 46s [id=yelb/yelb-db]
   kubernetes_deployment.yelb_appserver: Creation complete after 46s [id=yelb/yelb-appserver]
   
   Apply complete! Resources: 9 added, 0 changed, 1 destroyed.
   
   Outputs:
   
   eks_cluster_name = "CNS_Lab_Test"
   eks_public_ip = "18.117.14.78"
   ftd_mgmt_ip = "18.119.87.234"
   ```


5. Access the Yelb app by going to **`http://<eks_public_ip>:30001`** where <eks_public_ip> is the IP address of
   the terraform output **`eks_public_ip`**, for example in this case `http://18.117.14.78:30001. Do you know where 
   that service port came from? Take a look at the Yelb UI Service.
   
   ![Yelb UI](/images/yelb.png)

6. Access the NGINX app by going to **`http://<eks_public_ip>:30201`** where <eks_public_ip> is the IP address of
   the **`eks_public_ip`** output.
   
   ![NGINX UI](/images/nginx.png)

7. Verify the kubernetes environment using the kubectl client.
   1. If you didn't already, update the kube config file by running 
      **`aws eks --region <aws-region> update-kubeconfig --name <eks-cluster-name>`** 
      where <eks-cluster-name> is the name of the **`eks_cluster_name`** output and the <aws-region> is the region you are
      deploying to.
      
      For example:

      ```
      Terraform % aws eks --region us-east-2 update-kubeconfig --name CNS_Lab_Test
      Added new context arn:aws:eks:us-east-2:208176673708:cluster/CNS_Lab_Test to /Users/edmcnich/.kube/config
      ```
      
   2. Run some commands to verify the resources were implemented. Run **`kubectl get nodes`** which will show what EKS 
      worker nodes are available to the cluster. In this lab it is just one node. Run **`kubectl get ns`** to see the 
      Yelb and NGINX namespaces we created. Run **`kubectl get pods -n yeb`** to see all th pods we created in the Yelb
      namespace. Run **`kubectl get service -n yelb`** to view all the services we created for the Yelb namespace.
      
      ```
      Terraform % kubectl get nodes
      NAME                                      STATUS   ROLES    AGE   VERSION
      ip-10-0-1-90.us-east-2.compute.internal   Ready    <none>   10m   v1.21.2-eks-55daa9d
      Terraform % kubectl get ns
      NAME              STATUS   AGE
      default           Active   21m
      kube-node-lease   Active   21m
      kube-public       Active   21m
      kube-system       Active   21m
      nginx             Active   10m
      yelb              Active   10m
      Terraform % kubectl get pods -n yelb
      NAME                              READY   STATUS    RESTARTS   AGE
      redis-server-65977ffd-t24dj       1/1     Running   0          10m
      yelb-appserver-594494c5fd-htllt   1/1     Running   0          10m
      yelb-db-79687c7fbc-xpbll          1/1     Running   0          10m
      yelb-ui-5f446b88f9-lghq5          1/1     Running   2          10m
      Terraform % kubectl get service -n yelb
      NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
      redis-server     ClusterIP   172.20.243.191   <none>        6379/TCP       11m
      yelb-appserver   ClusterIP   172.20.158.193   <none>        4567/TCP       11m
      yelb-db          ClusterIP   172.20.214.165   <none>        5432/TCP       11m
      yelb-ui          NodePort    172.20.8.98      <none>        80:30001/TCP   11m
      ``` 

Awesome, now we have cloud native apps to play with. Let's see how we can secure them!!!

### Deploy Cisco Secure Cloud Analytics
**(OPTIONAL)**

:warning: **You will need a Cisco Secure Cloud Analytics account to complete this section**. If you don't have an account
you can sign up for a free trial 
[HERE](https://www.cisco.com/c/en/us/products/security/stealthwatch/stealthwatch-cloud-free-offer.html).

This section will show how to deploy **Cisco Secure Cloud Analytics** to this Cloud Native environment. 
[Secure Cloud Analytics](https://www.cisco.com/c/en/us/products/security/stealthwatch-cloud/index.html) 
provides the visibility and threat detection capabilities you need to keep your workloads highly 
secure in all major cloud environments like Amazon Web Services (AWS), Microsoft Azure, and Google Cloud Platform, and 
guess what, it supports integration directly with the kubernetes cluster. 

1. Log in to your Secure Cloud Analytics portal and go to **`Setting`** > **`Integrations`**. 

   ![Secure Cloud Analytics Dashboard](/images/swc-dash.png)
   
2. On the Setting menu bar select **`Integrations`** > **`Kubernetes`**.

   ![Secure Cloud Analytics Settings](/images/swc-inte.png)

3. This brings you to the Kubernetes Integration page. This page gives you step-by-step instructions
   on how to deploy Secure Cloud Analytics to your kubernetes cluster using the **`kubectl`** client.
   Luckily we have created a terraform file that will deploy all necessary resources, but first we need
   to get the **`secret key`** from the integration page. On the integration page the first step is to 
   create a secret key file. We don't need to run this step, we just need copy and save the key itself. Where it says
   **`echo -n "<secret_key>" > obsrvbl-service-key.txt`**, copy and save this key.
   
   ![Secure Cloud Analytics Secret Key](/images/swc-key.png)

4. In the **`/Lab_Build`** directory, go to the **`terraform.tfvars`** file and add this key to the Secure Cloud 
   Analytics **`sca_service_key`** variable. Make sure to uncomment (**`//`**) the variable.

   ```
   sca_service_key    = "<secret_key>"
   ```
   
   Go to the **`variables.tf`** file and uncomment the variable there as well

   ```
   variable "sca_service_key" {}
   ```
   
5. Find the file named **`secure_cloud_analytics`** and change it to **`secure_cloud_analytics.tf`** so terraform can 
   read it. Click 
   [secure_cloud_analytics](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/secure_cloud_analytics)
   to view the file.
   
6. Run **`terraform plan -out tfplan`** and review the resource that will be created. Run **`terraform apply "tfplan"`**
   to create the resources. 4 kubernetes resources will be created, *secret, service account, cluster role binding, and a
   daemonset*. 
   
   ```
   kubernetes_secret.obsrvbl: Creating...
   kubernetes_secret.obsrvbl: Creation complete after 1s [id=default/obsrvbl]
   kubernetes_service_account.obsrvbl: Creating...
   kubernetes_service_account.obsrvbl: Creation complete after 0s [id=default/obsrvbl]
   kubernetes_cluster_role_binding.obsrvbl: Creating...
   kubernetes_cluster_role_binding.obsrvbl: Creation complete after 0s [id=obsrvbl]
   kubernetes_daemonset.obsrvbl-ona: Creating...
   kubernetes_daemonset.obsrvbl-ona: Creation complete after 0s [id=default/obsrvbl-ona]
   
   Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
   
   ```   
   
7. Run some more kubectl commands to verify the infrastructure:
   * **`kubectl get pods`**
      ```   
       Terraform % kubectl get pods
      NAME                READY   STATUS    RESTARTS   AGE
      obsrvbl-ona-z4lkj   1/1     Running   0          74m
      ```
   * **`kubectl get daemonset`** 
     What is a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)?
      ```
      Terraform % kubectl get ds 
      NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
      obsrvbl-ona   1         1         1       1            1           <none>          76m
      ```   
   
8. Now check the Cisco Secure Cloud Analytics Portal. In the upper right corner select the Sensors
   icon. 
   
   ![Secure Cloud Analytics](/images/swc-sensor.png)

   This will take you to the Sensors screen. There will be a sensor named after the EC2 instance,
   for example **`ip-10-0-1-90.us-east-2.compute.internal`**. It may take a few minutes for the sensor to start 
   receiving data, and the icon to turn green.
   
   ![Secure Cloud Analytics Sensors](/images/swc-sen.png)

   Once the sensor starts collecting data you can select **`Investigate`** > `Device`.

   ![Secure Cloud Analytics Sensors](/images/swc-devices.png)

   This will bring you to the Endpoints screen where you should see containers from our test apps 
   start showing up.
   
   ![Secure Cloud Analytics Endpoints](/images/swc-ep.png)
   
   Click on one of the devices to start drilling down into Alerts, Observations, and Session traffic.

Well that was super easy. Now we have full visibility into our kubernetes environment. All the flows going in and out of
the cluster, and between the applications and pods will be inspected using behavioral modeling, including malware 
and insider threats, continuously monitoring and improving response times with automatic, high-fidelity alerts that make 
your security team more efficient.

### Deploy Cisco Secure Workload
**(OPTIONAL)**

:warning: **You will need a Cisco Secure Workload account and a Linux host to complete this section**.

This section will show how to deploy **Cisco Secure Workload** to this Cloud Native environment.
The 
[Cisco Secure Workload](https://www.cisco.com/c/en/us/products/security/tetration/index.html) 
platform is designed to address this challenge in a comprehensive and 
scalable way. Secure Workload enables holistic workload protection for multicloud data centers by using:
* Micro-segmentation, allowing operators to control network communication within the data center, enabling a zero-trust 
   model

* Behavior baselining, analysis, and identification of deviations for processes running on servers

* Detection of common vulnerabilities and exposures associated with the software packages installed on servers

* The ability to act proactively, such as quarantining server(s) when vulnerabilities are detected and blocking 
   communication when policy violations are detected

By using this multidimensional workload-protection approach, Cisco Secure Workload significantly reduces the attack 
surface, minimizes lateral movement in case of security incidents, and more quickly identifies Indicators Of Compromise.

1. To get Secure Workload working in our cloud native environment we need to do three things. First we need an API key
   and secret. Log into the Secure Workload dashboard and in the upper right hand corner click on the **Profile** icon
   then **API Keys**. 
   
   ![Secure Workload Profile](/images/sw-dash.png)
   
   Select **Create API Key**. Give the API key a description and check all the options below. Click **Create**.

   ![Secure Workload API Key](/images/sw-create-api2.png)

   This will show you the API Key and Secret Key. You can download it to a safe place or copy the keys directly from the
   screen. 
   
   ![Secure Workload API](/images/sw-api.png)

   We also need the Secure Workload hostname and Root Scope ID. Go to **`Organize`** > **`Scopes and Inventory`**. 
   The Root Scope is the top scope in the scope tree, for example in this case the root scope is **`edmcnich`**.
   Select the root scope and up in the URL field of the broswer you can see the hostname and Scope ID as highlighted
   below. The Scope ID can be found in between **`id=`** and the **`&chips`** in the URL field.
   
   ![Secure Workload API](/images/sw-rootscopeid.png)

   Save the Secure Workload API Key, Secret, Hostname, and Root Scope ID as we will need it in a few steps.

2. The second thing we need is an agent. Secure Workload has always supported a wide variety of operating systems to 
   deploy sofware agents to, but Kubernetes is a little different. We could manually deploy an agent to every worker 
   node in our cluster, but that isn't very agile and doesn't give us the ability to create segmentation policy at the
   container/pod layer. To do this we need to deploy a 
   [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), just like we did for Secure 
   Cloud Analytics. A Daemonset will deploy a Secure Workload agent to every kubernetes worker node scheduled in the 
   cluster. This means that if a new node is added to the cluster, it will come with the agent installed automatically.
   To install the Daemonset we need to download and run the install script. 
   
   :warning: The Cisco Secure Workload Kubernetes Installer is only supported to be run on a Linux Operating system.
   This will not work correctly on Windows or Mac operating systems. The Linux machine will also need AWS CLI and the
   Kubernetes agent installed!
   
   From the Secure Workload dashboard go to **`Manage`** > **`Agents`** on the left menu bar.

   ![Secure Workload Agents](/images/sw-agents.png)

   Select **`Installer`** to go through the Software Agent Installer workflow. Click **`Next`**.

   ![Secure Workload Installer](/images/sw-installer.png)

   Select **`Kubernetes`** as the platform to be installed on and **`YES/NO`** if your Kubernetes environment is going 
   through a proxy (add proxy info if it does). Click **`Download Installer`** to download the install script. Save the
   install script to a directory on your Linux machine. 
   
   ![Secure Workload Agent Download](/images/sw-agent-download.png)

   Make sure that AWS CLI and Kubectl are installed on your Linux host. Also make sure your kube config file is updated
   to use the right context (**`aws eks --region <aws-region> update-kubeconfig --name <cluster-name>`**).
   
   ```
   [devbox Lab_Build]$ aws eks --region us-east-2 update-kubeconfig --name CNS_Lab_Test
   Added new context arn:aws:eks:us-east-2:208176673708:cluster/CNS_Lab_Test to /home/centos/.kube/config
   ```
   
   Run the install script with --pre-check flag first.

   ```
   bash tetration_daemonset_installer.sh --pre-check
   ```
   
   If all the requirements are fulfilled run the installer.

   ```
   [devbox Lab_Build]$ bash ~/Downloads/tetration_installer_edmcnich_enforcer_kubernetes_tet-pov-rtp1.sh
   -------------------------------------------------------------
   Starting Tetration Analytics Installer for Kubernetes install
   -------------------------------------------------------------
   Location of Kubernetes credentials file is /home/centos/.kube/config
   The following Helm Chart will be installed
   apiVersion: v2
   appVersion: 3.6.0-17-enforcer
   description: Tetration Enforcer Agent
   name: tetration-agent
   type: application
   version: 3.6.0-17-enforcer
   Release "tetration-agent" does not exist. Installing it now.
   NAME: tetration-agent
   LAST DEPLOYED: Mon Sep 27 14:10:24 2021
   NAMESPACE: tetration
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The Tetration Enforcement Agent has been deployed to your Kubernetes cluster.
   
   1. You can view your Helm Chart details again using
   
     helm get all -n tetration tetration-agent
   
   2. You can view the Daemonset created using
   
     kubectl get ds -n tetration
   
   3. You can view the Daemonset pods created for Tetration Agents using
   
      kubectl get pod -n tetration
      
   --------------------------------------------------------------------------
   
   You can also check on the Tetration Agent UI page for these agents.
   Deployment of daemonset complete
   ```

   Check to make sure the daemonset has been deployed.

   ```
   [devbox Lab_Build]$ kubectl get ns tetration
   NAME        STATUS   AGE
   tetration   Active   5m25s
   [devbox Lab_Build]$ kubectl get ds -n tetration
   NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
   tetration-agent   1         1         1       1            1           <none>          5m41s
   [devbox Lab_Build]$ kubectl get pods -n tetration
   NAME                    READY   STATUS    RESTARTS   AGE
   tetration-agent-4kbrd   1/1     Running   0          5m56s
   ```
   
   Check the Secure Workload dashboard. Go to **`Manage`** > **`Agents`** and Select **`Agent List`**. The agent should 
   be there with the hostname of your EKS worker node.
   
   ![Secure Workload Agent List](/images/sw-agent-installed.png)

3. Finally, now that we have the agent installed and the daemonset running, we need to get Kubernetes Labels uploaded 
   into the Secure Workload instance. This will allow us to create inventory filters, scopes, application workplaces
   and policies for our cloud native apps Yelb and NGINX.
   
   First thing we need to do is allow the Secure Workload instance read only access to ingest the labels from the 
   kubernetes cluster. We created a terraform file to do this for us named **`secure_workload_clusterrolebinding`**. To 
   deploy these resources rename the file using the **`.tf`** extension, **`secure_workload_clusterrolebinding.tf`**. 
   Go to the **`terraform.tfvars`** file and add the Secure Workload Key, Secret and URL to the variables. Make
   sure to uncomment **(`//`)** the variables
   
   ```
   secure_workload_api_key = ""
   secure_workload_api_sec = ""
   secure_workload_api_url = "https://<secure_workload_host>"
   ```
   
   Go to the **`variables.tf`** file and uncomment the variable there as well.
   
   ```
   variable "secure_workload_api_key" {}
   variable "secure_workload_api_sec" {}
   variable "secure_workload_api_url" {
     default = "https://<secure_workload_host>"
   ```
   
   Run **`terraform plan -out tfplan`** and **`terraform apply "tfplan"`**.

   ```
   [devbox Lab_Build]$ terraform apply "tfplan"
   kubernetes_cluster_role_binding.tetration-read-only: Creating...
   kubernetes_cluster_role.tetration-read-only: Creating...
   kubernetes_service_account.tetration-read-only: Creating...
   kubernetes_cluster_role_binding.tetration-read-only: Creation complete after 0s [id=tetration.read.only]
   kubernetes_cluster_role.tetration-read-only: Creation complete after 0s [id=tetration.read.only]
   kubernetes_service_account.tetration-read-only: Creation complete after 0s [id=default/tetration.read.only]
   
   Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
   ```
   
   We need to get the token for the **`tetration.read.only`** service account. To do this we need to get the service 
   account **`secrets name`** and base64 decode the output of the token. 
   * Run the command 
   **`kubectl get serviceaccount -o yaml tetration.read.only`**
     
      Get the name of the secret, for example in this case
   **`tetration.read.only-token-dnlqm`**. 
     
   * Run the command 
   **`kubectl get secret <your secret name> --template "{{ .data.token }}" | base64 -d`**. 
     
      This will output the secret token.

   ```
   [devbox Lab_Build]$ kubectl get serviceaccount -o yaml tetration.read.only
   apiVersion: v1
   automountServiceAccountToken: true
   kind: ServiceAccount
   metadata:
     creationTimestamp: "2021-09-27T19:04:23Z"
     name: tetration.read.only
     namespace: default
     resourceVersion: "596080"
     uid: 36003a9b-9a1b-471a-bd90-cfc8087b307a
   secrets:
   - name: tetration.read.only-token-dnlqm
   [devbox Lab_Build]$ kubectl get secret tetration.read.only-token-dnlqm --template "{{ .data.token }}" | base64 -d
   eyJhbGciOiJSUzI1...data omitted
   ```
   
   Copy and save the token output. Go back to the Secure Workload dashboard. Select **`Manage`** and **`External 
   Orchestrators`**. Select **`Create New Configuration`**.
   
   ![Secure Workload External Orchestrators](/images/sw-ext-orch.png)

   On the **`Create External Orchestrator Configuration`** page select **`Kubernetes`** as the Type and Name it the same 
   as your EKS Cluster name, for example **`CNS_Lab_Test`**.
   
   ![Secure Workload External Orchestrators](/images/sw-ext-orch-name.png)

   Scroll down to **`Auth Token`** and paste the base64 decoded token in this field.

   ![Secure Workload External Orchestrators](/images/sw-ext-orch-auth.png)

   Select **`Hosts List`** and add the hostname of the EKS Cluster API Endpoint. You can get the hostname from the 
   Terraform Output. You can always get the Terraform Output by doing a **`terraform show`**.
   
   ```
   Outputs:
   
   eks_cluster_api_endpoint = "https://CD3C5AE0C39535356D915B2A9C1A6443.gr7.us-east-2.eks.amazonaws.com"
   eks_cluster_name = "CNS_Lab_Test"
   eks_public_ip = "18.190.41.30"
   ftd_mgmt_ip = "18.190.106.59"
   ```

   Copy the API server endpoint into the Hosts List of the External Orchestrator Configuration page. Make sure to
   delete **`https://`** from the hostname field. Add **`443`** as the port number.
   
   ![Secure Workload External Orchestrators](/images/sw-ext-orch-host.png)
   
   Click **`Create`** and the portal should successfully connect to the cluster.

   ![Secure Workload External Orchestrators](/images/sw-ext-org-success.png)
   
   Go back to **`Manage`** > **`Agents`** in the menu bar to the left. Select **`Agent List`** and 
   click on the EKS Worker hosts. Under the **`Labels`** section there are now labels assigned 
   to this host. The initial label we are interested in is **`??? orchestrator_system/cluster_name`**
   which defines labels from our EKS cluster, for example in this case **`CNS_Lab_Test`**.
   
   ![Secure Workload Agent Labels](/images/sw-agent-labels.png)

   Click through all the labels to get a sense of all the labels that are generated automatically
   by the Kubernetes External Orchestrator integration. We will use these labels to create more 
   defined Scopes for the cluster and apps.
   
   Next go to **`Organize`** > **`Scopes and Inventory`**. Make sure to select your **`Root`**
   scope, for example in this case it is `edmcnich`. Here you will see services, pods, and 
   workloads associated with the External Orchestrator.
   
   ![Secure Workload Scopes and Inventory](/images/sw-scope.png)

   Select the **`Pods`** tab and click on the Pod Name starting with **`yelb-db`**. Here you 
   see that the pods have labels too. 
   
   ![Secure Workload Scopes and Inventory](/images/sw-scope-pod.png)

   Select the **`Services`** tab and drill into any of the **`yelb`** services. We are going to 
   create Scopes, Inventory Filters, Workspaces (Applications), and Policies using these labels.
   Here are some labels to take note of as we will be using them in our Secure Workload Terraform
   files.
   * user_orchestrator_system/cluster_name
   * user_orchestrator_system/namespace
   * user_orchestrator_system/pod_name
   * user_orchestrator_system/service_name
   
4. With the Secure Workload Daemonset deployed and External Orchestrator integrated we can now use Terraform to declare
   policy as code. We first need to add the 
   [Secure Workload Terraform Provider](https://github.com/CiscoDevNet/terraform-provider-tetration) to the **`main.tf`**
   file. Uncomment the following Secure Workload provider configuration.
   
   ```
   terraform {
     required_providers {
       tetration = {
         source = "CiscoDevNet/tetration"
         version = "0.1.0"
       }
     }
   }
   
   provider "tetration" {
      api_key = var.secure_workload_api_key
      api_secret = var.secure_workload_api_sec
      api_url = var.secure_workload_api_url
      disable_tls_verification = false
   }
   ```
   
   Go to the **`terraform.tfvars`** file and add the Secure Workload Key, Secret, URL and Root Scope ID to the variables. 
   Make sure to uncomment if commented out **(`//`)**.
   
   ```
   secure_workload_api_key = ""
   secure_workload_api_sec = ""
   secure_workload_api_url = "https://<secure_workload_host>"
   secure_workload_root_scope = ""
   ```
   
   Go to the **`variables.tf`** file and uncomment the variable there as well.
   
   ```
   variable "secure_workload_api_key" {}
   variable "secure_workload_api_sec" {}
   variable "secure_workload_api_url" {}
   variable "secure_workload_root_scope" {}
   ```
   Run **`terraform init`** to initialize the provider.
   
   ```
   [devbox Lab_Build]$ terraform init
   
   Initializing the backend...
   
   Initializing provider plugins...
   - Finding ciscodevnet/tetration versions matching "0.1.0"...
   - Installing ciscodevnet/tetration v0.1.0...
   - Installed ciscodevnet/tetration v0.1.0 (self-signed, key ID E10BA876A27B7DB3)
   ```
   
5. Now that the provider is initialized, let's build out the Secure Workload policy using Terraform resources. In the
   **`Lab_Build`** directory there is a file named
   [secure_workload](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Lab_Build/secure_workload). 
   Open the file and take a look at the code.
   
   * At the top we define our Scopes. We create a cluster scope using a query filter using the kubernetes label
     **`user_orchestrator_system/cluster_name`** that is equal to the EKS Cluster name. What this will do is create a 
     scope for all inventory associated with the cluster name, for example CNS_Lab_Test.
     
      ```
      // Cluster Scope
      resource "tetration_scope" "scope" {
        short_name          = local.eks_cluster_name
        short_query_type    = "eq"
        short_query_field   = "user_orchestrator_system/cluster_name"
        short_query_value   = local.eks_cluster_name
        parent_app_scope_id = var.secure_workload_root_scope
      }
      ```
   * Then we create a nested scope for the Yelb application which is with is using label 
     **`user_orchestrator_system/namespace`**
     which is equal to the Yelb Namespace. So all inventory with namespace named yelb will be added to this scope.
     
      ```
      // Yelb App Scope
      resource "tetration_scope" "yelb_app_scope" {
        short_name          = "Yelb"
        short_query_type    = "eq"
        short_query_field   = "user_orchestrator_system/namespace"
        short_query_value   = "yelb"
        parent_app_scope_id = tetration_scope.scope.id
      }
      ```
   * After the scopes we create inventory filters for the pods and services running in the cluster. Below is just a 
     snippet of the Yelb DB service and pod filters. As you can see they are using the labels 
     **`user_orchestrator_system/service_name`** and **`user_orchestrator_system/pod_name`**.
   
      ```
      // Yelb App Filters
      resource "tetration_filter" "yelb-db-srv" {
        name         = "${local.eks_cluster_name} Yelb DB Service"
        query        = <<EOF
                          {
                            "type": "eq",
                            "field": "user_orchestrator_system/service_name",
                            "value": "yelb-db"
                          }
                EOF
        app_scope_id = tetration_scope.yelb_app_scope.id
        primary      = true
        public       = false
      }
      resource "tetration_filter" "yelb-db-pod" {
        name         = "${local.eks_cluster_name} Yelb DB Pod"
        query        = <<EOF
                          {
                            "type": "contains",
                            "field": "user_orchestrator_system/pod_name",
                            "value": "yelb-db"
                          }
                EOF
        app_scope_id = tetration_scope.yelb_app_scope.id
        primary      = true
        public       = false
      }
      ...data omitted
      ```
     
   * Finally, we create the Yelb application and policies, which we assign to the Yelb Scope. Here is snippet of the
     application, and the first policy rule.
   
      ```
      resource "tetration_application" "yelb_app" {
        app_scope_id = tetration_scope.yelb_app_scope.id
        name = "Yelb"
        description = "3-Tier App"
        alternate_query_mode = true
        strict_validation = true
        primary = false
        absolute_policy {
          consumer_filter_id = tetration_filter.any-ipv4.id
          provider_filter_id = tetration_filter.yelb-ui-srv.id
          action = "ALLOW"
          layer_4_network_policy {
            port_range = [80, 80]
            protocol = 6
          }
        }
      ...data omitted
      ```
   
   Change the name of file **`secure_workload`** to **`secure_workload.tf`** and run **`terraform plan -out tfplan`** 
   and **`terraform apply "tfplan"`** to deploy the resources.
   
   Verify the resources by going back into the Secure Workload dashboard. From the menu go to **`Organize`** > 
   **`Scopes and Inventory`**. You will now see 2 nested scopes under the root scope, for example in this case the 
   cluster scope is named **`CNS_Lab_Test`** and the app scope is named **`Yelb`**. Under the **`Yelb`** scope you will 
   see all the inventory filters. If you click on each inventory filter it will show what resources (pods or services) 
   are assigned. 
   
   ![Secure Workload Scopes](/images/sw-scopes-deployed.png)

   Next, from the menu bar go to **`Defend`** > **`Segmentation`**. You will see a new workspace called `Yelb`. Notice
   that this workspace is assigned to the nested `CNS_Lab_Test:Yelb` scopes. Click on the Yelb workspace.
   
   ![Secure Workload Scopes](/images/sw-ws-yelb.png)

   Select **`Policies`** and **`Absolute policies`** and this will show all the policies that were deployed using the
   Terraform resources. 
   
   ![Secure Workload Policies](/images/sw-ws-policies.png)
   
Cisco Secure Workload provides a distributed firewall in the Cloud Native environment using a daemonset which  
securely segments applications while microservices are being spun up. Since the application is being defined using
kubernetes services and deployments, using Terraform as the IaC tool here allows us to define the policy along with the 
application and its infrastructure. 

## Part 2
**(OPTIONAL)**

### Integrating IaC into a Continuous Deployment Pipeline
In this section we will use Jenkins as our CI/CD tool to integrate our Infrastructure using **Pipeline as Code**.  


[Pipeline as Code](https://www.jenkins.io/doc/book/pipeline-as-code/) describes a set of features that allow Jenkins 
users to define pipelined job processes with code, 
stored and versioned in a source repository. These features allow Jenkins to discover, manage, and run jobs for multiple 
source repositories and branches - eliminating the need for manual job creation and management.

To use Pipeline as Code, projects must contain a file named Jenkinsfile in the repository root, which contains a 
"Pipeline script." Here is a look at our 
[Jenkinsfile](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Jenkinsfile).

We will go through each stage of this Jenkinsfile in detail later in this section, but first lets get started setting 
up the Jenkins. This section assumes you already have Jenkins up and running in your environment. If you don't have
a Jenkins instance, you can go to [Installing Jenkins](https://www.jenkins.io/doc/book/installing/) for a bunch of 
install options. For this lab we used the [Docker](https://www.jenkins.io/doc/book/installing/docker/) install as we 
felt it was the easiest way to get up and running. You can run this on [Docker Desktop](https://docs.docker.com/desktop/) 
or any other version of Docker.

1. First let's fork the 
   [Cisco Cloud Native Security Workshop](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop) Github
   repository. Go to the repo and click **`Fork`**. This will allow you to fork the repo to your Github account. For
   more info on how to fork a repo go to [Fork a Repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
   on Github docs.

2. Go to the Jenkins home page and select **`New Item`**.

      ![Jenkins Home](/images/jenk-home.png)

3. Enter the name of the pipeline job and select **`Pipeline`**.

      ![Jenkins Item](/images/jenk-new-item.png)

4. Select **`Configuration`**. This will bring you to the configuration page. Give the project a description.

      ![Jenkins Configuration](/images/jenk-conf.png)

5. Scroll down to Pipeline, under the **Definition** dropdown select **`Pipeline script from SCM`**. Under **SCM** 
   select **`Git`**. Under **Repository URL** add **Your Forked Repo** URL. Under **Credentials** add your Github 
   credentials. If you don't know how to add your creds to Jenkins go to 
   [Using Credentials](https://www.jenkins.io/doc/book/using/using-credentials/) on the *Using Jenkins* documentation.
   
      ![Jenkins Pipeline Configuration](/images/jenk-pipeline.png)

6. Scroll down to **Branches to build** and under **Branch Specifier** change **`*/master`** to **`*/main`**. Under
   **Script Path** add **`Jenkinsfile`**. Select **Apply** and **Save**.
   
      ![Jenkins Pipeline Configuration](/images/jenk-branch.png)

7. Next we need to setup all the credentials in Jenkins so we can pass them to the Jenkinsfile securely using 
   environment variables. Remember in Part 1 of this lab we used the `terraform.tfvars` file to pass these credentials
   to our Terraform modules. Well that works in development when we are testing and building our Terraform code, but 
   that won't work when we are using CI/CD to continously deploy and update our infrastructure. First thing to note is 
   we don't want to save our credentials to a file in SCM. Second, we don't want our variables to be static. For
   example, we may want to change regions or availability zones depending on where we want to deploy.
   
   From the Jenkins Daskboard go to **Manage Jenkins** then **Manage Credentials**.

      ![Jenkins Manage Credentials](/images/jenk-creds.png)

8. Add the following credentials as **Secret Text** (refer to 
   [Using Credentials](https://www.jenkins.io/doc/book/using/using-credentials/) on how to create Secret Text credentials):
   * AWS Access Key
   * AWS Secret Key
   * Github Token
   * FTD Password
   * (Optional) Secure Cloud Analytics Service Key
   * (Optional) Secure Workload API Key
   * (Optional) Secure Workload API Secret
   

      
   ![Jenkins Manage Credentials](/images/jenk-creds-tokens.png)
   

9. Go back to **`Manage Jenkins`** and select **`Manage Plugins`**.
   
      ![Jenkins Manage Plugins](/images/jenk-plugins.png)

   Here we are going to add plugins for **`Terraform`** and **`Docker`**. In the search bar search for Terraform. You
   will see a plugin named **`Terraform Plugin`**. Select the install checkbox and click **`Install without restart`**.
   Do the same for **`Docker`**. In the search bar search for Docker. You
   will see a plugin named **`Docker Pipeline`**. Select the install checkbox and click **`Install without restart`**.
   
10. Go back to **`Manage Jenkins`** and select **`Global Tool Configuration`**. Scroll down to **`Docker`**. Select 
    **`Add Docker`**. Give it name and select **`Install automatically`**. Under **`Download from docker.com`** use 
    Docker version **`latest`**.
    
      ![Jenkins Docker Plugin](/images/jenk-docker.png)

11. Scroll down to **`Terraform`**. Select 
   **`Add Terraform`**. Give it name and select **`Install automatically`**. Under **`Install from bintray.com`** 
    select the version of Terraform and system type it will be running on. For example, here Terraform will be running
    on a linux amd64 host.
    
      ![Jenkins Terraform Plugin](/images/jenk-terraform.png)

    Click **`Apply`** and **`Save`**.
   

12. Now that the pipeline, credentials and plugins are configured in Jenkins, let's run through the 
   [Jenkinsfile](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/Jenkinsfile) and pick
   it apart. The first part of the **`Jenkinsfile`** is to declare the Jenkinsfile as a `pipeline` and the default 
   agent we will be using. The agent directive, which is required, instructs Jenkins to allocate an executor and 
   workspace for the Pipeline. Without an agent directive, not only is the Declarative Pipeline not valid, it would not 
   be capable of doing any work! By default the agent directive ensures that the source repository is checked out and 
   made available for steps in the subsequent stages. In this case we are using `agent any`, which will use any agent
   available. Because we are using the Jenkins on Docker deployment, the agent used will actually be a docker container.
   Next we set the `environment` variables. This is where we set all the variables needed for our deployment. We will
   pass these variables to our stages in the following steps. Notice the `credentials()` variables. This is where we 
   reference the secure variables we created in the Jenkins Credentials manager in the previous step. Also note that we
   have some variables defined for **`Prod`** and **`Dev`**. I'm pretty sure you can guess what they will be used for. 
    
      There are some additional variables needed for our pipeline to work correctly.
      * (Optional) **`SW_URL`** Add the hostname of your Secure Workload instance
      * (Optional) **`SW_ROOT_SCOPE`** Add the Secure Workload Root Scope ID        
        
      Once variables are added make sure to do a `git commit` and `git push` to update your forked repo.
   
   
   ```
   pipeline{
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
        FTD_PASSWORD           = credentials('ftd-password')
        SCA_SERVICE_KEY        = credentials('sca-service-key')
        SW_API_KEY             = credentials('sw-api-key')
        SW_API_SEC             = credentials('sw-api-sec')
        SW_URL                 = 'https://<hostname>'
        SW_ROOT_SCOPE          = '<root scope id>'
    }
   ```

13. Next we add the tools we configured in the previous steps.

   ```
       }
       tools {
           terraform 'Terraform 1.0.3'
           dockerTool 'Docker'
       }
   ```

14. Then we start building out our stages. The first stage is to checkout the repository. As you can see below we are
    checking out the Cisco Cloud Native Security Workshop repo. **When running this live you should use your forked repo.**
    Also notice we are using the **`$GITHUB_TOKEN`** environment variable.

   ```
   stages{
       stage('SCM Checkout'){
           steps{
               git branch: 'main', url: 'https://$GITHUB_TOKEN@github.com/<YOUR_GITHUB>/<YOUR_REPO>.git'
           }
   ```

15. The next stage is used to build the Dev Infrastructure environment, which is the VPC, EKS and FTDv.
    Notice that we are running terraform
    from the **`DEV/Infrastructure`** directory. This means this stage is its own terraform root module.
    Also notice that we are using the **DEV** environment
    variables for the Lab ID, AWS region and availability zones. 

   ```
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
                 -var="key_name=ftd_key"'
                 //sh 'docker run -v $(pwd)/Ansible:/ftd-ansible/playbooks -v $(pwd)/Ansible/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml'
             }
         }
     }
   ```

   If you take a look in the 
   [DEV/Infrastructure](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/tree/main/DEV/Infrastructure)
   directory you will only see **`main.tf`** and **`variables.tf`** files. Where is all the other code? 
   Well let's take a look at the 
   [main.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop/blob/main/DEV/Infrastructure/main.tf)
   file. Because we will be using the same infrastructure code in the Dev and Prod environments, we have built a 
   module. Think of a module like a function, which is repeatable code we can use over and over again. If we need to
   make changes to the module, changes would be applied to both the Dev and Prod environments, which is what we want.

   Add your remote hosts that you want to allow access to the FTD Management interface and AWS EKS API to the 
   **`remote_hosts`** variable here.

   ```
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
   ```
   
   As you can see from **`source = "github.com/emcnicholas/Cisco_Cloud_Native_Security_Infrastructure"`** we are sourcing
   the module code from GitHub. You can access this repo at 
   [Cisco Cloud Native Security Infrastructure](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Infrastructure).
   
   In this repo you will see most of the files and code we built in Part 1. 

   ![Cisco Secure Cloud Native Infrastructure](/images/github-infra.png)

16. For the next stage we build the applications, which is Yelb, NGINX, Cisco Secure Cloud Analytics and Secure Workload.
    We do the same thing here as we did with the Dev Infrastructure. We run Terraform from the **`DEV/Applications`**
    directory. You see that we added some variables for the Cisco Secure APIs.

   ```
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
   ```

   If you take a look at the **`main.tf`** file we use a module for the applications as well.

   ```
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
   ```

   This module is available at 
   [Cisco Cloud Native Security Applications](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Applications).

   ![Cisco Secure Cloud Native Applications](/images/github-appl.png)

17. Then we create a stage to test the applications, in this case we are testing the Yelb app. This is a super simple
    test where we are just going to do a http get request to the Yelb UI. We obviously should use more in-depth 
    unit, load, integration and regression testing for a real pipeline, but we're just labin it up here.
    
   ```
   stage('Test DEV Application'){
      steps{
          httpRequest consoleLogResponseBody: true, ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://$DEV_EKS_HOST:30001', validResponseCodes: '200', wrapAsMultipart: false
      }
   }
   ```

18. So far the Jenkinsfile stages were to deploy the Dev environment. After our testing is complete and successful
    we can deploy our Production environment. We will use the same exact code and modules that we did in the Dev build,
    except we will pass Prod variables using the Jenkins environment variables. Below you see that we are running
    Terraform from **`PROD/Infrastructure`** and **`PROD/Applications`** directories. 
    
   ```
           stage('Deploy PROD Infrastructure'){
               steps{
                   dir("PROD/Infrastructure"){
                       sh 'terraform init'
                       sh 'terraform apply -auto-approve \
                       -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
                       -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
                       -var="lab_id=$PROD_LAB_ID" \
                       -var="region=$PROD_AWS_REGION" \
                       -var="aws_az1=$PROD_AWS_AZ1" \
                       -var="aws_az2=$PROD_AWS_AZ2" \
                       -var="ftd_pass=$FTD_PASSWORD" -var="key_name=ftd_key"'
                       //sh 'docker run -v $(pwd)/Ansible:/ftd-ansible/playbooks -v $(pwd)/Ansible/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml'
                   }
               }
           }
   // Comment out if you are NOT deploying Secure Cloud Analytics or Secure Workload
           stage('Deploy PROD Cisco Secure Cloud Native Security'){
               steps{
                   dir("PROD/Applications"){
                       sh 'terraform init'
                       sh 'terraform apply -auto-approve \
                       -var="aws_access_key=$AWS_ACCESS_KEY_ID" \
                       -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
                       -var="lab_id=$PROD_LAB_ID" \
                       -var="region=$PROD_AWS_REGION" \
                       -var="aws_az1=$PROD_AWS_AZ1" \
                       -var="aws_az2=$PROD_AWS_AZ2" \
                       -var="sca_service_key=$SCA_SERVICE_KEY" \
                       -var="secure_workload_api_key=$SW_API_KEY" \
                       -var="secure_workload_api_sec=$SW_API_SEC" \
                       -var="secure_workload_api_url=$SW_URL" \
                       -var="secure_workload_root_scope=$SW_ROOT_SCOPE"'
                   }
               }
           }
           stage('Test PROD Application'){
               steps{
                   httpRequest consoleLogResponseBody: true, ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://$PROD_EKS_HOST:30001', validResponseCodes: '200', wrapAsMultipart: false
               }
           }
   ```

19. OK it's time to start deploying. Let's start our deployment with the Dev environment. First go to the **`Jenkinsfile`**
    and make sure only the following is uncommented.
    
   ```
   // Pipeline
   
   pipeline{
       agent any
   // Environment Variables
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
           DEV_EKS_HOST           = '3.19.111.199'
           PROD_EKS_HOST          = '<prod eks host ip>'
           REMOTE_HOSTS           = '["71.175.93.211/32","64.100.11.232/32","100.11.24.79/32"]' //ex: ["172.16.1.1", "192.168.2.2"]
       }
   // Jenkins Plugins and Tools
       tools {
           terraform 'Terraform 1.0.3'
           dockerTool 'Docker'
       }
   // Pipeline Stages
       stages{
   // Checkout Code from Github Repo
           stage('SCM Checkout'){
               steps{
                   git branch: 'main', url: 'https://$GITHUB_TOKEN@github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git'
               }
           }
   // Dev Environment Infrastructure Deployment - AWS VPC, EKS, FTDv
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
                       -var="key_name=ftd_key"'
                       //sh 'docker run -v $(pwd)/Ansible:/ftd-ansible/playbooks -v $(pwd)/Ansible/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml'
                   }
               }
           }
   // Dev Environment Applications Deployment - Yelb, NGINX, Secure Cloud Analytics and Secure Workload
   // Uncomment to run this stage
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
   ```

   Go to the Jenkins Dashboard and select your Pipeline job. Then select **`Build Now`**.
    
      ![Jenkins Pipeline Build](/images/jenk-build.png)
   
20. The run will start and should look like the screenshot below. You can see the stages we configured in our Jenkinsfile 
    and if the
    stages passed for failed. If any of the stages fail, please make sure all the variables are defined correctly and
    your forked Github repo has been updated. 
    
    The first run will take about 20 minutes because the EKS Cluster and FTDv takes time to provision.
    
      ![Jenkins Pipeline Build](/images/jenk-run.png)
   
21. On the menu bar select **`Open Blue Ocean`**.
    
      ![Jenkins Blue Ocean](/images/jenk-blue.png)
   
22. Blue Ocean gives us a much better interface for reviewing the output of the runs. Select the latest run to get
    details.

      ![Jenkins Blue Ocean](/images/jenk-blue-run.png)
   
23. At the top you will see the build status. You can click on any stage to get details. Click on 
    **`Build DEV Infrastructure`** stage and there will be a list of all steps in the stage. 
    
      ![Jenkins Blue Ocean](/images/jenk-blue-out.png)
    
24. Click through the steps to see the output for each step. Take a look at the last step **`terraform apply`** to
    get more details on the build.
    
      ![Jenkins Blue Ocean](/images/jenk-blue-tf-apply.png)
    
25. Scroll all the way down to the bottom, and you will see that 48 resources have been added, and we have some
    output variables.
    
      ![Jenkins Blue Ocean](/images/jenk-blue-tf-apply-comp.png)
    
26. Copy and save the output variables as we will need them. Open another browser tab to access the Secure Firewall
    management interface. Go to https://<dev_ftd_mgmt_ip and verify the firewall is up and running, and the policies 
    are configured. 
    
      ![Secure Firewall Dashboard](/images/ftd-dev-dash.png)
    
27. Open your AWS Dashboard and go to Elastic Kubernetes Service. Click on Amazon EKS Clusters and 
    verify the Cluster name, for example CNS_Lab_Dev, is up and running. 
    
      ![AWS EKS Dashboard](/images/aws-eks-cluster.png)
    
28. Go to your Cisco Secure Cloud Analytics portal and go to the Sensors screen
    and verify that the daemonset has been deployed and that events are being consumed. 
    
      ![Secure Cloud Analytic Sensors](/images/swc-dev-sensor.png)
    
29. Go to your Cisco Secure Workload portal and verify scopes and policies have been built.

      ![Secure Workload Scopes](/images/sw-dev-scopes.png)   ![Secure Workload Policies](/images/sw-dev-policy.png)

    
30. Using the Terraform outputs from Jenkins **`Build DEV Infrastructure`** stage, copy the **`dev_eks_public_ip`** and go 
    back to the **`Jenkinsfile`**. Add the IP address to the **`Test DEV Application`** stage
    *(this step is manual today, but we are building automation to take care of this)*.

   ```
           stage('Test DEV Application'){
               steps{
                   httpRequest consoleLogResponseBody: true, ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://<dev_eks_public_ip>:30001', validResponseCodes: '200', wrapAsMultipart: false
               }
           }
   ```

31. Go down to the **`Test DEV Application`**, **`Deploy PROD Infrastructure`**, and 
    **`Deploy PROD Cisco Secure Cloud Native Security`** and uncomment these stages. Do a **`git commit`** and 
    **`git push`** to update your forked repository.

32. Go back into your Jenkins Dashboard, select your Pipeline job and click **Build Now**. You will see the additional
    stages added for Prod. 

      ![Jenkins Build](/images/jenk-prod-build.png)
    
33. Now go to the Blue Ocean and review the build.

      ![Jenkins Build](/images/jenk-prod-blue.png)
    
34. In the Blue Ocean interface, select the **`Deploy PROD Infrastructure`** stage. Extend the **`terraform apply`**
    step. Scroll down to the bottom and copy the terraform outputs. Copy the **`prod_eks_public_ip`** variable IP
    address. Go back into the **`Jenkinsfile`** and go down to the **`Test PROD Application`** stage. Uncomment the 
    stage and add the **`prod_eks_public_ip`** IP address.
    
   ```
           stage('Test PROD Application'){
               steps{
                   httpRequest consoleLogResponseBody: true, ignoreSslErrors: true, responseHandle: 'NONE', url: 'http://<prod_eks_public_ip>:30001', validResponseCodes: '200', wrapAsMultipart: false
               }
           }
   ```
35. Go back to the Jenkins Dashboard, select your pipeline job and run it.

      ![Jenkins Build](/images/jenk-build-final.png)

36. Go into Blue Ocean and explore the full pipeline run.

### Congratulations you have completed the Cisco Cloud Native Workshop!!!
    
    

    
