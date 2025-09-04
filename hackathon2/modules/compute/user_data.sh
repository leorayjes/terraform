#!/bin/bash
# User Data Script for EC2 instances
# This script runs when an EC2 instance first starts

# Update system packages
yum update -y

# Install necessary packages
yum install -y httpd
yum install -y awscli
yum install -y amazon-cloudwatch-agent

# Start and enable Apache web server
systemctl start httpd
systemctl enable httpd

# Create a simple health check endpoint
cat <<EOF > /var/www/html/health
OK
EOF

# Create a simple index page with environment information
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Hackathon2 Application - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .badge { background: #007acc; color: white; padding: 5px 10px; border-radius: 4px; display: inline-block; }
        .status { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">Hackathon2 Multi-Environment Application</h1>
        
        <div class="info">
            <h2>Environment Information</h2>
            <p><strong>Environment:</strong> <span class="badge">${environment}</span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="availability-zone">Loading...</span></p>
            <p><strong>Instance Type:</strong> <span id="instance-type">Loading...</span></p>
            <p><strong>Status:</strong> <span class="status">Running</span></p>
        </div>
        
        <div class="info">
            <h2>Application Features</h2>
            <ul>
                <li>Environment-aware deployment</li>
                <li>Auto-scaling capabilities (${environment} environment)</li>
                <li>Load balancer integration</li>
                <li>CloudWatch monitoring</li>
                <li>S3 storage integration</li>
            </ul>
        </div>
        
        <div class="info">
            <h2>Infrastructure Details</h2>
            <p>This application demonstrates Terraform's ability to deploy different infrastructure configurations based on environment variables:</p>
            <ul>
                <li><strong>Development:</strong> Single EC2 instance, minimal features</li>
                <li><strong>Staging:</strong> Load balanced setup with database</li>
                <li><strong>Production:</strong> Full auto-scaling with monitoring and backups</li>
            </ul>
        </div>
        
        <div class="info">
            <small>Deployed via Terraform using workspaces and conditional logic</small>
        </div>
    </div>

    <script>
        // Fetch EC2 metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(error => document.getElementById('instance-id').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('availability-zone').textContent = data)
            .catch(error => document.getElementById('availability-zone').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/instance-type')
            .then(response => response.text())
            .then(data => document.getElementById('instance-type').textContent = data)
            .catch(error => document.getElementById('instance-type').textContent = 'N/A');
    </script>
</body>
</html>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 644 /var/www/html

# Configure CloudWatch agent (basic configuration)
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "metrics": {
        "namespace": "Hackathon2/${environment}",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 300
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 300,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 300
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/hackathon2/${environment}/apache/access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/hackathon2/${environment}/apache/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create a simple API endpoint for testing
mkdir -p /var/www/html/api
cat <<EOF > /var/www/html/api/info
{
    "environment": "${environment}",
    "application": "${name_prefix}",
    "status": "healthy",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "features": {
        "auto_scaling": "varies by environment",
        "load_balancer": "varies by environment", 
        "database": "varies by environment",
        "monitoring": "varies by environment"
    }
}
EOF

# Log the completion
echo "$(date): User data script completed successfully for ${environment} environment" >> /var/log/user-data.log

# Signal that the instance is ready (for Auto Scaling Group health checks)
systemctl restart httpd