# Zip up the responder's code
data "archive_file" "responder" {
  type        = "zip"
  source_file = "${path.module}/../lambdas/responder/handler.py"
  output_path = "${path.module}/build/responder.zip"
}

# The responder's role
resource "aws_iam_role" "responder" {
  name               = "glowtail-responder"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# Let it write logs
resource "aws_iam_role_policy_attachment" "responder_logs" {
  role       = aws_iam_role.responder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Its log group, 7 days
resource "aws_cloudwatch_log_group" "responder" {
  name              = "/aws/lambda/glowtail-responder"
  retention_in_days = 7
}

# The responder itself
resource "aws_lambda_function" "responder" {
  function_name    = "glowtail-responder"
  role             = aws_iam_role.responder.arn
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.responder.output_path
  source_code_hash = data.archive_file.responder.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.responder]
}