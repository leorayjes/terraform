# Security Groups for different tiers and services
# Implements defense-in-depth security model

# Web Security Group - for EC2 instances
resource "aws_security_group" "web" {
  name_prefix = "${var.name_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for web servers"

  # HTTP access from load balancer or internet
  ingress {
    description = "HTTP from load balancer or internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.enable_load_balancer ? [] : ["0.0.0.0/0"]
    security_groups = var.enable_load_balancer ? [aws_security_group.alb[0].id] : []
  }

  # HTTPS access from load balancer or internet
  ingress {
    description = "HTTPS from load balancer or internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.enable_load_balancer ? [] : ["0.0.0.0/0"]
    security_groups = var.enable_load_balancer ? [aws_security_group.alb[0].id] : []
  }

  # SSH access (restrict to specific IP ranges in production)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to specific IP ranges
  }

  # Outbound internet access for updates and external API calls
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-sg"
    Type = "security-group"
    Tier = "web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer Security Group (only if load balancer enabled)
resource "aws_security_group" "alb" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = "${var.name_prefix}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  # HTTP access from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to web servers
  egress {
    description = "HTTP to web servers"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "HTTPS to web servers"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
    Type = "security-group"
    Tier = "load-balancer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group (only if database enabled)
resource "aws_security_group" "database" {
  count = var.enable_database ? 1 : 0

  name_prefix = "${var.name_prefix}-db-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RDS database"

  # MySQL/Aurora access from web servers
  ingress {
    description = "MySQL/Aurora from web servers"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # PostgreSQL access from web servers
  ingress {
    description = "PostgreSQL from web servers"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # No outbound rules needed for RDS (managed service)
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
    Type = "security-group"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cache Security Group (only if cache enabled)
resource "aws_security_group" "cache" {
  count = var.enable_cache ? 1 : 0

  name_prefix = "${var.name_prefix}-cache-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ElastiCache Redis"

  # Redis access from web servers
  ingress {
    description = "Redis from web servers"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # No outbound rules needed for ElastiCache (managed service)
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-sg"
    Type = "security-group"
    Tier = "cache"
  })

  lifecycle {
    create_before_destroy = true
  }
}