resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/example-app"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  container_definitions    = jsonencode([{
    name      = "example-app"
    image     = "your-dockerhub-username/your-image:latest"  # Replace with your Docker Hub image
    memory    = 512
    cpu       = 256
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    environment = [
      { name  = "DB_HOST", value = "your-db-host" },
      { name  = "DB_USER", value = "your-db-user" },
      { name  = "DB_PASSWORD", value = "your-db-password" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/example-app"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    ClusterName  = aws_ecs_cluster.example.name
    ServiceName  = aws_ecs_service.example.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_sns_topic" "alerts" {
  name = "alerts-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"  # Replace with your email
}

resource "aws_lambda_function" "start_aurora" {
  filename         = "start_aurora.zip"
  function_name    = "startAurora"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "start_aurora.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("start_aurora.zip")
}

resource "aws_lambda_function" "stop_aurora" {
  filename         = "stop_aurora.zip"
  function_name    = "stopAurora"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "stop_aurora.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("stop_aurora.zip")
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_event_rule" "start_aurora_rule" {
  name                = "startAuroraRule"
  schedule_expression = "cron(0 14 * * ? *)"  # Adjust the cron expression as needed
}

resource "aws_cloudwatch_event_rule" "stop_aurora_rule" {
  name                = "stopAuroraRule"
  schedule_expression = "cron(0 19 * * ? *)"  # Adjust the cron expression as needed
}

resource "aws_cloudwatch_event_target" "start_aurora_target" {
  rule      = aws_cloudwatch_event_rule.start_aurora_rule.name
  target_id = "startAuroraFunction"
  arn       = aws_lambda_function.start_aurora.arn
}

resource "aws_cloudwatch_event_target" "stop_aurora_target" {
  rule      = aws_cloudwatch_event_rule.stop_aurora_rule.name
  target_id = "stopAuroraFunction"
  arn       = aws_lambda_function.stop_aurora.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_aurora.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_aurora_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_aurora.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_aurora_rule.arn
}
