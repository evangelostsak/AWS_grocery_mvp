output "instance_1_ip_addr" {
  value = aws_instance.instance_1.public_ip
}

output "instance_id" {
  value = aws_instance.instance_1.id
}

output "db_instance_addr" {
  value = aws_db_instance.db_instance.address
}