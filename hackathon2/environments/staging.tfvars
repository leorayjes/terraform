# Staging Environment Configuration  
# Medium complexity for testing and validation

# Core environment settings
environment = "staging"
aws_region  = "us-west-2" 
project_name = "hackathon2"

# Compute configuration - moderate scaling for testing
instance_type     = "t3.small"
min_size         = 2
max_size         = 4
desired_capacity = 2

# Feature toggles - testing production-like features
enable_monitoring      = true   # Enable monitoring for testing
enable_backups        = false  # No backups needed for staging data
enable_multi_az       = false  # Single AZ to save costs
enable_load_balancer  = true   # Test load balancing
enable_database       = true   # Test database connectivity
enable_cache          = false  # No cache in staging to save costs
enable_auto_scaling   = true   # Test auto scaling behavior

# Networking - 2 AZs for load balancer requirement
vpc_cidr = "10.0.0.0/16"
# availability_zones will be automatically set to use 2 AZs

# Database configuration - minimal for staging
db_instance_class     = "db.t3.micro"
db_allocated_storage  = 20
db_name              = "hackathon_staging"
db_username          = "admin" 
db_password          = "stagingpassword123!"

# Cache configuration (not used since enable_cache = false)
cache_node_type       = "cache.t3.micro"
cache_num_cache_nodes = 1

# S3 configuration - test versioning
enable_s3_versioning = true
s3_lifecycle_enabled = false

# SSL/TLS - can be added if certificate is available
ssl_certificate_arn = null