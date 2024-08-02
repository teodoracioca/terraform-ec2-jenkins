provider "aws" {
  region = "eu-central-1"
}

# Reference the default VPC
data "aws_vpc" "default" {
  default = true
}

# Reference the existing Internet Gateway
data "aws_internet_gateway" "internet-gw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_route_table" "rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.internet-gw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = "subnet-0d36451c51ebbc7bb"
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg-nou" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "8080 from the Internet"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from the internet"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Reference the default Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "example" {
  ami                    = "ami-026c3177c9bd54288"
  instance_type          = "t2.micro"
  subnet_id              = "subnet-0d36451c51ebbc7bb"
  vpc_security_group_ids = [aws_security_group.sg-nou.id]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World!" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF

  user_data_replace_on_change = true

  tags = {
    Name = "instanta-teo"
  }
}