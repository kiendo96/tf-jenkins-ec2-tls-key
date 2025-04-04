variable "aws_region" {
  description = "Project name used for tagging resource"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "project_name" {
  description = "Project name used for tagging resource"
  type        = string
  default     = "my-tf-jenkins-ecc2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Desired name for the EC2 key in AWS"
  type        = string
  default     = "tf-generated-key"
}