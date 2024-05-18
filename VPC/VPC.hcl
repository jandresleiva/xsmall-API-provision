data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet_ids" "selected" {
  vpc_id = var.vpc_id
}

data "aws_security_group" "default" {
  vpc_id = var.vpc_id
  filter {
    name   = "group-name"
    values = ["default"]
  }
}
