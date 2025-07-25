# General Variables

variable "region" {
  description = "Default region for provider"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the web application"
  type        = string
  default     = "web-app"
}

variable "environment_name" {
  description = "Deployment environment (dev/staging/production)"
  type        = string
  default     = "dev"
}

# EC2 Variables

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-099b9a78992042e1f"
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the key pair to use for ec2 instance"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "IP address to allow SSH access"
  type        = string
}

# ASG Variables

variable "asg_min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 3
}

# VPC & Subnet CIDRs

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to deploy into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# S3 Variables

variable "bucket_prefix" {
  description = "prefix of s3 bucket for app data"
  type        = string
}

# RDS Variables

variable "db_name" {
  description = "Name of DB"
  type        = string
}

variable "db_class" {
  description = "DB instance class"
  type        = string
}

variable "db_user" {
  description = "Username for DB"
  type        = string
}

variable "db_pass" {
  description = "Password for DB"
  type        = string
  sensitive   = true
}

variable "read_replica_az" {
  description = "Availability zone for read replica"
  type        = string
}
# Monitoring Variables
variable "alert_email" {
  description = "Email address to receive CloudWatch alerts"
  type        = string
}