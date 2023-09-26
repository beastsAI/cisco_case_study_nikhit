# provider "aws" {
#   region = "us-east-1"  # Specify your desired AWS region
# }

# # Create an S3 bucket for hosting the frontend application
# resource "aws_s3_bucket" "frontend_bucket" {
#   bucket = "my-frontend-bucket"  # Replace with your preferred bucket name
#   acl    = "public-read"

#   website {
#     index_document = "index.html"  # The main HTML file for your frontend
#   }
# }

# # Enable CORS (Cross-Origin Resource Sharing) to allow web access from your domain
# resource "aws_s3_bucket_cors" "frontend_cors" {
#   bucket = aws_s3_bucket.frontend_bucket.id

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET"]
#     allowed_origins = ["*"]  # Replace with your domain when deploying to production
#   }
# }

# # Upload your frontend files to the S3 bucket
# resource "aws_s3_bucket_object" "frontend_files" {
#   for_each = fileset("${path.module}/frontend", "**/*")
#   bucket   = aws_s3_bucket.frontend_bucket.id
#   source   = "${path.module}/frontend/${each.key}"
#   key      = each.key
#   content_type = "text/html"  # Update content types as needed for your files
# }

# # Output the S3 bucket URL where the frontend is hosted
# output "frontend_bucket_url" {
#   value = aws_s3_bucket.frontend_bucket.website_endpoint
# }
