terraform {
  backend "s3" {
    bucket  = "myawsterraformstate" # Replace with your bucket name
    key     = "terraform.tfstate"
    region  = "us-east-1" # Specify the AWS region where your bucket is located
    encrypt = true
    #dynamodb_table = "terraform_locks" # Optional, use DynamoDB for state locking
  }
}