provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "my_key" {
  key_name   = "tf-user"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH and web traffic"
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["202.181.129.18/32"] # Replace YOUR_IP with your real IP
  }

  ingress {
    description = "Grafana web access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "prometheus" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 in us-east-1
  instance_type = "t2.micro"
  key_name = aws_key_pair.tf_user.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "Prometheus"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install wget -y
              EOF
}

resource "aws_instance" "grafana" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name = aws_key_pair.tf_user.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "Grafana"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install wget -y
              EOF
}

