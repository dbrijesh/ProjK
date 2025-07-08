# iam.tf
# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution" {
  count = var.enable_ecs ? 1 : 0
  
  name = "${var.project_name}-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  count = var.enable_ecs ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution[0].name
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  count = var.enable_ecs ? 1 : 0
  
  name = "${var.project_name}-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task" {
  count = var.enable_ecs ? 1 : 0
  
  name = "${var.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = var.enable_s3 ? [
          aws_s3_bucket.main[0].arn,
          "${aws_s3_bucket.main[0].arn}/*"
        ] : []
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.enable_lambda ? [aws_lambda_function.main[0].arn] : []
      }
    ]
  })
}

# Lambda Execution Role
resource "aws_iam_role" "lambda" {
  count = var.enable_lambda ? 1 : 0
  
  name = "${var.project_name}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.enable_lambda ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda[0].name
}

resource "aws_iam_role_policy" "lambda" {
  count = var.enable_lambda ? 1 : 0
  
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:Connect"
        ]
        Resource = var.enable_rds ? [aws_db_instance.main[0].arn] : []
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = var.enable_s3 ? [
          aws_s3_bucket.main[0].arn,
          "${aws_s3_bucket.main[0].arn}/*"
        ] : []
      }
    ]
  })
}

# RDS Proxy Role
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