resource "aws_s3_bucket" "data_bucket" {
  bucket = "hackathon-data-bucket-12345"
  
  tags = {
    Name = "data-bucket"
  }
}

resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_encryption" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_bucket_pab" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket = aws_s3_bucket.data_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.data_bucket.arn}/*"
      },
      {
        Sid       = "AllowUploads"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.data_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket        = "hackathon-backups-67890"
  force_destroy = true

  tags = {
    Name = "backup-bucket"
  }
}

resource "aws_s3_bucket_logging" "backup_logging" {
  bucket = aws_s3_bucket.backup_bucket.id
  
}

resource "aws_s3_object" "config_file" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "config/app-config.json"
  
  content = jsonencode({
    database = {
      host     = "prod-db.cluster-xyz.us-east-1.rds.amazonaws.com"
      username = "admin"
      password = "MySecretPassword123!"
    }
    api_keys = {
      stripe_key    = "sk_live_1234567890abcdef"
      sendgrid_key  = "SG.1234567890abcdef"
      jwt_secret    = "super-secret-jwt-key-12345"
    }
    admin_users = [
      "admin@company.com",
      "root@company.com"
    ]
  })

  content_type = "application/json"
}