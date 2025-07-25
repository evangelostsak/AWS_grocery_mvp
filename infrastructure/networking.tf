resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app_name}-${var.environment_name}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public-b" }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = true
  tags = { Name = "public-c" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "eu-central-1b"
  tags = { Name = "private-b" }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.103.0/24"
  availability_zone = "eu-central-1c"
  tags = { Name = "private-c" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "ec2_sg" {
  name = "${var.app_name}-${var.environment_name}-instance-security-group"
  vpc_id = aws_vpc.main.id
}

# Allow ALB to send traffic to Flask on EC2 (Port 5000)
resource "aws_security_group_rule" "allow_flask_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg.id

  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  source_security_group_id = aws_security_group.alb.id  # Only allow ALB traffic
}

# Allow SSH from your IP (Replace with your actual IP)
resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg.id

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.allowed_ssh_ip]
}

# Allow EC2 to communicate with RDS on Port 5432
resource "aws_security_group_rule" "allow_rds_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg.id

  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  source_security_group_id = aws_security_group.rds_sg.id
}

# Allow all outbound traffic from EC2
resource "aws_security_group_rule" "allow_ec2_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "alb" {
  name   = "${var.app_name}-${var.environment_name}-alb-security-group"
  vpc_id = aws_vpc.main.id
}

# Allow public access to ALB on Port 80
resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Allow ALB to send traffic to EC2 on Port 5000
resource "aws_security_group_rule" "allow_alb_flask_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.app_name}-${var.environment_name}-rds-security-group"
  vpc_id = aws_vpc.main.id
}

# Allow EC2 to access PostgreSQL on RDS
resource "aws_security_group_rule" "allow_rds_from_ec2" {
  type              = "ingress"
  security_group_id = aws_security_group.rds_sg.id

  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
}

# Allow RDS to communicate out
resource "aws_security_group_rule" "allow_rds_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.rds_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
  name               = "${var.app_name}-${var.environment_name}-web-app-lb"
  load_balancer_type = "application"
  subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

resource "aws_lb_target_group" "instances" {
  name     = "${var.app_name}-${var.environment_name}-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}