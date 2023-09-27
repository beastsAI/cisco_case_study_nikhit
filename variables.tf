variable "aws_region" {
  description = "The AWS region in which to create resources."
  default     = "us-east-1" # Replace with your desired region
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16" # Replace with your desired CIDR block
}

variable "public_subnet_cidr_blocks" {
  description = "The CIDR blocks for public subnets."
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Replace with your desired CIDR blocks
}

variable "private_subnet_cidr_blocks" {
  description = "The CIDR blocks for private subnets."
  default     = ["10.0.3.0/24", "10.0.4.0/24"] # Replace with your desired CIDR blocks
}
