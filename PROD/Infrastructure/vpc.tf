// AWS VPC Configuration //

// VPC Resources //
resource "aws_vpc" "cns_lab_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  enable_classiclink = false
  instance_tenancy = "default"
  tags = tomap({
    "Name" = local.vpc_name
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
  })
}

resource "aws_subnet" "mgmt_subnet" {
  vpc_id            = aws_vpc.cns_lab_vpc.id
  cidr_block        = var.mgmt_subnet
  map_public_ip_on_launch = true
  availability_zone = var.aws_az1
  tags = {
    Name = "${local.vpc_name} mgmt subnet"
  }
}

resource "aws_subnet" "diag_subnet" {
  vpc_id            = aws_vpc.cns_lab_vpc.id
  cidr_block        = var.diag_subnet
  availability_zone = var.aws_az1
  tags = {
    Name = "${local.vpc_name} diag subnet"
  }
}

resource "aws_subnet" "outside_subnet" {
  vpc_id            = aws_vpc.cns_lab_vpc.id
  cidr_block        = var.outside_subnet
  map_public_ip_on_launch = true
  availability_zone = var.aws_az1
  tags = {
    Name = "${local.vpc_name} outside subnet"
  }
}

resource "aws_subnet" "inside_subnet" {
  vpc_id            = aws_vpc.cns_lab_vpc.id
  cidr_block        = var.inside_subnet
  availability_zone = var.aws_az1
  tags = {
    Name = "${local.vpc_name} inside subnet"
  }
}

resource "aws_subnet" "inside2_subnet" {
  vpc_id            = aws_vpc.cns_lab_vpc.id
  cidr_block        = var.inside2_subnet
  availability_zone = var.aws_az2
  tags = {
    Name = "${local.vpc_name} inside2 subnet"
  }
}

// Security Groups //
resource "aws_security_group" "sg_allow_all" {
  name        = "Allow All"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.cns_lab_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.vpc_name} Public Allow"
  }
}
resource "aws_security_group" "sg_mgmt" {
  name        = "Management"
  description = "Inbound Management Access"
  vpc_id      = aws_vpc.cns_lab_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.remote_hosts
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.vpc_name} Mgmt"
  }
}

// Network Interfaces //
resource "aws_network_interface" "ftd_mgmt" {
  description   = "ftd_mgmt"
  subnet_id     = aws_subnet.mgmt_subnet.id
  private_ips   = [var.ftd_mgmt_ip]
  tags = {
    Name = "${local.vpc_name} ftd_mgmt"
  }
}

resource "aws_network_interface" "ftd_diag" {
  description = "ftd_diag"
  subnet_id   = aws_subnet.diag_subnet.id
  tags = {
    Name = "${local.vpc_name} ftd_diag"
  }
}

resource "aws_network_interface" "ftd_outside" {
  description = "ftd_outside"
  subnet_id   = aws_subnet.outside_subnet.id
  //private_ip = var.ftd_outside_ip
  private_ips = var.ftd_outside_ip_list
  source_dest_check = false
  tags = {
    Name = "${local.vpc_name} ftd_outside"
  }
}

resource "aws_network_interface" "ftd_inside" {
  description = "ftd_inside"
  subnet_id   = aws_subnet.inside_subnet.id
  private_ips = [var.ftd_inside_ip]
  source_dest_check = false
  tags = {
    Name = "${local.vpc_name} ftd_inside"
  }
}

// Attach Security Groups to Network Interfaces //
resource "aws_network_interface_sg_attachment" "ftd_mgmt_attachment" {
  depends_on           = [aws_network_interface.ftd_mgmt]
  security_group_id    = aws_security_group.sg_mgmt.id
  network_interface_id = aws_network_interface.ftd_mgmt.id
}

resource "aws_network_interface_sg_attachment" "ftd_outside_attachment" {
  depends_on           = [aws_network_interface.ftd_outside]
  security_group_id    = aws_security_group.sg_allow_all.id
  network_interface_id = aws_network_interface.ftd_outside.id
}

resource "aws_network_interface_sg_attachment" "ftd_inside_attachment" {
  depends_on           = [aws_network_interface.ftd_inside]
  security_group_id    = aws_security_group.sg_allow_all.id
  network_interface_id = aws_network_interface.ftd_inside.id
}

// Internet Gateway //
resource "aws_internet_gateway" "int_gw" {
  vpc_id = aws_vpc.cns_lab_vpc.id
  tags = {
    Name = "${local.vpc_name}Internet Gateway"
  }
}

// Routing Tables //
resource "aws_route_table" "ftd_outside_route" {
  vpc_id = aws_vpc.cns_lab_vpc.id

  tags = {
    Name = "${local.vpc_name} outside routing table"
  }
}
resource "aws_route_table" "ftd_inside_route" {
  vpc_id = aws_vpc.cns_lab_vpc.id

  tags = {
    Name = "${local.vpc_name} inside routing table"
  }
}

// External Default Route to Internet Gateway //
resource "aws_route" "ext_default_route" {
  route_table_id         = aws_route_table.ftd_outside_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.int_gw.id
}

// Internal Default Route //
resource "aws_route" "inside_default_route" {
  depends_on              = [aws_instance.ftdv]
  route_table_id          = aws_route_table.ftd_inside_route.id
  destination_cidr_block  = "0.0.0.0/0"
  network_interface_id    = aws_network_interface.ftd_inside.id
}

resource "aws_route_table_association" "outside_association" {
  subnet_id      = aws_subnet.outside_subnet.id
  route_table_id = aws_route_table.ftd_outside_route.id
}

resource "aws_route_table_association" "mgmt_association" {
  subnet_id      = aws_subnet.mgmt_subnet.id
  route_table_id = aws_route_table.ftd_outside_route.id
}

resource "aws_route_table_association" "inside_association" {
  subnet_id      = aws_subnet.inside_subnet.id
  route_table_id = aws_route_table.ftd_inside_route.id
}

// Elastic IP Address Assignment //

resource "aws_eip" "ftd_mgmt_EIP" {
  vpc   = true
  depends_on = [aws_internet_gateway.int_gw]
  tags = {
    "Name" = "${local.vpc_name} FTD Mgmt"
  }
}

resource "aws_eip" "eks_outside_EIP" {
  vpc   = true
  depends_on = [aws_internet_gateway.int_gw]
  associate_with_private_ip = aws_network_interface.ftd_outside.private_ip == var.ftd_outside_ip_list[0] ? var.ftd_outside_ip_list[1] : var.ftd_outside_ip_list[0]
  tags = {
    "Name" = "${local.vpc_name} EKS Outside"
  }
}

// Associate Elastic IP Addresses with Network Interfaces //
resource "aws_eip_association" "ftd_mgmt_ip_assocation" {
  network_interface_id = aws_network_interface.ftd_mgmt.id
  allocation_id        = aws_eip.ftd_mgmt_EIP.id
}

resource "aws_eip_association" "eks_outside_ip_association" {
    private_ip_address   = aws_network_interface.ftd_outside.private_ip == var.ftd_outside_ip_list[0] ? var.ftd_outside_ip_list[1] : var.ftd_outside_ip_list[0]
    network_interface_id = aws_network_interface.ftd_outside.id
    allocation_id        = aws_eip.eks_outside_EIP.id
}