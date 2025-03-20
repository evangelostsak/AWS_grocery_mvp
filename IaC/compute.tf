resource "aws_instance" "instance_1" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.ec2_sg.name]
  key_name        = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  monitoring        = true  # CloudWatch detailed monitoring

  user_data = <<-EOF
  #!/bin/bash
  apt update -y
  apt install -y awslogs
  systemctl start awslogsd
  systemctl enable awslogsd
  echo "CloudWatch Agent Installed!"

  echo '[general]' | sudo tee /etc/awslogs/awscli.conf
  echo 'state_file = /var/lib/awslogs/agent-state' | sudo tee -a /etc/awslogs/awscli.conf

  echo '[/var/log/syslog]' | sudo tee -a /etc/awslogs/awslogs.conf
  echo 'file = /var/log/syslog' | sudo tee -a /etc/awslogs/awslogs.conf
  echo 'log_group_name = /aws/ec2/syslog' | sudo tee -a /etc/awslogs/awslogs.conf
  echo 'log_stream_name = {instance_id}' | sudo tee -a /etc/awslogs/awslogs.conf

  sudo systemctl restart awslogsd
EOF
}