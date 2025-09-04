# Compute Module Outputs
# Export compute resources for use by other modules

# EC2 Instance outputs (single instance mode)
output "instance_ids" {
  description = "IDs of EC2 instances (single instance mode)"
  value       = var.enable_auto_scaling ? [] : aws_instance.single[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = var.enable_auto_scaling ? [] : aws_instance.single[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = var.enable_auto_scaling ? [] : aws_instance.single[*].private_ip
}

# Auto Scaling Group outputs
output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.main[0].name : null
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.main[0].arn : null
}

output "auto_scaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.main[0].id : null
}

# Launch Template outputs
output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.main.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

# Load Balancer outputs
output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].id : null
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].arn : null
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix of the load balancer (for CloudWatch metrics)"
  value       = var.enable_load_balancer ? aws_lb.main[0].arn_suffix : null
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].dns_name : null
}

output "load_balancer_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].zone_id : null
}

# Target Group outputs
output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.main[0].arn : null
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for CloudWatch metrics)"
  value       = var.enable_load_balancer ? aws_lb_target_group.main[0].arn_suffix : null
}

output "target_group_name" {
  description = "Name of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.main[0].name : null
}

# Auto Scaling Policy outputs
output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = var.enable_auto_scaling ? aws_autoscaling_policy.scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"  
  value       = var.enable_auto_scaling ? aws_autoscaling_policy.scale_down[0].arn : null
}

# IAM outputs
output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# Configuration summary
output "configuration_summary" {
  description = "Summary of the compute configuration"
  value = {
    auto_scaling_enabled = var.enable_auto_scaling
    load_balancer_enabled = var.enable_load_balancer
    instance_type = var.instance_type
    min_instances = var.enable_auto_scaling ? var.min_size : 1
    max_instances = var.enable_auto_scaling ? var.max_size : 1
    desired_instances = var.enable_auto_scaling ? var.desired_capacity : 1
    ssl_enabled = var.ssl_certificate_arn != null
  }
}