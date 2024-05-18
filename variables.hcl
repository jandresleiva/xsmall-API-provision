variable "aws_region" {
  default = "us-west-2"  # Change to your desired region
}

variable "vpc_id" {
  description = "The ID of the VPC where the resources will be deployed"
}

variable "subnet_ids" {
  description = "The IDs of the subnets where the Lambda functions will be deployed"
  type        = list(string)
}

provider "aws" {
  region = var.aws_region
}
