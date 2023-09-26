import boto3

def lambda_handler(event, context):
    # Replace with your S3 bucket name
    bucket_name = "my-frontend-bucket"

    # Define the CORS configuration
    cors_configuration = {
        "CORSRules": [
            {
                "AllowedHeaders": ["*"],
                "AllowedMethods": ["GET"],
                "AllowedOrigins": ["*"]
            }
        ]
    }

    # Configure CORS for the S3 bucket
    s3_client = boto3.client("s3")
    s3_client.put_bucket_cors(Bucket=bucket_name, CORSConfiguration=cors_configuration)

    return {
        "statusCode": 200,
        "body": "CORS configuration updated successfully."
    }
