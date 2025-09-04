# Networking Module Outputs
# Export networking resources for use by other modules

# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Internet Gateway output
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Subnet outputs
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

# NAT Gateway outputs
output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Route Table outputs
output "public_route_table_id" {
  description = "ID of public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of database route table"
  value       = var.enable_database ? aws_route_table.database[0].id : null
}

# Subnet Group outputs
output "db_subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = var.enable_database ? aws_db_subnet_group.main[0].name : null
}

output "db_subnet_group_id" {
  description = "ID of the RDS subnet group"
  value       = var.enable_database ? aws_db_subnet_group.main[0].id : null
}

output "cache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = var.enable_cache ? aws_elasticache_subnet_group.main[0].name : null
}

# Security Group outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.enable_load_balancer ? aws_security_group.alb[0].id : null
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.enable_database ? aws_security_group.database[0].id : null
}

output "cache_security_group_id" {
  description = "ID of the cache security group"
  value       = var.enable_cache ? aws_security_group.cache[0].id : null
}

# Availability Zone outputs
output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}

output "availability_zone_count" {
  description = "Number of availability zones used"
  value       = length(var.availability_zones)
}