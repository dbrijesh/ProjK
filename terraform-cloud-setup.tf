# terraform-cloud-setup.tf
# This file helps set up Terraform Cloud workspace configuration

#terraform {
#  cloud {
#    organization = "your-org-name"
#    
#    workspaces {
#      name = "aws-infrastructure"
#    }
#  }
#}

# Terraform Cloud workspace configuration
# You can also configure this through the Terraform Cloud UI

# Required workspace variables (set these in Terraform Cloud UI):
# 
# Environment Variables:
# - AWS_ACCESS_KEY_ID (sensitive)
# - AWS_SECRET_ACCESS_KEY (sensitive)
# - AWS_DEFAULT_REGION
# 
# Terraform Variables:
# - aws_region
# - environment
# - project_name
# - enable_alb
# - enable_ecs
# - enable_rds
# - enable_rds_proxy
# - enable_lambda
# - enable_s3
# - rds_password (sensitive)

# Workspace settings recommendations:
# - Execution Mode: Remote
# - Terraform Version: ~> 1.6.0
# - Auto Apply: false (for safety)
# - Speculative Plans: true

# Cost Estimation: Enable in workspace settings
# Policy Sets: Configure as needed for governance
