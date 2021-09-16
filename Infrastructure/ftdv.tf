// Data //

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


// Cisco NGFW Instances //
data "template_file" "startup_file" {
  template = file("${path.root}/startup_file.json")
  vars = {
    ftd_pass = var.ftd_pass
    lab_id = var.lab_id
  }
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