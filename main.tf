locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_instance" "webserver" {
  ami           = "ami-0bbc328167dee8f3c"
  instance_type = var.instance_type
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-webserver"
    }
  )
  vpc_security_group_ids = [
    aws_security_group.web.id
  ]
}

resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}