output "ec2_public_ip" {
  # Use the public_ip attribute directly from the aws_instance resource
  value       = aws_instance.chaos_target.public_ip
  description = "The public IP of the chaos target"
}