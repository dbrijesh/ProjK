# outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = var.create_vpc ? aws_subnet.public[*].id : var.existing_public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = var.create_vpc ? aws_subnet.private[*].id : var.existing_private_subnet_ids
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = var.enable_alb ? aws_lb.main[0].dns_name : null
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = var.enable_alb ? aws_lb.main[0].zone_id : null
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = var.enable_ecs ? aws_ecs_cluster.main[0].name : null
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = var.enable_ecs ? aws_ecs_service.main[0].name : null
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = var.enable_rds ? aws_db_instance.main[0].endpoint : null
  sensitive   = true
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = var.enable_rds_proxy ? aws_db_proxy.main[0].endpoint : null
  sensitive   = true
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = var.enable_lambda ? aws_lambda_function.main[0].function_name : null
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = var.enable_lambda ? aws_lambda_function.main[0].arn : null
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = var.enable_s3 ? aws_s3_bucket.main[0].bucket : null
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = var.enable_s3 ? aws_s3_bucket.main[0].arn : null
}

output "enabled_services" {
  description = "List of enabled services"
  value = {
    alb       = var.enable_alb
    ecs       = var.enable_ecs
    rds       = var.enable_rds
    rds_proxy = var.enable_rds_proxy
    lambda    = var.enable_lambda
    s3        = var.enable_s3
  }
}