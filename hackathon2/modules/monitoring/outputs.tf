# Monitoring Module Outputs
# Export monitoring resources for use by other modules

# CloudWatch Dashboard outputs
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = "arn:aws:cloudwatch::${data.aws_caller_identity.current.account_id}:dashboard/${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# CloudWatch Log Group outputs
output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value = {
    application   = aws_cloudwatch_log_group.application.name
    apache_access = aws_cloudwatch_log_group.apache_access.name
    apache_error  = aws_cloudwatch_log_group.apache_error.name
  }
}

output "log_group_arns" {
  description = "ARNs of the CloudWatch log groups"
  value = {
    application   = aws_cloudwatch_log_group.application.arn
    apache_access = aws_cloudwatch_log_group.apache_access.arn
    apache_error  = aws_cloudwatch_log_group.apache_error.arn
  }
}

# SNS Topic outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.name
}

# CloudWatch Alarm outputs
output "cloudwatch_alarms" {
  description = "List of CloudWatch alarm names and their status"
  value = merge(
    # Auto Scaling alarms
    var.enable_auto_scaling ? {
      high_cpu_alarm = aws_cloudwatch_metric_alarm.high_cpu[0].alarm_name
      low_cpu_alarm  = aws_cloudwatch_metric_alarm.low_cpu[0].alarm_name
    } : {},
    
    # Database alarms
    var.enable_database ? {
      rds_cpu_alarm    = aws_cloudwatch_metric_alarm.rds_cpu_high[0].alarm_name
      rds_memory_alarm = aws_cloudwatch_metric_alarm.rds_free_memory_low[0].alarm_name
    } : {},
    
    # Load balancer alarms
    var.enable_load_balancer ? {
      alb_response_time_alarm = aws_cloudwatch_metric_alarm.alb_response_time_high[0].alarm_name
    } : {},
    
    # Cache alarms
    var.enable_cache ? {
      cache_cpu_alarm = aws_cloudwatch_metric_alarm.cache_cpu_high[0].alarm_name
    } : {},
    
    # Application alarms
    {
      error_rate_alarm = aws_cloudwatch_metric_alarm.error_rate_high.alarm_name
    }
  )
}

# Metric Filter outputs
output "log_metric_filters" {
  description = "List of CloudWatch log metric filters"
  value = {
    error_count = {
      name           = aws_cloudwatch_log_metric_filter.error_count.name
      log_group_name = aws_cloudwatch_log_metric_filter.error_count.log_group_name
      pattern        = aws_cloudwatch_log_metric_filter.error_count.pattern
    }
  }
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Monitoring configuration summary
output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    environment = var.environment
    dashboard_enabled = true
    log_groups_count = 3
    alarms_enabled = {
      auto_scaling    = var.enable_auto_scaling ? 2 : 0
      load_balancer   = var.enable_load_balancer ? 1 : 0
      database        = var.enable_database ? 2 : 0
      cache          = var.enable_cache ? 1 : 0
      application    = 1
    }
    total_alarms = (
      (var.enable_auto_scaling ? 2 : 0) +
      (var.enable_load_balancer ? 1 : 0) +
      (var.enable_database ? 2 : 0) +
      (var.enable_cache ? 1 : 0) +
      1 # application alarm
    )
    sns_topic_configured = true
    log_retention_days = var.environment == "prod" ? 30 : 7
  }
}

# URLs for easy access to AWS console resources
output "console_urls" {
  description = "URLs to access monitoring resources in AWS console"
  value = {
    dashboard = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
    alarms    = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#alarmsV2:search=${var.name_prefix}"
    logs      = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logsV2:log-groups/log-group/$252Fhackathon2$252F${var.environment}"
    metrics   = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#metricsV2:graph=~();search=Hackathon2/${var.environment}"
  }
}