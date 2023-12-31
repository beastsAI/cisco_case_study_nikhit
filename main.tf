# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.my_vpc.id
}


# Create public and private subnets
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(var.private_subnet_cidr_blocks, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  depends_on        = [aws_vpc.my_vpc]
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
  cluster_version = "1.27"                          # Specify your desired EKS version
  subnet_ids      = aws_subnet.private_subnet[*].id # Use this to specify the subnets
  vpc_id          = aws_vpc.my_vpc.id
  tags = {
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
    type = "fixed-response"
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
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
    }
  }
}

# Create an S3 bucket for hosting the frontend application
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "my-frontend-bucket"

  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_cors_configuration" "frontend" {
  bucket = module.s3_bucket.s3_bucket_id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = module.s3_bucket.s3_bucket_id

  index_document {
    suffix = "index.html"
  }
}
