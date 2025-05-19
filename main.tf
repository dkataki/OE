provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "tf-user" {
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
    cidr_blocks = ["0.0.0.0/32"] # Replace with your IP
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
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = aws_key_pair.tf-user.key_name
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

# ✅ UPDATED: Grafana instance now installs Grafana OSS and starts the service
resource "aws_instance" "grafana" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.tf-user.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "Grafana"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y wget
              cat <<EOL > /etc/yum.repos.d/grafana.repo
              [grafana]
              name=grafana
              baseurl=https://packages.grafana.com/oss/rpm
              repo_gpgcheck=1
              enabled=1
              gpgcheck=1
              gpgkey=https://packages.grafana.com/gpg.key
              sslverify=1
              EOL
              yum install -y grafana
              systemctl daemon-reexec
              systemctl enable grafana-server
              systemctl start grafana-server
              EOF
}

# ✅ NEW: Output to fetch the public IP of the Grafana instance
output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
  description = "Public IP to access Grafana UI on port 3000"
}