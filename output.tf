output "frontend_bucket_url" {
  value = aws_s3_bucket.frontend_bucket.website_endpoint
}
