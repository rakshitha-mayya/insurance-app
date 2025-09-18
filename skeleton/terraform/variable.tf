variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_name" {
  type        = string
  default     = "BackstageEC2"
  description = "EC2 instance name"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  default = "ap-south-1a"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "ami_id" {
  # Example Amazon Linux 2 AMI for us-east-1 — update if needed
  default = "ami-01b6d88af12965bb6"
}

variable "key_pair_name" {
  # Must match a key pair that exists in your AWS account
  default = "your-keypair-name"
}