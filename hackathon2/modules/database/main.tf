# Database Module - RDS and ElastiCache
# Creates environment-appropriate database infrastructure

# Random password for RDS (fallback if not provided)
resource "random_password" "db_password" {
  count   = var.db_password == null ? 1 : 0
  length  = 16
  special = true
}

# Local values for database configuration
locals {
  db_password = var.db_password != null ? var.db_password : random_password.db_password[0].result
  
  # Environment-specific database configurations
  environment_config = {
    dev = {
      deletion_protection = false
      skip_final_snapshot = true
      backup_retention_period = 0
      backup_window = null
      maintenance_window = null
    }
    staging = {
      deletion_protection = false
      skip_final_snapshot = true
      backup_retention_period = 7
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
    }
    prod = {
      deletion_protection = true
      skip_final_snapshot = false
      backup_retention_period = 30
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
    }
  }
  
  db_config = local.environment_config[var.environment]
}

# RDS Instance
resource "aws_db_instance" "main" {
  # Basic configuration
  identifier = "${var.name_prefix}-db"
  
  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type         = "gp2"
  storage_encrypted    = true
  
  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = local.db_password
  port     = 3306
  
  # Network configuration
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  
  # High Availability
  multi_az               = var.enable_multi_az
  availability_zone      = var.enable_multi_az ? null : var.availability_zones[0]
  
  # Backup configuration
  backup_retention_period = var.enable_backups ? local.db_config.backup_retention_period : 0
  backup_window          = var.enable_backups ? local.db_config.backup_window : null
  maintenance_window     = local.db_config.maintenance_window
  
  # Snapshot configuration
  skip_final_snapshot       = local.db_config.skip_final_snapshot
  final_snapshot_identifier = local.db_config.skip_final_snapshot ? null : "${var.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = local.db_config.deletion_protection
  
  # Performance and monitoring
  performance_insights_enabled = var.environment == "prod"
  monitoring_interval         = var.environment == "prod" ? 60 : 0
  monitoring_role_arn        = var.environment == "prod" ? aws_iam_role.rds_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports = ["error", "general", "slow_query"]
  
  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = aws_db_option_group.main.name
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds"
    Type = "rds-instance"
  })
  
  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${var.name_prefix}-db-params"
  
  # Performance optimizations
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }
  
  parameter {
    name  = "max_connections"
    value = var.environment == "prod" ? "200" : "100"
  }
  
  # Logging configuration
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  
  parameter {
    name  = "long_query_time"
    value = "2"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-params"
    Type = "db-parameter-group"
  })
}

# RDS Option Group
resource "aws_db_option_group" "main" {
  name                 = "${var.name_prefix}-db-options"
  option_group_description = "Option group for ${var.name_prefix}"
  engine_name          = "mysql"
  major_engine_version = "8.0"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-options"
    Type = "db-option-group"
  })
}

# IAM Role for RDS Enhanced Monitoring (production only)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  
  name_prefix = "${var.name_prefix}-rds-monitoring-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-monitoring-role"
    Type = "iam-role"
  })
}

# Attach AWS managed policy for RDS monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ElastiCache Redis Cluster (only if cache is enabled)
resource "aws_elasticache_replication_group" "main" {
  count = var.enable_cache ? 1 : 0
  
  replication_group_id         = "${var.name_prefix}-redis"
  description                  = "Redis cluster for ${var.environment} environment"
  
  # Node configuration
  node_type                    = var.cache_node_type
  port                        = 6379
  parameter_group_name        = aws_elasticache_parameter_group.redis[0].name
  
  # Cluster configuration
  num_cache_clusters          = var.cache_num_cache_nodes
  
  # Network configuration
  subnet_group_name           = var.cache_subnet_group_name
  security_group_ids          = [var.cache_security_group_id]
  
  # Engine configuration
  engine_version              = "7.0"
  
  # Security
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token                  = var.environment == "prod" ? random_password.redis_auth[0].result : null
  
  # Backup configuration (production only)
  snapshot_retention_limit    = var.environment == "prod" ? 5 : 0
  snapshot_window            = var.environment == "prod" ? "03:00-05:00" : null
  
  # Maintenance
  maintenance_window         = "sun:05:00-sun:07:00"
  
  # Availability
  multi_az_enabled           = var.environment == "prod"
  automatic_failover_enabled = var.environment == "prod"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
    Type = "elasticache-replication-group"
  })
  
  lifecycle {
    ignore_changes = [auth_token]
  }
}

# ElastiCache Parameter Group for Redis
resource "aws_elasticache_parameter_group" "redis" {
  count = var.enable_cache ? 1 : 0
  
  family = "redis7"
  name   = "${var.name_prefix}-redis-params"
  
  # Memory optimization
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-params"
    Type = "elasticache-parameter-group"
  })
}

# Random auth token for Redis (production only)
resource "random_password" "redis_auth" {
  count   = var.enable_cache && var.environment == "prod" ? 1 : 0
  length  = 32
  special = false
}

# Store RDS password in AWS Secrets Manager (production only)
resource "aws_secretsmanager_secret" "db_password" {
  count = var.environment == "prod" ? 1 : 0
  
  name        = "${var.name_prefix}-db-password"
  description = "RDS password for ${var.name_prefix}"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-password"
    Type = "secrets-manager-secret"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count = var.environment == "prod" ? 1 : 0
  
  secret_id     = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = local.db_password
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# Store Redis auth token in AWS Secrets Manager (production only)
resource "aws_secretsmanager_secret" "redis_auth" {
  count = var.enable_cache && var.environment == "prod" ? 1 : 0
  
  name        = "${var.name_prefix}-redis-auth"
  description = "Redis auth token for ${var.name_prefix}"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-auth"
    Type = "secrets-manager-secret"
  })
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  count = var.enable_cache && var.environment == "prod" ? 1 : 0
  
  secret_id     = aws_secretsmanager_secret.redis_auth[0].id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth[0].result
    endpoint   = aws_elasticache_replication_group.main[0].primary_endpoint_address
    port       = aws_elasticache_replication_group.main[0].port
  })
}