output "frontend_bucket_url" {
  value = module.s3_bucket.s3_bucket_website_endpoint
}
