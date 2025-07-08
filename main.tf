# main.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  cloud {
    organization = "brijeshorg"
    workspaces {
      name = "brijeshworkspace"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      CreatedBy     = "GitHub-Actions"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC and Networking
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  count = var.create_vpc ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = var.create_vpc ? 2 : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  count = var.create_vpc ? 2 : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "private"
  }
}

resource "aws_route_table" "public" {
  count = var.create_vpc ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = var.create_vpc ? 2 : 0
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Security Groups
resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0
  
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  count = var.enable_ecs ? 1 : 0
  
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.enable_alb ? [aws_security_group.alb[0].id] : []
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  count = var.enable_rds ? 1 : 0
  
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.enable_ecs ? [aws_security_group.ecs[0].id] : []
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  count = var.enable_alb ? 1 : 0
  
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.create_vpc ? aws_subnet.public[*].id : var.existing_public_subnet_ids
  
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "main" {
  count = var.enable_alb ? 1 : 0
  
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}

resource "aws_lb_listener" "main" {
  count = var.enable_alb ? 1 : 0
  
  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  count = var.enable_ecs ? 1 : 0
  
  name = "${var.project_name}-cluster"
  
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs[0].name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  count = var.enable_ecs ? 1 : 0
  
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  count = var.enable_ecs ? 1 : 0
  
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn
  
  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-container"
      image = var.ecs_image
      
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs[0].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "main" {
  count = var.enable_ecs ? 1 : 0
  
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main[0].id
  task_definition = aws_ecs_task_definition.main[0].arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.create_vpc ? aws_subnet.private[*].id : var.existing_private_subnet_ids
    security_groups  = [aws_security_group.ecs[0].id]
    assign_public_ip = false
  }
  
  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.main[0].arn
      container_name   = "${var.project_name}-container"
      container_port   = 80
    }
  }
  
  depends_on = [aws_lb_listener.main]
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.enable_rds ? 1 : 0
  
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.create_vpc ? aws_subnet.private[*].id : var.existing_private_subnet_ids
}

# RDS Instance
resource "aws_db_instance" "main" {
  count = var.enable_rds ? 1 : 0
  
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class
  
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = var.rds_db_name
  username = var.rds_username
  password = var.rds_password
  
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
}

# RDS Proxy
resource "aws_db_proxy" "main" {
  count = var.enable_rds_proxy ? 1 : 0
  
  name                   = "${var.project_name}-db-proxy"
  engine_family          = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.rds_proxy[0].arn
  }
  
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_subnet_ids         = var.create_vpc ? aws_subnet.private[*].id : var.existing_private_subnet_ids

}

resource "aws_db_proxy_default_target_group" "main" {
  count = var.enable_rds_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.main[0].name

  connection_pool_config {
    connection_borrow_timeout = 120
    max_connections_percent = 100
    max_idle_connections_percent = 50
    session_pinning_filters = ["EXCLUDE_VARIABLE_SETS"]
  }
  
}

resource "aws_db_proxy_target" "main" {
  count = var.enable_rds_proxy ? 1 : 0
  
  db_instance_identifier = aws_db_instance.main[0].id
  db_proxy_name          = aws_db_proxy.main[0].name
  target_group_name      = aws_db_proxy_default_target_group.main[0].name
}

# RDS Proxy IAM Role
resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  
  name = "${var.project_name}-rds-proxy-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  
  name = "${var.project_name}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds_proxy[0].arn
      }
    ]
  })
}


# RDS Proxy Secret
resource "aws_secretsmanager_secret" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  
  name = "${var.project_name}-rds-proxy-secret"
}

resource "aws_secretsmanager_secret_version" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.rds_proxy[0].id
  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
  })
}

# Lambda Function
resource "aws_lambda_function" "main" {
  count = var.enable_lambda ? 1 : 0
  
  filename         = var.lambda_zip_file
  function_name    = "${var.project_name}-function"
  role            = aws_iam_role.lambda[0].arn
  handler         = var.lambda_handler
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  vpc_config {
    subnet_ids         = var.create_vpc ? aws_subnet.private[*].id : var.existing_private_subnet_ids
    security_group_ids = [aws_security_group.lambda[0].id]
  }
}

resource "aws_security_group" "lambda" {
  count = var.enable_lambda ? 1 : 0
  
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  count = var.enable_s3 ? 1 : 0
  
  bucket = "${var.project_name}-${random_string.bucket_suffix[0].result}"
}

resource "random_string" "bucket_suffix" {
  count = var.enable_s3 ? 1 : 0
  
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "main" {
  count = var.enable_s3 ? 1 : 0
  
  bucket = aws_s3_bucket.main[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_s3 ? 1 : 0
  
  bucket = aws_s3_bucket.main[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
