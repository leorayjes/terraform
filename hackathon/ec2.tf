resource "aws_instance" "web" {
  count                  = 2
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = false
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Starting web server..."
    export DB_PASSWORD="SuperSecret123!"
    export API_KEY="sk-1234567890abcdef"
    export ADMIN_PASSWORD="admin123"
    
    # Install web server
    yum update -y
    yum install -y httpd mysql-client
    systemctl start httpd
    systemctl enable httpd
    
    # Create default page with sensitive info
    echo "<h1>Web Server</h1>" > /var/www/html/index.html
    echo "<p>Database Password: SuperSecret123!</p>" >> /var/www/html/index.html
    echo "<p>API Key: sk-1234567890abcdef</p>" >> /var/www/html/index.html
  EOF

  monitoring = false

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BrVlvG7s5uXkmiJdSGHdHRn0J4xG9rWMvG9P7YHsRBWvtjL0Q4xG9rWMvG9P7YHsRBWvtjL0Q4xG9rWMvG9P7YHsRBWvtjL0Q4xG9rWMvG9P7YHs deployer@hackathon"
}

resource "aws_instance" "admin" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.admin_profile.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = false
  }

  tags = {
    Name = "admin-server"
    Role = "Administrator"
  }
}