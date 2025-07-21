output "alb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}

output "db_instance_addr" {
  value = aws_db_instance.db_instance.address
}