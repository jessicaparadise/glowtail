# The mailbox Glowtail posts incidents to
resource "aws_sns_topic" "alerts" {
  name = "glowtail-alerts"
}

# Forward everything in the mailbox to your email
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}