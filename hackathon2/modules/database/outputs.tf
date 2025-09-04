# Database Module Outputs
# Export database resources for use by other modules

# RDS outputs
output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_availability_zone" {
  description = "RDS instance availability zone"
  value       = aws_db_instance.main.availability_zone
}

output "rds_multi_az" {
  description = "RDS Multi-AZ configuration"
  value       = aws_db_instance.main.multi_az
}

output "rds_storage_encrypted" {
  description = "RDS storage encryption status"
  value       = aws_db_instance.main.storage_encrypted
}

output "rds_backup_retention_period" {
  description = "RDS backup retention period"
  value       = aws_db_instance.main.backup_retention_period
}

# ElastiCache outputs (conditional)
output "cache_cluster_id" {
  description = "ElastiCache cluster identifier"
  value       = var.enable_cache ? aws_elasticache_replication_group.main[0].replication_group_id : null
}

output "cache_cluster_arn" {
  description = "ElastiCache cluster ARN"
  value       = var.enable_cache ? aws_elasticache_replication_group.main[0].arn : null
}

output "cache_cluster_endpoint" {
  description = "ElastiCache cluster primary endpoint"
  value       = var.enable_cache ? aws_elasticache_replication_group.main[0].primary_endpoint_address : null
  sensitive   = true
}

output "cache_cluster_port" {
  description = "ElastiCache cluster port"
  value       = var.enable_cache ? aws_elasticache_replication_group.main[0].port : null
}

output "cache_cluster_reader_endpoint" {
  description = "ElastiCache cluster reader endpoint"
  value       = var.enable_cache ? aws_elasticache_replication_group.main[0].reader_endpoint_address : null
  sensitive   = true
}

output "cache_auth_token_enabled" {
  description = "Whether Redis auth token is enabled"
  value       = var.enable_cache && var.environment == "prod" ? true : false
}

# Secrets Manager outputs (production only)
output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = var.environment == "prod" ? aws_secretsmanager_secret.db_password[0].arn : null
  sensitive   = true
}

output "cache_secret_arn" {
  description = "ARN of the cache auth token secret"
  value       = var.enable_cache && var.environment == "prod" ? aws_secretsmanager_secret.redis_auth[0].arn : null
  sensitive   = true
}

# Parameter Group outputs
output "db_parameter_group_name" {
  description = "Name of the RDS parameter group"
  value       = aws_db_parameter_group.main.name
}

output "cache_parameter_group_name" {
  description = "Name of the ElastiCache parameter group"
  value       = var.enable_cache ? aws_elasticache_parameter_group.redis[0].name : null
}

# Connection information for applications
output "database_connection_info" {
  description = "Database connection information for applications"
  value = {
    rds = {
      endpoint = aws_db_instance.main.endpoint
      port     = aws_db_instance.main.port
      database = aws_db_instance.main.db_name
      username = aws_db_instance.main.username
      # Note: Password should be retrieved from Secrets Manager in production
      secrets_arn = var.environment == "prod" ? aws_secretsmanager_secret.db_password[0].arn : null
    }
    redis = var.enable_cache ? {
      endpoint = aws_elasticache_replication_group.main[0].primary_endpoint_address
      port     = aws_elasticache_replication_group.main[0].port
      auth_token_required = var.environment == "prod" ? true : false
      secrets_arn = var.environment == "prod" ? aws_secretsmanager_secret.redis_auth[0].arn : null
    } : null
  }
  sensitive = true
}

# Configuration summary
output "database_summary" {
  description = "Summary of database configuration"
  value = {
    environment = var.environment
    rds = {
      instance_class = var.db_instance_class
      storage_gb = var.db_allocated_storage
      multi_az = var.enable_multi_az
      backups_enabled = var.enable_backups
      encrypted = true
      engine = "mysql"
      engine_version = "8.0"
    }
    redis = var.enable_cache ? {
      node_type = var.cache_node_type
      num_nodes = var.cache_num_cache_nodes
      encryption_at_rest = true
      encryption_in_transit = true
      auth_token_enabled = var.environment == "prod"
      engine_version = "7.0"
    } : null
  }
}