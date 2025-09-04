# Monitoring Module Variables
# Input variables for the monitoring module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# Feature toggles to determine what to monitor
variable "enable_auto_scaling" {
  description = "Whether auto scaling is enabled (affects monitoring setup)"
  type        = bool
  default     = false
}

variable "enable_load_balancer" {
  description = "Whether load balancer is enabled (affects monitoring setup)"
  type        = bool
  default     = false
}

variable "enable_database" {
  description = "Whether database is enabled (affects monitoring setup)"
  type        = bool
  default     = false
}

variable "enable_cache" {
  description = "Whether cache is enabled (affects monitoring setup)"
  type        = bool
  default     = false
}

# Resource references for monitoring
variable "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
  default     = null
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the load balancer for CloudWatch metrics"
  type        = string
  default     = null
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group for CloudWatch metrics"
  type        = string
  default     = null
}

variable "rds_instance_id" {
  description = "RDS instance identifier to monitor"
  type        = string
  default     = null
}

variable "cache_cluster_id" {
  description = "ElastiCache cluster ID to monitor"
  type        = string
  default     = null
}

# Notification configuration
variable "alert_email_addresses" {
  description = "List of email addresses to receive CloudWatch alarms"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.alert_email_addresses :
      can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid email format."
  }
}

# Alarm thresholds (customizable per environment)
variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms (percentage)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU alarm threshold must be between 1 and 100."
  }
}

variable "response_time_threshold" {
  description = "Response time threshold for load balancer alarms (seconds)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.response_time_threshold > 0 && var.response_time_threshold <= 30
    error_message = "Response time threshold must be between 0 and 30 seconds."
  }
}

variable "error_rate_threshold" {
  description = "Error rate threshold for application alarms (count per 5 minutes)"
  type        = number
  default     = 10
  
  validation {
    condition     = var.error_rate_threshold >= 1 && var.error_rate_threshold <= 1000
    error_message = "Error rate threshold must be between 1 and 1000."
  }
}

# Log retention configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = null # Will be set based on environment
  
  validation {
    condition = var.log_retention_days == null || contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch log retention periods."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}