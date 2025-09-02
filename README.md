# Terraform Course Outline

This README provides a week-by-week breakdown of a hands-on Terraform course. Each session includes content, demos, and Q&A, progressing from fundamentals to advanced features.

## Week 1

### Session 1: Terraform Fundamentals
- What is Infrastructure as Code (IaC) and why it matters
- Terraform vs other IaC tools (CloudFormation, Ansible, Pulumi)
- Core concepts: providers, resources, state
- Installing Terraform and basic CLI commands
- Demo: First terraform init, plan, apply with a simple resource
- Q&A (10 minutes)

### Session 2: Basic Configuration & Syntax
- HCL (HashiCorp Configuration Language) syntax
- Writing your first .tf files
- Understanding terraform plan vs apply vs destroy
- Basic resource dependencies
- Demo: Deploy a simple AWS EC2 instance or Azure VM
- Q&A (10 minutes)

## Week 2

### Session 3: Variables & Outputs
- Input variables (string, number, bool, list, map)
- Variable files (.tfvars) and precedence
- Output values and their uses
- Local values for computed expressions
- Demo: Parameterize the previous week's infrastructure
- Q&A (10 minutes)

### Session 4: State Management Basics
- Understanding terraform.tfstate
- State locking and why it matters
- Remote state backends (S3, Azure Storage, etc.)
- terraform import for existing resources
- Demo: Configure remote state backend
- Q&A (10 minutes)

## Week 3

### Session 5: Data Sources & Dependencies
- Data sources vs resources
- Implicit vs explicit dependencies
- depends_on attribute
- Referencing resources and data sources
- Demo: Use data sources to fetch existing VPC/subnet info
- Q&A (10 minutes)

### Session 6: Modules Introduction
- What are modules and why use them
- Module structure and best practices
- Creating your first custom module
- Using modules from Terraform Registry
- Demo: Convert existing config into a reusable module
- Q&A (10 minutes)

## Week 4

### Session 7: Advanced Features
- for_each and count for multiple resources
- Conditional expressions and functions
- Dynamic blocks for complex configurations
- Terraform workspaces for environment management
- Demo: Deploy to multiple environments using workspaces
- Q&A (10 minutes)

### Session 8: Best Practices & Workflows
- Code organization and file structure
- Version control strategies
- CI/CD integration basics
- Security considerations (sensitive values, .gitignore)
- Troubleshooting common issues
- terraform fmt, validate, and tflint
- Demo: Set up a proper project structure with CI/CD pipeline
- Q&A and course wrap-up (15 minutes)

---