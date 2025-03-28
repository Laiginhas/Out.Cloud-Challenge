resource "aws_cloudwatch_metric_alarm" "high_memory_usage" {
  alarm_name          = "HighMemoryUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Dispara se a memória ultrapassar 80%"
  dimensions = {
    InstanceId = aws_instance.wordpress.id
  }

  actions_enabled = false
}
