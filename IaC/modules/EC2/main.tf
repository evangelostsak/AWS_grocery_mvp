resource "aws_instance" "grovery_app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair
  vpc_security_group_ids = [var.security_group_id]
  user_data = <<-EOF
              #!/bin/bash
                cd AWS_grocery
                sudo docker-compose up -d
              EOF
}