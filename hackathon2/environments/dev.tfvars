# Development Environment Configuration
# Minimal, cost-effective setup for developers

# Core environment settings
environment = "dev"
aws_region  = "us-west-2"
project_name = "hackathon2"

# Compute configuration - minimal for cost optimization
instance_type     = "t3.micro"
min_size         = 1
max_size         = 1
desired_capacity = 1

# Feature toggles - minimal features for dev
enable_monitoring      = false
enable_backups        = false
enable_multi_az       = false
enable_load_balancer  = false  # No load balancer needed for single instance
enable_database       = false  # No database for simple dev setup
enable_cache          = false  # No cache needed
enable_auto_scaling   = false  # Single EC2 instance

# Networking - single AZ to minimize costs
vpc_cidr = "10.0.0.0/16"
# availability_zones will be automatically set to use only 1 AZ

# S3 configuration - basic setup
enable_s3_versioning = false
s3_lifecycle_enabled = false

# SSL/TLS - not needed for dev
ssl_certificate_arn = null

# Note: Database and cache settings are included but not used
# since enable_database = false
db_instance_class     = "db.t3.micro"
db_allocated_storage  = 20
db_name              = "hackathon_dev"
db_username          = "admin"
db_password          = "devpassword123!"

cache_node_type       = "cache.t3.micro"
cache_num_cache_nodes = 1