
module "my_s3_bucket" {
  source = "./module/"

  ## Remember that bucket names must be unique across all of AWS
  bucket_name       = "my-tf-test-bucket" 
  versioning_status = true

  tags = {
    Environment = "Dev"
    Project     = "Infrastructure"
  }
}

output "bucket_id" {
  value = module.my_s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  value = module.my_s3_bucket.s3_bucket_arn
}
