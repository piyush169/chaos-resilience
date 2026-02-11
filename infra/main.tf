provider "aws" {
    region = "ap-south-1"
}
variable "public_key" {
  description = "The public SSH key for the EC2 instance"
  type        = string
}

//security group for api
resource "aws_security_group" "chaos_sg" {
    name = "chaos-sg-${terraform.workspace}"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_key_pair" "chaos_deployer" {
  key_name   = "chaos-keypair"
  public_key = var.public_key
}

//
resource "aws_instance" "chaos_target" {
    ami          = "ami-019715e0d74f695be" 
    instance_type = "m7i-flex.large"
    key_name   = aws_key_pair.chaos_deployer.key_name
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
                sudo minikube mount /home/ubuntu/k8s:/k8s &
            EOF
  
}