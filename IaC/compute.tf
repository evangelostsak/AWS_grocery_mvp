resource "aws_instance" "instance_1" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.ec2_sg.name]
  key_name        = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}