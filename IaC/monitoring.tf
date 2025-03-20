resource "aws_cloudwatch_metric_alarm" "high_cpu_usage" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300  # Every 5 minutes
  statistic         = "Average"
  threshold         = 80.0  # Alert if CPU > 80%
  alarm_description = "EC2 instance CPU usage is too high!"
  actions_enabled    = true
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.instance_1.id
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space" {
  alarm_name          = "low-disk-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DiskSpaceAvailable"
  namespace          = "System/Linux"
  period             = 300
  statistic         = "Average"
  threshold         = 20.0  # Alert if disk space < 20%
  alarm_description = "Low disk space on EC2 instance!"
  actions_enabled    = true
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.instance_1.id
    Filesystem = "/dev/xvda1"
    MountPath  = "/"
  }
}

resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "email"
  endpoint  = "wokiv32671@erapk.com"  # Replace with your email, temp email used here
}