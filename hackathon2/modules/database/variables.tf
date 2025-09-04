# Database Module Variables
# Input variables for the database module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# RDS configuration variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "Allocated storage must be between 20 and 1000 GB."
  }
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "hackathon"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
  sensitive   = true
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "Username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  default     = null
  sensitive   = true
}

# High availability and backup configuration
variable "enable_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "enable_backups" {
  description = "Enable automated backups for RDS"
  type        = bool
  default     = false
}

# Cache configuration variables
variable "enable_cache" {
  description = "Enable ElastiCache Redis cluster"
  type        = bool
  default     = false
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "cache_num_cache_nodes" {
  description = "Number of cache nodes in the cluster"
  type        = number
  default     = 1
  
  validation {
    condition     = var.cache_num_cache_nodes >= 1 && var.cache_num_cache_nodes <= 6
    error_message = "Number of cache nodes must be between 1 and 6."
  }
}

# Networking dependencies
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for database"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "database_security_group_id" {
  description = "ID of the database security group"
  type        = string
}

variable "cache_security_group_id" {
  description = "ID of the cache security group"
  type        = string
  default     = null
}

variable "db_subnet_group_name" {
  description = "Name of the RDS subnet group"
  type        = string
}

variable "cache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}