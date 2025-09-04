# Compute Module - EC2 instances, Auto Scaling, Load Balancer
# Creates environment-appropriate compute infrastructure

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.name_prefix}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-role"
    Type = "iam-role"
  })
}

# IAM Role Policy for EC2 instances (minimal permissions)
resource "aws_iam_role_policy" "ec2_policy" {
  name_prefix = "${var.name_prefix}-ec2-policy-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch metrics and logs
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      # S3 access for application storage
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.name_prefix}-*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.name_prefix}-*"
      }
    ]
  })
}

# Instance Profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.name_prefix}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-profile"
    Type = "iam-instance-profile"
  })
}

# User data script for EC2 instances
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    name_prefix = var.name_prefix
  }))
}

# Launch Template for Auto Scaling Group or single EC2
resource "aws_launch_template" "main" {
  name_prefix   = "${var.name_prefix}-lt-"
  description   = "Launch template for ${var.environment} environment"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.web_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = local.user_data

  # EBS configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type          = "gp3"
      delete_on_termination = true
      encrypted            = true
    }
  }

  # Instance metadata service configuration (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-instance"
      Type = "ec2-instance"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-launch-template"
    Type = "launch-template"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Single EC2 Instance (when auto scaling is disabled)
resource "aws_instance" "single" {
  count = var.enable_auto_scaling ? 0 : 1

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[0]

  vpc_security_group_ids = [var.web_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data             = local.user_data

  root_block_device {
    volume_size           = 20
    volume_type          = "gp3"
    delete_on_termination = true
    encrypted            = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-single-instance"
    Type = "ec2-instance"
  })
}

# Auto Scaling Group (when auto scaling is enabled)
resource "aws_autoscaling_group" "main" {
  count = var.enable_auto_scaling ? 1 : 0

  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : var.public_subnet_ids
  target_group_arns   = var.enable_load_balancer ? [aws_lb_target_group.main[0].arn] : []
  health_check_type   = var.enable_load_balancer ? "ELB" : "EC2"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-asg-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${var.name_prefix}-scale-up"
  scaling_adjustment = 1
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 300
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

resource "aws_autoscaling_policy" "scale_down" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${var.name_prefix}-scale-down"
  scaling_adjustment = -1
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 300
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}