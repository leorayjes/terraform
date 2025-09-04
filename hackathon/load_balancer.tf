resource "aws_lb" "main" {
  name               = "hackathon-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "hackathon-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-target-group"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_acm_certificate" "main" {
  domain_name       = "hackathon.example.com"
  validation_method = "DNS"

  tags = {
    Name = "hackathon-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "network" {
  name               = "hackathon-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "hackathon-nlb"
  }
}

resource "aws_lb_target_group" "tcp" {
  name     = "tcp-tg"
  port     = 3306
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "tcp-target-group"
  }
}

resource "aws_lb_listener" "database" {
  load_balancer_arn = aws_lb.network.arn
  port              = "3306"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp.arn
  }
}