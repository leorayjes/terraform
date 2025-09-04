# Core infrastructure outputs
output "environment" {
  description = "Current environment name"
  value       = var.environment
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

# Networking outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used"
  value       = local.availability_zones
}

# Compute outputs
output "instance_ids" {
  description = "IDs of EC2 instances (if not using auto scaling)"
  value       = var.enable_auto_scaling ? [] : module.compute.instance_ids
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = var.enable_auto_scaling ? module.compute.auto_scaling_group_name : null
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = var.enable_auto_scaling ? module.compute.auto_scaling_group_arn : null
}

# Load balancer outputs (conditional)
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? module.compute.load_balancer_dns_name : null
}

output "load_balancer_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = var.enable_load_balancer ? module.compute.load_balancer_zone_id : null
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.enable_load_balancer ? module.compute.load_balancer_arn : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.enable_load_balancer ? module.compute.target_group_arn : null
}

# Database outputs (conditional)
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.enable_database ? module.database[0].rds_endpoint : null
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.enable_database ? module.database[0].rds_port : null
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = var.enable_database ? module.database[0].rds_instance_id : null
}

# Cache outputs (conditional)
output "cache_cluster_endpoint" {
  description = "ElastiCache cluster endpoint"
  value       = var.enable_cache && var.enable_database ? module.database[0].cache_cluster_endpoint : null
  sensitive   = true
}

output "cache_cluster_port" {
  description = "ElastiCache cluster port"
  value       = var.enable_cache && var.enable_database ? module.database[0].cache_cluster_port : null
}

# S3 outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.app_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_storage.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.app_storage.bucket_domain_name
}

# Security group outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.networking.web_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.enable_database ? module.networking.database_security_group_id : null
}

# Monitoring outputs (conditional)
output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.enable_monitoring ? module.monitoring[0].cloudwatch_dashboard_url : null
}

# Resource counts for cost analysis
output "resource_summary" {
  description = "Summary of resources created by environment"
  value = {
    environment      = var.environment
    ec2_instances    = var.enable_auto_scaling ? "${var.min_size}-${var.max_size}" : "1"
    instance_type    = var.instance_type
    load_balancer    = var.enable_load_balancer ? "ALB" : "none"
    database        = var.enable_database ? "RDS ${var.db_instance_class}" : "none"
    cache           = var.enable_cache && var.enable_database ? "ElastiCache ${var.cache_node_type}" : "none"
    monitoring      = var.enable_monitoring ? "CloudWatch" : "none"
    multi_az        = var.enable_multi_az ? "yes" : "no"
    backups         = var.enable_backups ? "automated" : "none"
    s3_versioning   = var.enable_s3_versioning ? "enabled" : "disabled"
  }
}

# Application access information
output "application_endpoints" {
  description = "Endpoints to access the application"
  value = {
    # If load balancer is enabled, use its DNS name; otherwise list instance IPs
    web_url = var.enable_load_balancer ? "http://${module.compute.load_balancer_dns_name}" : "Check EC2 console for instance public IPs"
    ssh_access = var.enable_load_balancer ? "Access via load balancer or individual instance IPs" : "SSH to individual instances"
  }
}