data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_sns_topic" "fail_topic" {
  name = "fail-topic"
}

resource "aws_iam_policy" "lambda_policy" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = [aws_sns_topic.fail_topic.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
data "archive_file" "success_lambda" {
  type        = "zip"
  source_file = "success.js"
  output_path = "success_payload.zip"
}

resource "aws_lambda_function" "success_lambda" {
  filename      = "success_payload.zip"
  function_name = "success_function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "success.handler"

  source_code_hash = data.archive_file.success_lambda.output_base64sha256

  runtime = "nodejs18.x"
}

data "archive_file" "fail_lambda" {
  type        = "zip"
  source_file = "fail.js"
  output_path = "fail_payload.zip"
}

resource "aws_lambda_function" "fail_lambda" {
  filename      = "fail_payload.zip"
  function_name = "fail_function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "fail.handler"

  source_code_hash = data.archive_file.success_lambda.output_base64sha256

  runtime = "nodejs18.x"
}


resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.fail_lambda.function_name}"
  retention_in_days = 14
}
