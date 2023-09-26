# Define the AWS provider configuration
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.18.1"
    }
  }
}
provider "aws" {
  region = "us-east-1" # Specify your desired AWS region

}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true
}

# Create public and private subnets
resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-cors-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_s3_policy_attachment" {
  name = "cors-iam-role"  
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # Adjust permissions as needed
  roles       = aws_iam_role.lambda_role.name
}


resource "aws_lambda_function" "configure_cors" {
  filename      = "configure_cors.py" # Replace with your actual Python script file
  function_name = "configureCorsFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_handler"
  runtime       = "python3.8"
  source_code_hash = filebase64sha256("configure_cors.py") # Update the file name accordingly

  environment {
    variables = {
      # Add any environment variables if needed
    }
  }
}



resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
}

# Create security groups for EKS cluster, ALB, and instances
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks_cluster_sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.my_vpc.id

  # Define inbound and outbound rules
  # my: Allow inbound traffic from specific IPs, e.g., for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to trusted IPs in production
  }

  # Allow outbound traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EKS cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.21" # Specify your desired EKS version
  subnet_ids      = aws_subnet.private_subnet[*].id # Use this to specify the subnets
  vpc_id          = aws_vpc.my_vpc.id
  tags            = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnet[*].id

  enable_http2 = true

  security_groups = [aws_security_group.eks_cluster_sg.id]
}

# Create ALB listeners and rules for frontend/backend routing
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
    }
  }
}

# Create an S3 bucket for hosting the frontend application
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "my-frontend-bucket" # Replace with your preferred bucket name
  acl    = "public-read"

  website {
    index_document = "index.html" # The main HTML file for your frontend
  }
}

# # Enable CORS (Cross-Origin Resource Sharing) to allow web access from your domain
# resource "aws_s3_bucket_cors" "frontend_cors" {
#   bucket = aws_s3_bucket.frontend_bucket.id

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET"]
#     allowed_origins = ["*"] # Replace with your domain when deploying to production
#   }
# }

# Upload your frontend files to the S3 bucket
resource "aws_s3_object" "frontend_files" {
  for_each      = fileset("${path.module}/frontend", "**/*")
  bucket   = aws_s3_bucket.frontend_bucket.id
  source   = "${path.module}/frontend/${each.key}"
  key      = each.key
  content_type = "text/html"  # Update content types as needed for your files
  }

# Output the S3 bucket URL where the frontend is hosted
output "frontend_bucket_url" {
  value = aws_s3_bucket.frontend_bucket.website_endpoint
}

