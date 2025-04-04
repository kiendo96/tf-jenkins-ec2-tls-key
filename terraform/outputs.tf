output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "The ID of EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${aws_instance.web_server.public_dns}"
}

output "private_key_pem" {
  description = "Generated Private Key in PEM format"
  value       = tls_private_key.generated_ssh_key.private_key_pem
  sensitive   = true
}

output "key_pair_name_output" {
  description = "Name of the key pair created in AWS"
  value       = aws_key_pair.generated_key_pair.key_name
}