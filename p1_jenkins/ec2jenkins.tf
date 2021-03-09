provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

#create the instance
resource "aws_instance" "MyJenkins" {
  ami             = "ami-096f43ef67d75e998"
  key_name        = "muna3ec2"
  instance_type   = "t2.micro"
  security_groups = ["security_jenkins_port"]
  tags = {
    Name = "jenkins_server"
  }

  #to execute commands remotely!!!
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade -y",
      "sudo yum install jenkins java-1.8.0-openjdk-devel -y",
      "sudo systemctl daemon-reload",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins",
      "sudo shutdown -P +300"
    ]
    connection {
      type        = "ssh"
      host        = self.public_ip #ip address of ec2-instance
      user        = "ec2-user"     #username of the ec2 instance
      timeout     = "1m"
      private_key = file("/Users/yannick_jkm/Documents/AWS/Keys/muna3ec2.pem") #upload the private_key
    }
  }
}

#Create security group with firewall rules
resource "aws_security_group" "security_jenkins_port" {
  name        = "security_jenkins_port"
  description = "security group for jenkins"

  # inbound SG for jenkins server
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["84.17.51.68/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["84.17.51.68/32"]
  }

  # outbound SG for jenkins server
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security_jenkins_port"
  }
}
