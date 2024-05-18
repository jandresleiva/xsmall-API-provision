# Define the AWS provider
provider "aws" {
  region = var.aws_region
}

# Call the VPC module
module "vpc" {
  source = "./VPC"
  # Add necessary variables and configurations
}

# Call the ECS module
module "ecs" {
  source = "./ECS"
  # Add necessary variables and configurations
}

# Call the Lambda module
module "lambda" {
  source = "./LambdaController"
  # Add necessary variables and configurations
}

# Call the IAM module
module "iam" {
  source = "./IAM"
  # Add necessary variables and configurations
}

# Define output values
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}
