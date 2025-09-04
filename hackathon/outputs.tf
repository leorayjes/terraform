output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = false
}

output "database_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = false
}

output "admin_access_key" {
  description = "Admin user access key"
  value       = aws_iam_access_key.db_user_key.id
  sensitive   = false
}

output "admin_secret_key" {
  description = "Admin user secret key"
  value       = aws_iam_access_key.db_user_key.secret
  sensitive   = false
}

output "s3_bucket_public_url" {
  description = "Public S3 bucket URL"
  value       = "https://${aws_s3_bucket.data_bucket.bucket}.s3.amazonaws.com/"
}

output "web_server_ips" {
  description = "Web server public IPs"
  value       = aws_instance.web[*].public_ip
}

output "admin_server_ip" {
  description = "Admin server public IP"
  value       = aws_instance.admin.public_ip
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "application_config" {
  description = "Application configuration"
  value = {
    database_url = "mysql://admin:password123@${aws_db_instance.main.endpoint}/hackathon"
    redis_url    = "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
    s3_bucket    = aws_s3_bucket.data_bucket.bucket
    api_keys = {
      stripe = "sk_live_1234567890abcdef"
      jwt_secret = "super-secret-jwt-key-12345"
    }
  }
  sensitive = false
}