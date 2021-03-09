provider "aws" {
  region = "eu-west-1"
  access_key = ""
  secret_key = ""
}


variable "subnet_prefix" {
  description = "cidr block for the subnet"
  #type        = string
  #default
}

# 1. Create VPC

resource "aws_vpc" "prod-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "production"
  }

}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  
}

# 3. Route table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"   # send all traffic to default route
    gateway_id = aws_internet_gateway.gw.id
  }

  #route {
  #  ipv6_cidr_block        = "::/0"
  #  egress_only_gateway_id = aws_egress_only_internet_gateway.foo.id
  #}

  tags = {
    Name = "prod route-table"
  }
}


# 4. Create Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "eu-west-1b"

  ags = {
    Name = var.subnet_prefix[0].name
  }
}

  


resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "eu-west-1b"

  tags = {
    Name = var.subnet_prefix[1].name
  }
}


# 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}


# 6. Configure Security Group

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow port 22,80,443 inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}


# 7. Create a Network interface with an IP in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
  
}

# 8. Create an Elastic IP to the network interface created in step 7

resource "aws_eip" "elastic-main" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]

}

output "server_publi_ip" {
  value = aws_eip.elastic-main.public_ip
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
  ami                       = "ami-08bac620dc84221eb"
  instance_type             = "t2.micro"
  availability_zone         = "eu-west-1b"
  key_name                  = "sawa1ec2"
  
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.web-server-nic.id
  }

  tags = {
    Name = "Web-server"
  }


user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo your very first web server > /var/www/html/index.html'
            EOF

}


# insert something here
