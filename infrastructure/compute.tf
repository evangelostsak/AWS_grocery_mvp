resource "aws_launch_template" "app_template" {
  name_prefix   = "grocery-app-"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = base64encode(<<-EOF
  #!/bin/bash
  apt update -y
  apt install -y awslogs amazon-cloudwatch-agent

  # Create config for CW Agent
  cat <<EOC > /opt/aws/amazon-cloudwatch-agent/bin/config.json
  {
    "metrics": {
      "metrics_collected": {
        "disk": {
          "measurement": [
            "used_percent"
          ],
          "resources": [
            "*"
          ]
        }
      }
    }
  }
  EOC

  # Start CW Agent with config
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
    -s

  systemctl enable amazon-cloudwatch-agent
  systemctl start amazon-cloudwatch-agent

  echo "CloudWatch Agent Started!"

  # Optional legacy awslogs setup if still used
  echo '[general]' | sudo tee /etc/awslogs/awscli.conf
  echo 'state_file = /var/lib/awslogs/agent-state' | sudo tee -a /etc/awslogs/awscli.conf
  echo '[/var/log/syslog]' | sudo tee -a /etc/awslogs/awslogs.conf
  echo 'file = /var/log/syslog' | sudo tee -a /etc/awslogs/awslogs.conf
  echo 'log_group_name = /aws/ec2/syslog' | sudo tee -a /etc/awslogs/awslogs.conf
  echo 'log_stream_name = {instance_id}' | sudo tee -a /etc/awslogs/awslogs.conf
  sudo systemctl restart awslogsd
EOF
)
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "grocery-asg"
  min_size                  = 3
  max_size                  = 3
  desired_capacity          = 3
  vpc_zone_identifier       = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]
  target_group_arns         = [aws_lb_target_group.instances.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "grocery-instance"
    propagate_at_launch = true
  }
}