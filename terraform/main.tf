# provider let know terraform which api to use.
# in our case provider is aws.
provider "aws" {
  profile = "adil"           # this the profile which we created using aws configure cli command
  region  = "ap-south-1"        # this will make default region as ap-south-1 which is in mumbai
  shared_credentials_file =	"C:\\Users\\A3285\\.aws\\credentials"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# this resource will create a key pair using above private key
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh

   depends_on = [tls_private_key.private_key]
}

# this resource will save the private key at our specified path.
resource "local_file" "saveKey" {
  content = tls_private_key.private_key.private_key_pem
  filename = "${var.base_path}${var.key_name}.pem"
  
}

# vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }

  enable_dns_hostnames = true
}

# public subnet
resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.0.0/24"

  availability_zone_id = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }

  map_public_ip_on_launch = true
}

# private subnet
resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.1.0/24"

  availability_zone_id = "ap-south-1b"

  tags = {
    Name = "private-subnet"
  }
}
resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# route table with target as internet gateway
resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "IG-route-table"
  }
}

# associate route table to public subnet
resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.IG_route_table,
  ]
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.IG_route_table.id
}
# elastic ip
resource "aws_eip" "elastic_ip" {
  vpc      = true
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_eip.elastic_ip,
  ]
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gateway"
  }
}

# route table with target as NAT gateway
resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "NAT-route-table"
  }
}

# associate route table to private subnet
resource "aws_route_table_association" "associate_routetable_to_private_subnet" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_route_table.NAT_route_table,
  ]
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.NAT_route_table.id
}
resource "aws_security_group" "sg_python_app" {
  depends_on = [
    aws_vpc.vpc,
  ]

  name        = "sg python app"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow TCP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["182.32.75.1/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# wordpress ec2 instance
resource "aws_instance" "python" {
  depends_on = [
    aws_security_group.sg_python_app,
    aws_instance.mysql
  ]
  ami = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_python_app.id]
  subnet_id = aws_subnet.public_subnet.id
  user_data = <<EOF
            #! /bin/bash
            yum update
            yum install gcc openssl-devel bzip2-devel libffi-devel
            cd /opt
            sudo wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tgz
            sudo tar xzf Python-3.7.4.tgz
            cd Python-3.7.4
            sudo ./configure –enable-optimizations
            sudo make altinstall
            sudo rm /usr/src/Python-3.7.4.tgz
  EOF

  tags = {
      Name = "wordpress"
  }
}
# mysql security group
resource "aws_security_group" "sg_mysql" {
  depends_on = [
    aws_vpc.vpc,
  ]
  name        = "sg mysql"
  description = "Allow mysql inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow TCP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_python_app.id]
  }

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["182.32.75.1/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# mysql ec2 instance
resource "aws_instance" "mysql" {
  depends_on = [
    aws_security_group.sg_mysql,
    aws_nat_gateway.nat_gateway,
    aws_route_table_association.associate_routetable_to_private_subnet,
  ]
  ami = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_mysql.id]
  subnet_id = aws_subnet.private_subnet.id
  user_data = file("configure_mysql.sh")
  tags = {
      Name = "mysql-instance"
  }
}