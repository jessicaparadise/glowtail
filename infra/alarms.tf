# Trips when the patient throws even one error
resource "aws_cloudwatch_metric_alarm" "patient_errors" {
  alarm_name          = "glowtail-patient-errors"
  alarm_description   = "The patient Lambda threw an error"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.patient.function_name
  }
}