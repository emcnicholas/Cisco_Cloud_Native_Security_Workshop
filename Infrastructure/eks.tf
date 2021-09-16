// EKS Cluster //

// IAM role and policy to allow the EKS service to manage or retrieve data from other AWS services
resource "aws_iam_role" "eks-cluster-role" {
  name = "${local.vpc_name}_cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

// Security Group to access Cluster Master API //
resource "aws_security_group" "eks-cluster-sg" {
  name        = "${local.eks_cluster_name}_cluster_sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.cns_lab_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.eks_cluster_name
  }
}

resource "aws_security_group_rule" "eks-cluster-ingress-workstation-https" {
  cidr_blocks       = var.remote_hosts
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks-cluster-sg.id
  to_port           = 443
  type              = "ingress"
}
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
//////////////////////
// EKS Worker Nodes //
//////////////////////

// EKS Worker Node AWS Role //
resource "aws_iam_role" "eks_node_role" {
  name = "${local.eks_cluster_name}_eks_node_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_instance_profile" "eks-iam-instance-profile" {
  name = "${local.eks_cluster_name}_instance_profile"
  role = aws_iam_role.eks_node_role.name
}

// Security Group to access Cluster Worker Nodes
resource "aws_security_group" "eks-node-sg" {
  name = "${local.eks_cluster_name}_node_sg"
  description = "Security group for all nodes in the cluster"
  vpc_id = aws_vpc.cns_lab_vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = tomap({
    "Name" = "lab-eks-node"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  })
  }


// Allow the worker nodes networking access to the EKS master cluster
resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.eks-node-sg.id
  to_port                  = 443
  type                     = "ingress"
}

// Create a data source to fetch the latest Amazon Machine Image (AMI) that Amazon provides with an EKS compatible
// Kubernetes baked in. It will filter for and select an AMI compatible with the specific Kubernetes version being deployed.
data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks_cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

// Create an AutoScaling Launch Configuration that uses all our prerequisite
// resources to define how to create EC2 instances using them
data "aws_region" "current" {}

locals {
  eks-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority.0.data}' '${local.eks_cluster_name}'
USERDATA
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
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
CONFIGMAPAWSAUTH
}


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