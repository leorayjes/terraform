# Get current AWS region and availability zones
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Use specified AZs or default to first 2 available
locals {
  # Environment-specific configurations
  environment_config = {
    dev = {
      az_count = 1
      enable_nat_gateway = false
    }
    staging = {
      az_count = 2  
      enable_nat_gateway = true
    }
    prod = {
      az_count = 3
      enable_nat_gateway = true
    }
  }
  
  # Get environment-specific settings
  env_config = local.environment_config[var.environment]
  
  # Determine AZs to use
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, local.env_config.az_count)
  
  # Generate resource name prefix
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Determine desired capacity for ASG
  asg_desired_capacity = var.desired_capacity != null ? var.desired_capacity : var.min_size
}

# Networking module - VPC, subnets, security groups
module "networking" {
  source = "./modules/networking"
  
  # Core configuration
  environment    = var.environment
  name_prefix    = local.name_prefix
  vpc_cidr       = var.vpc_cidr
  
  # Availability zones and subnets
  availability_zones  = local.availability_zones
  enable_nat_gateway = local.env_config.enable_nat_gateway
  
  # Feature toggles
  enable_load_balancer = var.enable_load_balancer
  enable_database     = var.enable_database
  enable_cache        = var.enable_cache
  
  tags = {
    Environment = var.environment
    Module      = "networking"
  }
}

# Compute module - EC2, Auto Scaling, Load Balancer
module "compute" {
  source = "./modules/compute"
  
  # Core configuration
  environment   = var.environment
  name_prefix   = local.name_prefix
  instance_type = var.instance_type
  
  # Scaling configuration
  enable_auto_scaling = var.enable_auto_scaling
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = local.asg_desired_capacity
  
  # Load balancer configuration
  enable_load_balancer = var.enable_load_balancer
  ssl_certificate_arn  = var.ssl_certificate_arn
  
  # Networking dependencies
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  web_security_group_id = module.networking.web_security_group_id
  alb_security_group_id = module.networking.alb_security_group_id
  
  tags = {
    Environment = var.environment
    Module      = "compute"
  }
  
  depends_on = [module.networking]
}

# Database module - RDS and ElastiCache
module "database" {
  count  = var.enable_database ? 1 : 0
  source = "./modules/database"
  
  # Core configuration
  environment = var.environment
  name_prefix = local.name_prefix
  
  # Database configuration
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  
  # High availability and backup
  enable_multi_az = var.enable_multi_az
  enable_backups  = var.enable_backups
  
  # Cache configuration
  enable_cache         = var.enable_cache
  cache_node_type      = var.cache_node_type
  cache_num_cache_nodes = var.cache_num_cache_nodes
  
  # Networking dependencies
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  database_security_group_id = module.networking.database_security_group_id
  cache_security_group_id    = module.networking.cache_security_group_id
  
  tags = {
    Environment = var.environment
    Module      = "database"
  }
  
  depends_on = [module.networking]
}

# Monitoring module - CloudWatch alarms and dashboards
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  # Core configuration
  environment = var.environment
  name_prefix = local.name_prefix
  
  # Resources to monitor
  enable_auto_scaling  = var.enable_auto_scaling
  enable_load_balancer = var.enable_load_balancer
  enable_database      = var.enable_database
  enable_cache         = var.enable_cache
  
  # Resource references for monitoring
  auto_scaling_group_name = var.enable_auto_scaling ? module.compute.auto_scaling_group_name : null
  load_balancer_arn_suffix = var.enable_load_balancer ? module.compute.load_balancer_arn_suffix : null
  target_group_arn_suffix = var.enable_load_balancer ? module.compute.target_group_arn_suffix : null
  rds_instance_id = var.enable_database ? module.database[0].rds_instance_id : null
  cache_cluster_id = var.enable_cache && var.enable_database ? module.database[0].cache_cluster_id : null
  
  tags = {
    Environment = var.environment
    Module      = "monitoring"
  }
  
  depends_on = [module.compute, module.database]
}

# S3 bucket for application storage
resource "aws_s3_bucket" "app_storage" {
  bucket = "${local.name_prefix}-app-storage-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "${local.name_prefix}-app-storage"
    Environment = var.environment
    Purpose     = "Application storage"
  }
}

# Random suffix for S3 bucket uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning (conditional)
resource "aws_s3_bucket_versioning" "app_storage" {
  count  = var.enable_s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.app_storage.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket lifecycle configuration (conditional)
resource "aws_s3_bucket_lifecycle_configuration" "app_storage" {
  count  = var.s3_lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.app_storage.id
  
  rule {
    id     = "transition_to_ia"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
  
  # Only apply versioning rules if versioning is enabled
  dynamic "rule" {
    for_each = var.enable_s3_versioning ? [1] : []
    
    content {
      id     = "delete_old_versions"
      status = "Enabled"
      
      noncurrent_version_expiration {
        noncurrent_days = 90
      }
    }
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}