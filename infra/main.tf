provider "aws" {
    region = "ap-south-1"
}

//security group for api
resource "aws_security_group" "chaos_sg" {
    name = "chaos_sg"
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

//
resource "aws_instance" "chaos_target" {
    ami          = "ami-0ff5003538b60d5ec" 
    instance_type = "t2.medium"
    key_name      = "chaos-keypair"
    security_groups = [aws_security_group.chaos_sg.id]
    iam_instance_profile = "ChaosWorkerRole"

    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker ubuntu
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                sudo install minikube-linux-amd64 /usr/local/bin/minikube
                sudo -u ubuntu minikube start --driver=docker
            EOF
  
}