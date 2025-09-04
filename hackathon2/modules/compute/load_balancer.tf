# Application Load Balancer and related resources
# Only created when var.enable_load_balancer is true

# Application Load Balancer
resource "aws_lb" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
    Type = "application-load-balancer"
  })
}

# Target Group for ALB
resource "aws_lb_target_group" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name     = "${var.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  # Deregistration delay for graceful shutdown
  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tg"
    Type = "target-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachment for single EC2 instance
resource "aws_lb_target_group_attachment" "single" {
  count = var.enable_load_balancer && !var.enable_auto_scaling ? 1 : 0

  target_group_arn = aws_lb_target_group.main[0].arn
  target_id        = aws_instance.single[0].id
  port             = 80
}

# HTTP Listener (redirects to HTTPS if SSL certificate is provided)
resource "aws_lb_listener" "http" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  # If SSL certificate is provided, redirect HTTP to HTTPS
  # Otherwise, forward to target group
  dynamic "default_action" {
    for_each = var.ssl_certificate_arn != null ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.ssl_certificate_arn == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main[0].arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-http-listener"
    Type = "alb-listener"
  })
}

# HTTPS Listener (only if SSL certificate is provided)
resource "aws_lb_listener" "https" {
  count = var.enable_load_balancer && var.ssl_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-https-listener"
    Type = "alb-listener"
  })
}

# CloudWatch Alarms for Load Balancer (basic monitoring)
resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
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
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main[0].arn_suffix
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-response-time-alarm"
    Type = "cloudwatch-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts" {
  count = var.enable_load_balancer ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.enable_auto_scaling ? var.min_size : "1"
  alarm_description   = "This metric monitors ALB healthy host count"
  treat_missing_data  = "breaching"
  alarm_actions       = []

  dimensions = {
    TargetGroup  = aws_lb_target_group.main[0].arn_suffix
    LoadBalancer = aws_lb.main[0].arn_suffix
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-healthy-hosts-alarm"
    Type = "cloudwatch-alarm"
  })
}