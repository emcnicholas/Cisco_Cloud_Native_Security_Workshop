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

## Prerequisites
The following software is mandatory to run this code successfully. Cisco Secure Firewall will be deployed using an eval license on AWS.
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

## Instructions

### Set up the Terraform project
1. First thing to do is to set up a project on your local environment. From your IDE or the CLI create a project directory to work in.
You can name the directory whatever you would like. Clone
   [This Repository](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Workshop.git)
to your project directory and move into the /Cisco_Cloud_Native_Security_Part1 directory. Take a look inside the directory. 

        Cisco_Cloud_Native_Security % ls 
        DEV             Jenkinsfile     LICENSE         PROD            README.md       images

2. Let's start in the **Terraform** directory. We need to create a few global variables in our project. Terraform uses a
*variable definitions file* to set these global variables. The file must be named `terraform.tfvars` or any name ending in `.auto.tfvars`.
In this case we created a file called `terraform.tfvars`. Let's take a look at the 
   [terraform.tfvars](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/terraform.tfvars)
   file:

   ```   
   // Global Variables
   
   // AWS Environment
   aws_access_key     = "<aws access key>"
   aws_secret_key     = "<aws secret key>"
   vpc_name           = "CNS_Lab"
   region             = "us-east-2"
   aws_az1            = "us-east-2a"
   aws_az1            = "us-east-2b"
   lab_id             = "1" // Lab ID (1 through 25)
   remote_hosts       = ["172.16.1.1/32","192.168.2.2/32"] //this is a list, seperate multiple hosts with commas   
   // FTD Variables
   FTD_version        = "ftdv-6.7.0" //Allowed Values = ftdv-6.7.0, ftdv-6.6.0,
   ftd_user           = "admin"
   ftd_pass           = "<password>"
   key_name           = "<ssh key>"   
   ```   
   These variables are defined globally, so they will be passed to any variables declared in any other terraform files in this
   project. Here we configure the 
   * `aws_access_key` and `aws_secret_key` to authenticate to the AWS API 
   * `vpc_name` which creates a name for the VPC as well as appends the name to any tags we give to resources in the project
   * VPC `region` and availability zone (`aws_az1` and `aws_az2`)
   * `lab_id` which is appended to the end of the `vpc_name`
   * `remote_hosts` which is used to permit access inbound to the FTD mgmt interface and EKS API (Add you public IP address here)
   * `FTD_version` is the version of FTDv we use from the AWS Marketplace
   * `ftd_user` and `ftd_pass` is the username and password we configure on the FTD instance
   * `key_name` is the ssh key created on AWS to access EC2 instances. This must be created previous to running terraform ([Create SSH Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)).

3. Next we created a variables file to use in our terraform module. If you are asking "didn't we just create a variables
   file", we did but at a global level. Now we need to configure the variables at the module level. A module is a 
   container for multiple resources that are used together. Modules can be used to create lightweight abstractions, 
   so that you can describe your infrastructure in terms of its architecture, rather than directly in terms of physical 
   objects. The .tf files in your working directory when you run terraform plan or terraform apply together form the 
   root module. That module may call other modules and connect them together by passing output values from one to input 
   values of another.
   The top directory, in this case `/terraform` is assigned to the **Root** module. We can create multiple directories 
   under the root module that would be defined as **Nested Modules**. In part 1 we will only be using the **Root**
   module to develop our IaC, but in part 2 we will use **Nested Modules** to partition our code.
   In the `/terraform` directory we have a file named `variables.tf` which will define all the variables used in the 
   **Root** module. Like I said above, the `terraform.tfvars` file sets global variables for all modules, but this
   `variables.tf` file sets variables just for the root module. The cool thing about the variables set in this file is 
   that we can now set defaults. What this allows us to do is only set variables in the `terraform.tfvars` files that
   we need to change for our environment and leave all the other variables in the `variables.tf` file as default.
   Let's take a look at the [variables.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/variables.tf) 
   file.
   ```
   //Subnet and IP addresses
   variable "outside_subnet" {
       default = "10.0.0.0/24"
   }
   variable "ftd_outside_ip_list" {
       type = list(string)
       default = ["10.0.0.10","10.0.0.11"]
   }
   variable "ftd_outside_ip" {
       default = "10.0.0.10"
   }
   variable "eks_outside_ip" {
       default = "10.0.0.11"
   }
   variable "inside_subnet" {
       default = "10.0.1.0/24"
   }
   variable "ftd_inside_ip" {
       default = "10.0.1.10"
   }
   ...
   ```
   In the `variables.tf` file we have a bunch of additional variables that are defined for the VPC such as subnets, 
   network addresses, eks cluster info, and a lot more. If you noticed, some variables have defaults assigned and some 
   don't. We can assign any of these variables in the `terraform.tfvars` and it will take precedence over the defaults. 
   The variables that **do not** have defaults need to be assigned in `terraform.tfvars`. For example, lets say we wanted
   to use a different IP address for `variable "ftd_outside_ip"`. All we need to do is assign that variable in the 
   `terraform.tfvars` as such:
   >ftd_outside_ip = 10.0.0.99
   
   This will declare the `ftd_outside_ip` as `10.0.0.99` instead of the default `10.0.0.10` when we apply our terraform
   files. Now that we have all the variables defined lets start building some Infrastructure as Code.
   
### Building the Infrastructure as Code
In the following steps we configure code to deploy a VPC, EKS Cluster, and FTDv instance.

1. When using Terraform to deploy IaC the first thing we need are providers. A Terraform Provider represents an 
   integration that is responsible for understanding API interactions with the underlying infrastructure, such as a 
   public cloud service (AWS, GCP, Azure), a PaaS service (Heroku), a SaaS service (DNSimple, CloudFlare), or on-prem 
   resources (vSphere). The Provider then exposes these as resources that Terraform users can interface with, from 
   within Terraform a configuration.
   
   We can add these providers to any of our terraform files, but in our case we added them to the `main.tf`
   file. Let's take a look at the [main.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/main.tf) 
   file:
   ```   
   // Providers //
   provider "aws" {
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
   region     =  var.region
   }
   ...
   ```
   We will discuss the additional providers later in this document, but for now let's go over the AWS provider. This
   provider will download all the resources we need to configure zones, CIDRs, subnets, addresses, VPCs, Internet
   Gateways, EKS Clusters, EC2 instance, etc.... All we need to provide is the `access_key`, `secret_key` and `region`.
   Each AWS region has its own provider. 

   
2. Now that we have the AWS provider we can configure AWS resources. We created a file named `vpc.tf` just for the VPC
   configuration. We could stick all of our resources in one file, such as `main.tf`, but this becomes hard to manage 
   once our configuration grows to thousands of line. So we segment our code into smaller manageable files. The `vpc.tf`
   has a lot of configuration, such as: 
   * VPC configuration
   * Subnets
   * Security Groups
   * Network Interfaces
   * Internet gateway
   * Routes
   * Elastic IP address (public IP addresses)
   
   All these resources deploy the AWS network infrastructure. Let's take a look at the 
   [vpc.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/vpc.tf) file.

   
3. Now that there is a network, next we create a file for the Cisco Secure Firewall (FTDv) instance called `ftdv.tf`. 
   The FTDv will attach to all the network interfaces and subnets assigned in the `vpc.tf` file. Let's take a look at 
   the [ftdv.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/ftdv.tf) file.
   
   First we pull the AWS AMI data source ([what's a data source?](https://www.terraform.io/docs/language/data-sources/index.html))
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
   
   Also notice the `"template_file" "startup_file"` data source. This refers to a `startup_file.json` file
   we want to bootstrap the AWS instance. In this case the 
   [startup_file.json](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/startup_file.json) 
   contains the FTDv admin password, hostname, and management type:
   ```
   {
       "AdminPassword": "${ftd_pass}",
       "Hostname": "FTD-${lab_id}",
       "ManageLocally": "Yes"
   }
   ```

4. Now we add AWS EKS to deploy are application on. In this use case we are only using 1 worker node with no load
   balancing instance (just to save some money). We created the `eks.tf` file which deploys our EKS cluster and worker nodes.
   In addition to the snippet below there are also other resources created such as AWS IAM Roles, Policies, and 
   Security Groups.
   
   Check out the [eks.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/eks.tf) 
   file.
   ```
   ...
   
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
   
   ...
   
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
   
   ...
   
   ```
   
   The infrastructure is up and running. We created all our variables, deployed VPC, Cisco Secure Firewall (FTDv), and
   an EKS cluster in AWS. Now it is time to start working with **Ansible** to configure the FTDv Policy. 
   

### Using Ansible for Configuration Management
We will use Ansible to configure the Cisco Secure Firewall (FTDv) policy. We will initialize and provision the FTDv by 
accepting the EULA, configuring the Interfaces, Security zones, NAT, Access Control Policy, Routes, and Network/Service
objects.

1. The infrastructure is built, and we need to start putting some policy in place. To do this we need some information 
   from Terraform such as the FTDv management, EKS internal, and EKS external IP addresses. To get this info we created a 
   terraform file named `ftd_host_file.tf`. This file will pull this information from Terraform and create an Ansible
   hosts (inventory) file. Let's take a look at the 
   [ftd_host_file.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/ftd_host_file.tf).
   
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
       filename = "../Ansible/hosts.yaml"
   }
   ```
   
   Once again we use another data source to get the IP address of the EKS worker node. Then we grabbed the IP address 
   of the FTDv management interface, added the FTD username and password from our variables, and the EKS outside IP 
   address. We create this file in the `/Ansible` directory so it can be used with the Ansible playbooks we will discuss
   next.
   

2. Now let's take a look into the `/Ansible` directory to review the playbooks we will run on our FTDv instance. There 
   are 2 files located in this directory, `ftd_initial_provisioning.yaml` and `ftd_configuration.yaml`. There is a 3rd
   file that will be generated by `ftd_host_file.tf`, which will be `hosts.yaml` (this won't be visible until after the
   terraform apply). Let's look at the 
   [ftd_initial_provisioning.yaml](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Ansible/ftd_initial_provisioning.yaml)
   file.
   
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

   This file will take care of the initial provisioning of the FTD. When an FTDv gets spun up there is an End User 
   License Agreement (EULA) that needs to be accepted, and an evaluation license (90 days) for all its features needs to 
   be enabled. The `ftd_initial_provisioning.yaml` takes care of this for us.

   
3. After the initial provisioning of the FTDv is completed we will run the `ftd_configuration.yaml` to configure the FTDv
   policies. This playbook will configure interfaces, network objects, service objects, NAT, security zones, access
   control policies, and deploy the configuration to the FTDv instance. This configuration is too large to take a 
   snippet on this doc, but you can take a look at it at 
   [ftd_configuration.yaml](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Ansible/ftd_configuration.yaml).
   As you can see this ansible playbook creates access rules, NATs, network and service objects for two applications,
   YELB and NGINX. We will dive a little deeper into them applications later in this doc, but these are the 2 apps that
   we will be securing!!!
   

4. In the real world when we are deploying our IaC we use a CI/CD tool to do so, such as Jenkins, GitHub Actions, or 
   AWS CodePipeline, but since we are just developing our code in this Part 1 doc, we are going to "stitch" a few stages
   together to make sure our code works before integrating into a pipeline tool in Part 2. We created an `ansible_deploy.tf`
   file that will run our Ansible playbooks as a terraform resource after our infrastructure has been brought up. 
   Let's take a look at the 
   [ansible_deploy.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/ansible_deploy.tf) file.
   
   ```
   // Initial FTP provisioning //
   resource "null_resource" "ftd_init_prov" {
     depends_on = [local_file.host_file]
     provisioner "local-exec" {
         working_dir = "../ansible"
         command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_initial_provisioning.yaml"
     }
   }
   
   // FTD Configuration //
   resource "null_resource" "ftd_conf" {
     depends_on = [null_resource.ftd_init_prov]
     provisioner "local-exec" {
         working_dir = "../ansible"
         command = "docker run -v $(pwd):/ftd-ansible/playbooks -v $(pwd)/hosts.yaml:/etc/ansible/hosts ciscodevnet/ftd-ansible playbooks/ftd_configuration.yaml"
     }
   }
   ```
   
   Here we are just running these playbooks from a terraform provisioner. As you can see we are running these commands
   from **Docker**. *"Why Docker?"* you may ask. Well the kind fellas in the Cisco Secure Firewall Product Engineering
   department were awesome enough to create a **[FTD Ansible Docker Image](https://hub.docker.com/r/ciscodevnet/ftd-ansible)**, 
   where all we have to do is pass our host and playbooks files to it, and **KABOOM!!** everything is configured.
   

### Working with Kubernetes using Terraform

In this section we configure Kubernetes resources using Terraform. We will create two applications, Yelb and Nginx,
that we will use to test with.

1. First lets take a look at the Kubernetes providers we will initialize. At the beginning of the code we tell terraform 
   what version of the provider is required. This is very important because some features we us in our IaC may be 
   version specific. Next we add a couple data sources which we will fetch the EKS cluster CA Cert and Token. We use
   the data sources to configure authentication for the Kubernetes and kubectl providers. Why are there two providers
   for K8s? The first, `provider "kubernetes"` is the official Kubernetes provider and has resources and data sources
   built for almost anything you want to create via the K8s API. The second, `provider "kubectl"` allows us to apply
   native YAML files like we would if we were using the kubectl CLI. So for example, if we had a yaml file and we just
   wanted to apply it without building it as a resource, we can use the [Kubectl Provider](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs). 
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
   RBAC access to IAM users and roles. Here we created a file called `config_map_aws_auth.tf`. Lets talk a look at 
   [config_map_aws_auth.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/config_map_aws_auth.tf).
   
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
   
   We use the `kubectl_manifest` resource here to apply the config map using YAML. Notice the `rolearn` has a value of
   the role we created in our `eks.tf` file. This will allow our worker node to talk to the Cluster API.
   

### Provision the Infrastructure as Code
At this point you are ready to provision all the code in the the `/terraform` directory. The code at this point will 
provision a VPC, FTDv Instance, EKS Cluster and EKS Node *(the provisioning of Cisco Secure Cloud Analytics,
Secure Workload, and Secure Cloud Native are adding in later steps that are optional but recommended)*.
This means running the *terraform plan* and *terraform apply* commands in the directory we are working in. The `terraform
plan` command creates an execution plan by reading the current state of any already-existing remote objects to make sure 
that the Terraform state is up-to-date, comparing the current configuration to the prior state and noting any 
differences, and proposing a set of change actions that should, if applied, make the remote objects match the 
configuration. The `terraform apply` command executes the actions proposed in a Terraform plan.
For more information about terraform provisioning, see 
[Provisioning Infrastructure with Terraform](https://www.terraform.io/docs/cli/run/index.html).

1. Make sure you are in the `/terraform` directory. Run the `terraform init` command. The 
   [terraform init](https://www.terraform.io/docs/cli/commands/init.html) command is used
   to initialize a working directory containing Terraform configuration files. This is the first command that should be 
   run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run 
   this command multiple times. This will initialize all the providers and version that we declared in
   the `main.tf` file.
   
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
   
2. Run the `terraform plan` using an output file, `terraform plan -out 
   tfplan`. This writes the generated plan to the given filename in an opaque file format that you can later pass to
   terraform apply to execute the planned changes. Here we see that we are planning to deploy 60 new resources. We 
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
      + eks_cluster_name = "CNS_Lab_55"
      + eks_public_ip    = (known after apply)
      + ftd_mgmt_ip      = (known after apply)
   
   ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   
   Saved the plan to: tfplan
   
   To perform exactly these actions, run the following command to apply:
       terraform apply "tfplan"
   
   ```

3. Apply the plan using the `terraform apply "tfplan"` command. 
   The [terraform apply](https://www.terraform.io/docs/cli/commands/apply.html) command executes the actions proposed 
   in a Terraform plan. Once again below we omitted a lot of the output data, but you can see we start building the 
   infrastructure. At the end you should see 60 resources added, and some **Outputs:** we can use to access the 
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
   
   Apply complete! Resources: 60 added, 0 changed, 0 destroyed.
   
   Outputs:
   
   eks_public_ip = "18.216.235.214"
   ftd_mgmt_ip = "3.136.174.54"
   eks_cluster_name = CNS_Lab_55
   ```

### Access the Environment
Use the outputs generated from the `output.tf` file to access the environment. The IP addresses and ports above may be
different, so make sure to use the outputs from your `terraform apply`.

1. Access the Secure Firewall (FTDv) management interface by going to `https://<ftd_mgmt_ip>` where <ftd_mgmt_ip> is
   the IP from the `ftd_mgmt_ip` output. This will bring you to a logon page. Enter the username and password you defined
   in the `terraform.tfvars` file.
   
   ![FTDv Logon Page](/images/ftd-login.png)

2. Once logged in poke around and make sure everything was configured correctly from the ansible playbooks.
   Check the Policies, where you can see the Access Control and NAT rules.
   
   ![FTDv Access Control](/images/ftd-pol.png)

   ![FTDv NAT](/images/ftd-nat.png)

   Check out the Objects and Interfaces.

   ![FTDv Objects](/images/ftd-obj.png)

   ![FTDv Interfaces](/images/ftd-int.png)
 
3. Access your AWS account portal and select **Services** > **Compute** > **EC2**. There will be two instances running
   named `CNS_Lab_<lab_id>_FTDv` and `CNS_Lab_<lab_id>_node`. The `CNS_Lab_<lab_id>_FTDv` is obviously the firewall and 
   the `CNS_Lab_<lab_id>_node` is the EKS worker node where we will deploy our applications.
   
   ![AWS Compute](/images/aws-ec2.png)

4. Next lets go to **Services** > **Containers** > **Elastic Kubernetes Service**. Under **Amazon EKS** select 
   **Clusters**. There will be EKS cluster named `CNS_Lab_<lab_id>`. 
   
   ![AWS EKS Cluster](/images/eks-cluster.png)
   
   Select the cluster, and you will see the EC2 instance assigned as a worker node for the cluster.

   ![AWS EKS Node](/images/eks-node.png)

5. Finally, select to **Services** > **Networking & Content Delivery** > **VPC**. Select **Your VPC**. On the left
   hand menu bar click through VPCs, Subnets, Route Tables, Internet Gateways, and Elatic IPs. You will see resources 
   with the CNS_Lab_<lab_id> appended to the name of the resources.
   
   ![AWS VPC](/images/aws-vpc.png)

6. To access the EKS environment locally using the kubectl client, we need to 
   [Update Kube Config](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/eks/update-kubeconfig.html).
   Make sure your AWS CLI Configuration is updated and run the following command where `<aws-region>` is the region 
   the EKS cluster is deployed and where `<cluster-name>` in the EKS cluster name.
   
   `aws eks --region <aws-region> update-kubeconfig --name <cluster-name>`

   For example `aws eks --region us-east-2 update-kubeconfig --name CNS_LAB_55`


### Deploy Cisco Secure Cloud Analytics
**(OPTIONAL)**

:warning: **You will need a Cisco Secure Cloud Analytics account to complete this section**. If you don't have an account
you can sign up for a free trial 
[HERE](https://www.cisco.com/c/en/us/products/security/stealthwatch/stealthwatch-cloud-free-offer.html).

This section will show how to deploy **Cisco Secure Cloud Analytics** to this Cloud Native environment. 
[Secure Cloud Analytics](https://www.cisco.com/c/en/us/products/security/stealthwatch-cloud/index.html) 
provides the visibility and threat detection capabilities you need to keep your workloads highly 
secure in all major cloud environments like Amazon Web Services (AWS), Microsoft Azure, and Google Cloud Platform. And 
guess what, it supports integration directly with the kubernetes cluster. 

1. Log in to your Secure Cloud Analytics portal and go to `Setting` then `Integrations`. 

   ![Secure Cloud Analytics Dashboard](/images/swc-dash.png)
   
2. On the Setting menu bar select `Integrations` then `Kubernetes`.

   ![Secure Cloud Analytics Settings](/images/swc-inte.png)

3. This brings you to the Kubernetes Integration page. This page give you step by step instructions
   on how to deploy Secure Cloud Analytics to your kubernetes cluster using the `kubectl` client.
   Luckily we have created a terraform file that will deploy all necessary resources, but first we need
   to get the `secret key` from the integration page. On the integration page the first step is to 
   create a secret key file. We don't need to run this step, we just need copy and save the key itself. Where it says
   `echo -n "<secret_key>" > obsrvbl-service-key.txt`, copy and save this key.
   
   ![Secure Cloud Analytics Secret Key](/images/swc-key.png)

4. Go to the `terraform.tfvars` file and add this key to the Secure Cloud Analytics `sca_service_key` variable.

   ```
   sca_service_key    = "<secret_key>"
   ```
   
5. Find the file named `secure_cloud_analytics` and change it to `secure_cloud_analytics.tf` so terraform can read it.
   Click [secure_cloud_analytics](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/secure_cloud_analytics)
   to view the file.
   
6. Run `terraform plan -out tfplan` and review the resource that will be created. Run `terraform apply "tfplan"` to 
   create the resources. 4 kubernetes resources will be created, secret, service account, cluster role binding, and a
   daemonset. 
   
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
   * `kubectl get pods`
      ```   
       Terraform % kubectl get pods
      NAME                READY   STATUS    RESTARTS   AGE
      obsrvbl-ona-z4lkj   1/1     Running   0          74m
      ```
   * `kubectl get daemonset` What is a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)?
      ```
      Terraform % kubectl get ds 
      NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
      obsrvbl-ona   1         1         1       1            1           <none>          76m
      ```   
   
8. Now check the Cisco Secure Cloud Analytics Portal. In the upper right corner select the Sensors
   icon. 
   
   ![Secure Cloud Analytics](/images/swc-sensor.png)

   This will take you to the Sensors screen. There will be a sensor named after the EC2 instance,
   for example `ip-10-0-1-90.us-east-2.compute.internal`. It may take a few minutes for the sensor to start receiving 
   data, and the icon to turn green.
   
   ![Secure Cloud Analytics Sensors](/images/swc-sen.png)

   Once the sensor starts collecting data you can select `Investigate` then `Device`.

   ![Secure Cloud Analytics Sensors](/images/swc-devices.png)

   This will bring you to the Endpoints screen where you should see containers from our test apps 
   start showing up.
   
   ![Secure Cloud Analytics Endpoints](/images/swc-ep.png)
   
   Click on one of the devices to start drilling down into Alerts, Observations, and Session traffic.

### Deploy Cisco Secure Workload

Blah blah blah blah

### Deploy Cisco Secure Cloud Native
**(OPTIONAL)**

:warning: **You will need a Cisco Secure Cloud Native account to complete this section**.


1. Log into the dashboard

   ![Secure Cloud Native Dashboard](/images/cn-dash.png)

2. Select System > Manage Users

   ![Secure Cloud Native System](/images/cn-user.png)

3. Select add New User

   ![Secure Cloud Native Users](/images/cn-newuser.png)


4. For Role use Service User and Name it whatever you like. Click Finish and you will be provided with an Access and
Secret Key. Save the keys somewhere safe.

   ![Secure Cloud Native Token](/images/cn-token.png)

5. Create a Deployment for the EKS cluster. Select Deployments > Clusters. Click New Cluster. Cluster Name should be the 
name of the EKS Cluster (ex: CNS_Lab_55). Orchestration will be Amazon Elastic Kubernetes Service. Keep all the defaults
for options below and click Next.

   ![Secure Cloud Native Cluster](/images/cn-cluster.png)
   
6. For Connection Controls select the following and click Next. 

   ![Secure Cloud Native Connection Controls](/images/cn-cc.png)

7. For Advanced Settings select the following and click Finish. 

   ![Secure Cloud Native Advanced Settings](/images/cn-adv.png)

8. You will be presented with the Installation instructions.

   ![Secure Cloud Native Installation Info](/images/cn-install.png)

9. Download the package to the linux machine you will be executing the install script. Extract the package (ex: `tar-zxvf 
CNS_Lab_55.tar.gz`). 
   
10. Run the installation script `./install_bundle.sh`.

      * :warning: Make sure your kubeconfig context is updated
     `aws eks --region <aws-region> update-kubeconfig --name <cluster-name>`

   ```
   [centos@devbox Downloads]$ ./install_bundle.sh 
   Installing istio custom resources
   Finished creating istio custom resources
   
   Installing istio components
   Finished installing istio
   Installing Secure CN components
   Waiting for the Secure CN controller to be ready
   Secure CN controller is ready
   Finished installing Secure CN
   ```

11. The install script creates all the Istio and Secure CN components such as namespaces, pods and services. 
    Let's take a look by running a couple commands.
    
   ```
   [centos@devbox Downloads]$ kubectl get ns
   NAME              STATUS   AGE
   default           Active   23h
   istio-system      Active   14m
   kube-node-lease   Active   23h
   kube-public       Active   23h
   kube-system       Active   23h
   portshift         Active   14m
   
   [centos@devbox Downloads]$ kubectl get pods -n istio-system
   NAME                     READY   STATUS    RESTARTS   AGE
   istiod-866bff9fd-qdlff   1/1     Running   0          14m
   
   [centos@devbox Downloads]$ kubectl get pods -n portshift
   NAME                                  READY   STATUS    RESTARTS   AGE
   clair-6c75ccf778-6zjzc                1/1     Running   0          14m
   clair-postgres-7fd9ccd886-4g4ld       1/1     Running   0          14m
   nats-0                                1/1     Running   0          14m
   nats-proxy-549b67d548-php9f           1/1     Running   0          14m
   openapi-compliance-6b65979fb8-rtd4p   0/1     Pending   0          14m
   portshift-agent-7b967589fc-xqhvm      1/1     Running   0          14m
   ```
   
12. Let's deploy some apps and secure them. Now that the Secure CN controllers are deployed to the cluster we can
   deploy our applications. Go to the `/Kubernetes` and deploy `yelb_app.yaml`. 
    
   ```
   [centos@devbox Cisco_Cloud_Native_Security_Part1]$ cd Kubernetes/
   
   [centos@devbox Kubernetes]$ kubectl create -f yelb_app.yaml 
   namespace/yelb created
   service/redis-server created
   service/yelb-db created
   service/yelb-appserver created
   service/yelb-ui created
   deployment.apps/yelb-ui created
   deployment.apps/redis-server created
   deployment.apps/yelb-db created
   deployment.apps/yelb-appserver created
   
   [centos@devbox Kubernetes]$ kubectl get pods -n yelb
   NAME                              READY   STATUS    RESTARTS   AGE
   redis-server-65ffc76d5b-m2pww     3/3     Running   0          2m4s
   yelb-appserver-7c64984796-qtxtt   3/3     Running   0          2m4s
   yelb-db-69f6449f7-2km8m           3/3     Running   0          2m4s
   yelb-ui-557b95648f-clmpz          3/3     Running   2          2m4s
   ```
   
   As you can see there are 3 containers deployed in these pods. If you do a `kubectl describe pods <pod-name> -n yelb`
   this shows you a lot of data, but if you scroll down to the `Containers` section you will see details of each
   container running in the pod. Here you see the 3 containers are the `yelb-ui`, `istio-proxy`and `dns-detector.  

   ```
   [centos@devbox Kubernetes]$ kubectl describe pods yelb-ui-557b95648f-clmpz -n yelb
   Name:         yelb-ui-557b95648f-clmpz
   Namespace:    yelb
   Priority:     0
   Node:         ip-10-0-1-124.us-east-2.compute.internal/10.0.1.124
   Start Time:   Tue, 14 Sep 2021 10:30:58 -0400
   Labels: 
   
   omit....
   
   Containers:
     yelb-ui:
       Container ID:   docker://21529288f61125861468260ec1e9ee90b05485a59bf0259fd5218aa5e91669b6
       Image:          mreferre/yelb-ui:0.7
       Image ID:       docker-pullable://mreferre/yelb-ui@sha256:a2199d4f9fd38b168af93acf25331cda4e93140704bcba585d8981e0eeec0050
       Port:           80/TCP
   
   omit....
   
     istio-proxy:
       Container ID:  docker://e2ccbbb3137e8b1b116fdf48b0756169b6a59bf06f9177f3cacba22ca7c5dcb3
       Image:         gcr.io/eticloud/k8sec/istio/proxyv2:6887c8de7bc751ead056887ecec422b0fe5acfdf-dbg
       Image ID:      docker-pullable://gcr.io/eticloud/k8sec/istio/proxyv2@sha256:6e1b943c4c24debd7bf841e6aad20a3068202dfd757fdd06126cb4b17f7f7955
       Port:          15090/TCP
       
   omit....
   
     dns-detector:
       Container ID:  docker://6ffb4ec1a16051503fa0fc196dcae4585d63d6b9b802088a6d52b370ed210a59
       Image:         gcr.io/eticloud/k8sec/gopassivedns:5cb7e015b517fac57c3f935d1e46fceba60f51e6
       Image ID:      docker-pullable://gcr.io/eticloud/k8sec/gopassivedns@sha256:474c31d80923cc6d5a03779a333afaacb00f5a8dfcf9f5fc41e0829f5a62facf
       Port:          <none>
   
   ```
   
13. Go back into the Secure Cloud Native portal. Go to the menu bar on the left and select **Runtime** > **Workloads**
   and filter on the Cluster using the cluster name, for exmaple CNS_Lab_55. You will see the 4 pods deployed earlier.
    
   ![Secure Cloud Native Runtime](/images/cn-runtime.png)

14. Click into one of the pods, for example yelb-ui. Check out the data in Risk, Pod, Runtime, Security Context, and 
   API tabs. 
    In the **Risk** tab you will see any risk alerts associated with the workloads.
    
   ![Secure Cloud Native Risk](/images/cn-risk.png)
   
   The **Pod** tab shows labels and container images associated with the pod.

   ![Secure Cloud Native Pod](/images/cn-pod.png)

   The **Runtime** shows all the labels, annotations, and container images.

   ![Secure Cloud Native Runtime](/images/cn-run.png)

15. Right now we we are at the cluster level
   
   Go t Deployments > Environment. Select New Environment
   
   ![Secure Cloud Native Environment](/images/cn-env.png)

   Set the Environment name to `Yelb-App` and set risk to `Medium`. Select Next.

   ![Secure Cloud Native Environment](/images/cn-new-env.png)

   For Cluster name select your cluster name from the dropdown. For Namespace select By Name. Under names select Yelb
   and click Finish.

   ![Secure Cloud Native Environment](/images/cn-infra.png)

   Go back to Runtime > Workloads. You now see that the Environment is assigned to Yelb-App.

   ![Secure Cloud Native Runtime](/images/cn-run-env.png)

16. Let's get back to Terraform!! 

   Provider Here

   Go back to 


   

   
    
   

```
Initializing the backend...

Initializing provider plugins...
- Finding localdomain/provider/portshift versions matching ">= 1.0.2"...
- Installing localdomain/provider/portshift v1.0.2...
- Installed localdomain/provider/portshift v1.0.2 (unauthenticated)
```

```
Terraform will perform the following actions:

  # portshift_k8_cluster.myCluster will be created
  + resource "portshift_k8_cluster" "myCluster" {
      + cd_pod_template                      = false
      + ci_image_validation                  = "false"
      + connections_control                  = true
      + fail_close                           = "false"
      + id                                   = (known after apply)
      + inspect_incoming_cluster_connections = "false"
      + kubernetes_cluster_context           = "arn:aws:eks:us-east-2:208176673708:cluster/CNS_Lab_55"
      + multi_cluster_communication_support  = "false"
      + orchestration_type                   = "EKS"
      + persistent_storage                   = "false"
      + portshift_cluster_name               = "CNS_Lab_55_Cluster"
      + restrict_registries                  = false
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```


### Deploy Test Applications
In part 1 we will be deploying our applications

3. Let's deploy some apps to secure. Yelb is a cool 3 teir demo app that allows users to vote on a set of alternatives 
   (restaurants) and dynamically updates pie charts based on number of votes received. If you want some more details
   about this app check out the [Yelb GitHub](https://github.com/mreferre/yelb). For this app we built a terraform file
   named `yelb_app.tf`. In this file we create kubernetes resources such as `kubernetes_namespace`, `kubernetes_service`,
   and `kubernetes_deployment`. Below is an example for just the yelb web server. Take a look at the full manifest at 
   [yelb_app.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/yelb_app.tf) for 
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

4. We also configured a second app using the `nginx_app.tf` file. This app is just a NGINX test page that we can play
   with when testing out security controls. Check out the configuration of that app at 
   [nginx_app.tf](https://github.com/emcnicholas/Cisco_Cloud_Native_Security_Part1/blob/main/Terraform/nginx_app.tf).
   

3. Access the Yelb app by going to `http://<eks_public_ip>:<yelb_service_port>` where <eks_public_ip> is the IP address of
   the `eks_public_ip` output and <yelb_service_port> is the port of the `yelb_service_port`.
   
   ![Yelb UI](/images/yelb.png)

4. Access the NGINX app by going to `http://<eks_public_ip>:<nginx_service_port>` where <eks_public_ip> is the IP address of
   the `eks_public_ip` output and <nginx_service_port> is the port of the `nginx_service_port`.
   
   ![NGINX UI](/images/nginx.png)

5. Verify the kubernetes environment using the kubectl client.
   1. Update the kube config file by running `aws eks --region us-east-2 update-kubeconfig --name <eks-cluster-name>` 
      where <eks-cluster-name> is the name of the `eks_cluster_name` output.

      ```
      Terraform % aws eks --region us-east-2 update-kubeconfig --name CNS_Lab_1
      Added new context arn:aws:eks:us-east-2:208176673708:cluster/CNS_Lab_1 to /Users/edmcnich/.kube/config
      ```
      
   2. Run some commands to verify the resources were implemented. Run `kubectl get nodes` which will show what EKS 
      worker nodes are available to the cluster. In this lab it is just one node. Run `kubectl get ns` to see the 
      Yelb and NGINX namespaces we created. Run `kubectl get pods -n yeb` to see all th pods we created in the Yelb
      namespace. Run `kubectl get service -n yelb` to view all the services we created for the Yelb namespace.
      
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
