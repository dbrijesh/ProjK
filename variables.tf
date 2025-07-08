# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

# Network Configuration
variable "create_vpc" {
  description = "Create new VPC"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "existing_vpc_id" {
  description = "Existing VPC ID (if create_vpc is false)"
  type        = string
  default     = ""
}

variable "existing_public_subnet_ids" {
  description = "Existing public subnet IDs"
  type        = list(string)
  default     = []
}

variable "existing_private_subnet_ids" {
  description = "Existing private subnet IDs"
  type        = list(string)
  default     = []
}

# Service Toggle Variables
variable "enable_alb" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Enable ECS Fargate"
  type        = bool
  default     = false
}

variable "enable_rds" {
  description = "Enable RDS PostgreSQL"
  type        = bool
  default     = false
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy"
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Enable Lambda Function"
  type        = bool
  default     = false
}

variable "enable_s3" {
  description = "Enable S3 Bucket"
  type        = bool
  default     = false
}

# ECS Configuration
variable "ecs_cpu" {
  description = "ECS task CPU"
  type        = string
  default     = "256"
}

variable "ecs_memory" {
  description = "ECS task memory"
  type        = string
  default     = "512"
}

variable "ecs_image" {
  description = "ECS container image"
  type        = string
  default     = "nginx:latest"
}

variable "ecs_desired_count" {
  description = "ECS desired count"
  type        = number
  default     = 1
}

# RDS Configuration
variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage"
  type        = number
  default     = 100
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = "myapp"
}

variable "rds_username" {
  description = "RDS username"
  type        = string
  default     = "dbuser"
}

variable "rds_password" {
  description = "RDS password"
  type        = string
  sensitive   = true
}

# Lambda Configuration
variable "lambda_zip_file" {
  description = "Lambda zip file path"
  type        = string
  default     = "lambda.zip"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_timeout" {
  description = "Lambda timeout"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size"
  type        = number
  default     = 128
}