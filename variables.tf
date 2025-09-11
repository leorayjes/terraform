variable "project_name" {
    description = "The name of the project"
    type        = string
    default     = "terraform-demo"
}

variable "environment" {
    description = "The environment for deployment"
    type        = string  
    validation {
        condition     = contains(["dev", "staging", "prod"], var.environment)
        error_message = "Environment must be one of 'dev', 'staging', or 'prod'."
    }
}

variable "instance_type" {
    description = "The type of instance to use"
    type        = string
    default     = "t2.micro"
}