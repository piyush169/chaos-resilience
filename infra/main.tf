provider "aws" {
    region = "us-east-1"
}
variable "public_key" {
  description = "The public SSH key for the EC2 instance"
  type        = string
}

resource "aws_vpc" "chaos_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "chaos-vpc" }
}

resource "aws_subnet" "chaos_subnet" {
  vpc_id                  = aws_vpc.chaos_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  tags = { Name = "chaos-subnet" }
}

resource "aws_internet_gateway" "chaos_igw" {
  vpc_id = aws_vpc.chaos_vpc.id
}

resource "aws_route_table" "chaos_rt" {
  vpc_id = aws_vpc.chaos_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chaos_igw.id
  }
}

resource "aws_route_table_association" "chaos_rta" {
  subnet_id      = aws_subnet.chaos_subnet.id
  route_table_id = aws_route_table.chaos_rt.id
}

resource "aws_security_group" "chaos_sg" {
  name        = "chaos-sg-default"
  description = "Allow inbound traffic for chaos lab"
  vpc_id      = aws_vpc.chaos_vpc.id  

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
        from_port   = 8080
        to_port     = 8080
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


resource "aws_security_group_rule" "lambda_to_redis_bridge" {
  type              = "ingress"
  from_port         = 31379
  to_port           = 31379
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.chaos_sg.id
  description       = "Allows Lambda to trigger chaos by pushing to Redis"
}

resource "aws_key_pair" "chaos_deployer" {
  key_name   = "chaos-keypair"
  public_key = var.public_key
}

//
resource "aws_instance" "chaos_target" {
    ami          = "ami-0b6c6ebed2801a5cb" 
    instance_type = "m7i-flex.large"
    key_name   = aws_key_pair.chaos_deployer.key_name
    subnet_id     = aws_subnet.chaos_subnet.id  
    vpc_security_group_ids = [aws_security_group.chaos_sg.id]
    depends_on = [aws_security_group.chaos_sg]
    iam_instance_profile = "ChaosWorkerRole"

    root_block_device {
    volume_size = 20      
    volume_type = "gp3" 
  }

    tags = {
    Name        = "Chaos-Lab-Instance"
    Environment = "Dev"
    Project     = "Chaos-Resilience"
  }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker ubuntu
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                sudo install minikube-linux-amd64 /usr/local/bin/minikube
                sudo -u ubuntu minikube start --driver=docker
                sudo mkdir -p /home/ubuntu/k8s
                sudo chown ubuntu:ubuntu /home/ubuntu/k8s
                sudo minikube mount /home/ubuntu/k8s:/k8s &
            EOF
  
}

