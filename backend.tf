resource "random_id" "bucket_suffix" {
 byte_length = 4
}

resource "aws_s3_bucket" "terraform_state" {
 bucket = "my-terraform-state-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
 bucket = aws_s3_bucket.terraform_state.id
 versioning_configuration {
 status = "Enabled"
 }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}