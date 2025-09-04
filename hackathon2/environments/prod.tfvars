# Production Environment Configuration
# Full production setup with monitoring, backup, and auto-scaling

# Core environment settings
environment = "prod"
aws_region  = "us-west-2"
project_name = "hackathon2"

# Compute configuration - optimized for performance and availability
instance_type     = "t3.medium"
min_size         = 3
max_size         = 10
desired_capacity = 3

# Feature toggles - all production features enabled
enable_monitoring      = true   # Full CloudWatch monitoring
enable_backups        = true   # Automated RDS backups
enable_multi_az       = true   # High availability
enable_load_balancer  = true   # Application Load Balancer
enable_database       = true   # Production database
enable_cache          = true   # Redis caching layer
enable_auto_scaling   = true   # Auto scaling for demand

# Networking - 3 AZs for high availability
vpc_cidr = "10.0.0.0/16"
# availability_zones will be automatically set to use 3 AZs

# Database configuration - production-ready
db_instance_class     = "db.t3.small"  # Larger instance for production
db_allocated_storage  = 100            # More storage for production
db_name              = "hackathon_prod"
db_username          = "admin"
# Note: In real production, use AWS Secrets Manager for passwords
db_password          = "prodpassword123!"

# Cache configuration - production Redis cluster
cache_node_type       = "cache.t3.small"  # Larger cache instance
cache_num_cache_nodes = 2                 # Multiple nodes for availability

# S3 configuration - full lifecycle management
enable_s3_versioning = true
s3_lifecycle_enabled = true

# SSL/TLS - should be configured with actual certificate ARN
# ssl_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
ssl_certificate_arn = null  # Replace with actual certificate ARN