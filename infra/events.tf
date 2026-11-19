# The rule: listen for the patient's alarm going into ALARM
resource "aws_cloudwatch_event_rule" "alarm_fired" {
  name        = "glowtail-alarm-fired"
  description = "Wake the responder when a Glowtail alarm goes into ALARM"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    resources     = [aws_cloudwatch_metric_alarm.patient_errors.arn]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

# The target: who to wake up
resource "aws_cloudwatch_event_target" "responder" {
  rule = aws_cloudwatch_event_rule.alarm_fired.name
  arn  = aws_lambda_function.responder.arn
}

# The bouncer: let EventBridge (and only this rule) run the responder
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.responder.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_fired.arn
}