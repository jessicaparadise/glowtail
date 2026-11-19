# This file is used to build the patient lambda function. It uses the archive_file data source to create a zip file from the handler.py file. 
# The zip file is then used in the aws_lambda_function resource to create the lambda function.
data "archive_file" "patient" {
  type        = "zip"
  source_file = "${path.module}/../lambdas/patient/handler.py"
  output_path = "${path.module}/build/patient.zip"
}

# Who can wear the patient's badge: only the Lambda service
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# The patient's role
resource "aws_iam_role" "patient" {
  name               = "glowtail-patient"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# Let it write logs (and nothing else)
resource "aws_iam_role_policy_attachment" "patient_logs" {
  role       = aws_iam_role.patient.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Where its logs go, kept 7 days so it stays cheap
resource "aws_cloudwatch_log_group" "patient" {
  name              = "/aws/lambda/glowtail-patient"
  retention_in_days = 7
}

# The patient itself
resource "aws_lambda_function" "patient" {
  function_name    = "glowtail-patient"
  role             = aws_iam_role.patient.arn
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.patient.output_path
  source_code_hash = data.archive_file.patient.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.patient]
}