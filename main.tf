resource "aws_instance" "webserver" {
  ami           = "ami-0bbc328167dee8f3c"
  instance_type = "t2.micro"
  tags = {
    Name = "WebServerInstance"
  }
  vpc_security_group_ids = [
    aws_security_group.web.id
  ]
}

resource "aws_security_group" "web" {
  name_prefix = "web-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}