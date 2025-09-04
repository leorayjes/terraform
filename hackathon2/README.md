# Multi-Environment Deployment Challenge

A Terraform hackathon challenge focused on building intelligent, environment-aware infrastructure that scales from simple development setups to full production deployments.

## Challenge Overview

Teams must build a single Terraform codebase that dynamically deploys different infrastructure configurations based on environment variables. The infrastructure should automatically adapt its complexity and resources based on the target environment.

## Environment Tiers

### Development Environment
- **Goal**: Minimal, cost-effective setup for developers
- **Infrastructure**: 
  - Single EC2 instance (t3.micro)
  - Basic security group (SSH + HTTP)
  - Simple S3 bucket for storage
  - No load balancer or scaling

### Staging Environment  
- **Goal**: Medium complexity for testing and validation
- **Infrastructure**:
  - 2 EC2 instances (t3.small) with basic load balancing
  - Application Load Balancer
  - RDS database (t3.micro)
  - Enhanced security groups
  - VPC with public/private subnets

### Production Environment
- **Goal**: Full production setup with monitoring, backup, and auto-scaling
- **Infrastructure**:
  - Auto Scaling Group (3-10 instances, t3.medium)
  - Application Load Balancer with SSL termination
  - Multi-AZ RDS with automated backups
  - ElastiCache for caching
  - CloudWatch monitoring and alarms
  - S3 with versioning and lifecycle policies
  - IAM roles with least privilege access
  - VPC with multiple availability zones

## Technical Requirements

### Core Technologies
- **Terraform Workspaces**: Use workspaces to manage environment state
- **Conditional Logic**: Leverage `count`, `for_each`, and conditional expressions
- **Variable Management**: Environment-specific variable files and validation
- **Remote State**: S3 backend with state locking via DynamoDB

### Key Features to Implement
1. **Dynamic Resource Scaling**: Resources should scale based on environment
2. **Conditional Resource Creation**: Some resources only exist in certain environments
3. **Environment-Specific Configurations**: Different instance types, storage, networking
4. **Security Gradation**: Security measures that increase with environment criticality
5. **Cost Optimization**: Development should be minimal cost, production should be optimized for performance

## Project Structure

```
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/
│   ├── compute/
│   ├── networking/
│   ├── database/
│   └── monitoring/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tf
```

## Getting Started

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Create Workspaces**
   ```bash
   terraform workspace new dev
   terraform workspace new staging  
   terraform workspace new prod
   ```

3. **Deploy to Development**
   ```bash
   terraform workspace select dev
   terraform plan -var-file="environments/dev.tfvars"
   terraform apply -var-file="environments/dev.tfvars"
   ```

4. **Deploy to Staging**
   ```bash
   terraform workspace select staging
   terraform plan -var-file="environments/staging.tfvars"
   terraform apply -var-file="environments/staging.tfvars"
   ```

5. **Deploy to Production**
   ```bash
   terraform workspace select prod
   terraform plan -var-file="environments/prod.tfvars"
   terraform apply -var-file="environments/prod.tfvars"
   ```

## Judging Criteria

### Technical Excellence (40%)
- Proper use of Terraform workspaces and conditional logic
- Clean, modular code structure
- Effective use of variables and data sources
- Proper state management

### Environment Differentiation (30%)
- Clear distinction between environment complexities
- Appropriate resource sizing and scaling
- Environment-specific features and configurations

### Security & Best Practices (20%)
- Progressive security implementation
- IAM roles and policies
- Network security and isolation
- Secrets management

### Innovation & Creativity (10%)
- Creative use of Terraform features
- Unique approaches to environment management
- Additional tooling or automation

## Bonus Challenges

1. **CI/CD Integration**: Add GitHub Actions or similar for automated deployments
2. **Cost Monitoring**: Implement cost tracking and budgeting alerts
3. **Disaster Recovery**: Add backup and recovery mechanisms for production
4. **Multi-Region**: Extend production to multiple AWS regions
5. **Container Support**: Add ECS or EKS for containerized applications

## Resources

- [Terraform Workspaces Documentation](https://www.terraform.io/docs/language/state/workspaces.html)
- [Terraform Conditional Expressions](https://www.terraform.io/docs/language/expressions/conditionals.html)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Time Limit

**Duration**: 4-6 hours

## Submission Requirements

1. Complete Terraform code that works across all three environments
2. Documentation explaining your approach and design decisions
3. Demo showing deployment to each environment
4. Cost analysis comparing environments
5. Brief presentation (5 minutes) highlighting key features

## Sample Environment Variables

```hcl
# environments/dev.tfvars
environment = "dev"
instance_type = "t3.micro"
min_size = 1
max_size = 1
enable_monitoring = false
enable_backups = false

# environments/staging.tfvars
environment = "staging"  
instance_type = "t3.small"
min_size = 2
max_size = 4
enable_monitoring = true
enable_backups = false

# environments/prod.tfvars
environment = "prod"
instance_type = "t3.medium"
min_size = 3
max_size = 10
enable_monitoring = true
enable_backups = true
enable_multi_az = true
```

---

**Good luck, and may the best infrastructure win! 🚀**