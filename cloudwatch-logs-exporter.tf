data archive_file log_exporter {
  type        = "zip"
  source_file = "${path.module}/lambda/cloudwatch-to-s3.py"
  output_path = "${path.module}/lambda/tmp/cloudwatch-to-s3.zip"
}

resource random_string random {
  length  = 8
  special = false
  upper   = false
  number  = false
}

resource aws_iam_role log_exporter {
  name               = "log-exporter-${random_string.random.result}"
  assume_role_policy = data.aws_iam_policy_document.log_exporter.json
}

resource aws_iam_role_policy log_exporter {
  name   = "log-exporter-${random_string.random.result}"
  role   = aws_iam_role.log_exporter.id
  policy = data.aws_iam_policy_document.log_exporter_policy.json
}

resource aws_lambda_function log_exporter {
  function_name    = "log-exporter-${random_string.random.result}"
  filename         = data.archive_file.log_exporter.output_path
  role             = aws_iam_role.log_exporter.arn
  handler          = "cloudwatch-to-s3.lambda_handler"
  source_code_hash = data.archive_file.log_exporter.output_base64sha256
  timeout          = 300
  runtime          = "python3.8"

  environment {
    variables = {
      S3_BUCKET = var.cloudwatch_logs_export_bucket
    }
  }
}

resource aws_cloudwatch_event_rule log_exporter {
  name                = "log-exporter-${random_string.random.result}"
  description         = "Fires periodically to export logs to S3"
  schedule_expression = "rate(4 hours)"
}

resource aws_cloudwatch_event_target log_exporter {
  rule      = aws_cloudwatch_event_rule.log_exporter.name
  target_id = "log-exporter-${random_string.random.result}"
  arn       = aws_lambda_function.log_exporter.arn
}

resource aws_lambda_permission log_exporter {
  statement_id  = "AllowExecutionFromCloudWatch"
  function_name = "log-exporter-${random_string.random.result}"
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_cloudwatch_event_rule.log_exporter.arn
}



