# Monitoring Module - CloudWatch dashboards, alarms, and log groups
# Creates comprehensive monitoring for all infrastructure components

# CloudWatch Log Groups for centralized logging
resource "aws_cloudwatch_log_group" "application" {
  name              = "/hackathon2/${var.environment}/application"
  retention_in_days = var.environment == "prod" ? 30 : 7
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-logs"
    Type = "cloudwatch-log-group"
    Purpose = "Application logs"
  })
}

resource "aws_cloudwatch_log_group" "apache_access" {
  name              = "/hackathon2/${var.environment}/apache/access"
  retention_in_days = var.environment == "prod" ? 30 : 7
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-apache-access-logs"
    Type = "cloudwatch-log-group"
    Purpose = "Apache access logs"
  })
}

resource "aws_cloudwatch_log_group" "apache_error" {
  name              = "/hackathon2/${var.environment}/apache/error"
  retention_in_days = var.environment == "prod" ? 30 : 7
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-apache-error-logs"
    Type = "cloudwatch-log-group"
    Purpose = "Apache error logs"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = concat(
      # EC2/Auto Scaling widgets
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          
          properties = {
            metrics = var.enable_auto_scaling ? [
              ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.auto_scaling_group_name],
              [".", "GroupInServiceInstances", ".", "."],
              [".", "GroupMaxSize", ".", "."],
              [".", "GroupMinSize", ".", "."]
            ] : [
              ["AWS/EC2", "CPUUtilization", "InstanceId", "i-example"]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = var.enable_auto_scaling ? "Auto Scaling Group Metrics" : "EC2 Instance Metrics"
            period  = 300
          }
        }
      ],
      
      # Load Balancer widgets (conditional)
      var.enable_load_balancer ? [
        {
          type   = "metric"
          x      = 0
          y      = 6
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.load_balancer_arn_suffix],
              [".", "TargetResponseTime", ".", "."],
              [".", "HTTPCode_Target_2XX_Count", ".", "."],
              [".", "HTTPCode_Target_4XX_Count", ".", "."],
              [".", "HTTPCode_Target_5XX_Count", ".", "."]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "Load Balancer Metrics"
            period  = 300
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 12
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.load_balancer_arn_suffix],
              [".", "UnHealthyHostCount", ".", ".", ".", "."]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "Target Health Metrics"
            period  = 300
          }
        }
      ] : [],
      
      # Database widgets (conditional)
      var.enable_database ? [
        {
          type   = "metric"
          x      = 0
          y      = var.enable_load_balancer ? 18 : 6
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
              [".", "DatabaseConnections", ".", "."],
              [".", "FreeableMemory", ".", "."],
              [".", "ReadLatency", ".", "."],
              [".", "WriteLatency", ".", "."]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "RDS Database Metrics"
            period  = 300
          }
        }
      ] : [],
      
      # Cache widgets (conditional)
      var.enable_cache ? [
        {
          type   = "metric"
          x      = 0
          y      = (var.enable_load_balancer ? 18 : 6) + (var.enable_database ? 6 : 0)
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.cache_cluster_id],
              [".", "CacheMisses", ".", "."],
              [".", "CacheHits", ".", "."],
              [".", "NetworkBytesIn", ".", "."],
              [".", "NetworkBytesOut", ".", "."]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "ElastiCache Redis Metrics"
            period  = 300
          }
        }
      ] : []
    )
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dashboard"
    Type = "cloudwatch-dashboard"
  })
}

# Get current AWS region
data "aws_region" "current" {}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_auto_scaling ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.auto_scaling_group_name
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-high-cpu-alarm"
    Type = "cloudwatch-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  count = var.enable_auto_scaling ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.auto_scaling_group_name
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-low-cpu-alarm"
    Type = "cloudwatch-alarm"
  })
}

# Database Alarms (conditional)
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.enable_database ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-cpu-alarm"
    Type = "cloudwatch-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_memory_low" {
  count = var.enable_database ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-rds-low-free-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "10000000" # 10MB in bytes
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-memory-alarm"
    Type = "cloudwatch-alarm"
  })
}

# Load Balancer Alarms (conditional)
resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  count = var.enable_load_balancer ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ALB target response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-response-time-alarm"
    Type = "cloudwatch-alarm"
  })
}

# Cache Alarms (conditional)
resource "aws_cloudwatch_metric_alarm" "cache_cpu_high" {
  count = var.enable_cache ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-cache-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ElastiCache CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    CacheClusterId = var.cache_cluster_id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-cpu-alarm"
    Type = "cloudwatch-alarm"
  })
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-cloudwatch-alerts"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alerts"
    Type = "sns-topic"
  })
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.name_prefix}-error-count"
  log_group_name = aws_cloudwatch_log_group.apache_error.name
  pattern        = "ERROR"
  
  metric_transformation {
    name      = "${var.name_prefix}-error-count"
    namespace = "Hackathon2/${var.environment}"
    value     = "1"
  }
}

# Custom CloudWatch Alarm for Error Count
resource "aws_cloudwatch_metric_alarm" "error_rate_high" {
  alarm_name          = "${var.name_prefix}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${var.name_prefix}-error-count"
  namespace           = "Hackathon2/${var.environment}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors application error rate"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-error-rate-alarm"
    Type = "cloudwatch-alarm"
  })
}