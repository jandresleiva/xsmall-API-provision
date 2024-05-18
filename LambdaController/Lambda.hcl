resource "aws_lambda_function" "stop_aurora" {
  function_name = "stop_aurora_cluster"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda_stop.zip"  # Zip file containing the stop Lambda function
  source_code_hash = filebase64sha256("lambda_stop.zip")

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  environment {
    variables = {
      CLUSTER_ID = "your-cluster-id"  # Replace with your Aurora cluster ID
    }
  }
}

resource "aws_lambda_function" "start_aurora" {
  function_name = "start_aurora_cluster"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda_start.zip"  # Zip file containing the start Lambda function
  source_code_hash = filebase64sha256("lambda_start.zip")

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  environment {
    variables = {
      CLUSTER_ID = "your-cluster-id"  # Replace with your Aurora cluster ID
    }
  }
}
