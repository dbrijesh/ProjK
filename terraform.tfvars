# terraform.tfvars.example
# Copy this file to terraform.tfvars and modify as needed

# Basic Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "myapp"

# Network Configuration
create_vpc = true
vpc_cidr   = "10.0.0.0/16"

# Service Selection - Enable/Disable AWS Services
enable_alb       = true
enable_ecs       = true
enable_rds       = true
enable_rds_proxy = false  # Set to true if you want RDS Proxy
enable_lambda    = true
enable_s3        = true

# ECS Configuration
ecs_cpu           = "256"
ecs_memory        = "512"
ecs_image         = "nginx:latest"
ecs_desired_count = 1

# RDS Configuration
rds_engine_version      = "15.4"
rds_instance_class      = "db.t3.micro"
rds_allocated_storage   = 20
rds_max_allocated_storage = 100
rds_db_name             = "myapp"
rds_username            = "dbuser"
rds_password            = "change-this-password"  # Use a strong password

# Lambda Configuration
lambda_zip_file    = "lambda.zip"
lambda_handler     = "index.handler"
lambda_runtime     = "python3.9"
lambda_timeout     = 30
lambda_memory_size = 128