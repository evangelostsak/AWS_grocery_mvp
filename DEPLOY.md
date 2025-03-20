# 🚀 AWS Grocery App Deployment Guide  

This project demonstrates a **cloud-native deployment** of a grocery web application using **AWS infrastructure** and **Terraform**.

## 🌍 AWS Services Used  

| **AWS Service**       | **Purpose** |
|-------------------|---------|
| **EC2**          | Hosts the Flask application |
| **Amazon RDS**   | Migrated the database from local storage to PostgreSQL |
| **Application Load Balancer (ALB)** | Distributes traffic efficiently |
| **S3 Bucket**    | Stores avatars instead of local storage |
| **CloudWatch**   | Enables real-time monitoring and alerts |
| **IAM Roles**    | Securely connects EC2 to S3 & CloudWatch |
| **Security Groups** | Controls network access between services |

## Services worth mentioning  

| **Service**       | **Purpose** |
|-------------------|---------|
| **Docker & docker-compose**          | Containerization of the application into 2 containers (backend, frontend) |

---

## 🖥️ 1️⃣ Deploying EC2 Instance 

Amazon EC2 is used to host the **Grocery app**, making it accessible globally.

### ✅ Key Configurations  
- **AMI:** AWS Linux (`ami-099b9a78992042e1f`) (**custom AMI**) 
- **Instance Type:** `t2.micro` (Free-tier eligible)  
- **IAM Role:** Allows EC2 to access **S3 avatars**  
- **User Data:** Automatically starts the app on launch  
- **Security:** ALB sends requests to Flask (`5000`), SSH is restricted to **my IP**  

### **Terraform Code (EC2)**
```hcl
resource "aws_instance" "app_instance" {
  ami               = var.ami
  instance_type     = var.instance_type
  key_name         = var.key_name
  security_groups   = [aws_security_group.ec2_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  monitoring        = true  # Enables CloudWatch monitoring

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
```

## 🛢️ 2️⃣ Migrating to Amazon RDS
To replace local database storage, I migrated to Amazon RDS (PostgreSQL) for scalability & reliability.

### ✅ Why RDS?

- ✔️ Scalability – Handles large database queries efficiently
- ✔️ Automatic Backups – Managed by AWS
- ✔️ Security – Only EC2 can connect to RDS

## Terraform Code (RDS)
```hcl
resource "aws_db_instance" "db_instance" {
  identifier           = "grocery-db2"
  engine              = "postgres"
  engine_version      = "12.22"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username           = var.db_user
  password           = var.db_pass
  publicly_accessible = false
  skip_final_snapshot = true
}
````
## 🔒 EC2 to RDS Connection (Security Group Rule)
```hcl
resource "aws_security_group_rule" "allow_rds_from_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_sg.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
}
```
## 🔒 3️⃣ Securing the Network with Security Groups
Security groups ensure that only the right AWS services can communicate.
### Security Group Rules
| **Resource** | **Allowed Ports** | **Source** | **Purpose** |
|-------------|------------------|------------|-------------|
| **EC2**     | `5000`            | ALB Security Group | Accepts Flask traffic |
| **EC2**     | `22`              | My Public IP | SSH access |
| **ALB**     | `80`              | `0.0.0.0/0` | Public HTTP traffic |
| **RDS**     | `5432`            | EC2 Security Group | Database access |

## ⚖️ 4️⃣ Application Load Balancer (ALB) for Traffic Distribution  

### ✅ Why ALB?  
✔️ Distributes traffic efficiently  
✔️ Ensures **high availability**  
✔️ Handles **auto-scaling**  

### **Terraform Code (ALB)**
```hcl
resource "aws_lb" "load_balancer" {
  name               = "${var.app_name}-lb"
  load_balancer_type = "application"
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
```
## 📦 5️⃣ Storing Avatars in S3 Instead of Locally  

Instead of storing user avatars on EC2, I moved them to **Amazon S3** for better scalability and availability.

### ✅ Why Use S3?  
✔️ **Faster performance** – No impact on EC2 storage  
✔️ **No need for additional disk space** on the instance  
✔️ **Easier backups and durability** – AWS manages storage reliability  

### **Terraform Code (S3)**
```hcl
resource "aws_s3_bucket" "avatars_bucket" {
  bucket_prefix = "grocery-app-avatars"
  force_destroy = true
}
```

### **Modified App to Use S3**
```python
'.env'

S3_BUCKET_NAME=your-bucket-name
S3_REGION=eu-central-1
USE_S3_STORAGE=true
```

This ensures that avatars are no longer stored on EC2, improving performance and scalability.

 
## 📊 6️⃣ CloudWatch Monitoring & Alerts  
 
To ensure system reliability, I set up **AWS CloudWatch** to monitor key performance metrics and trigger alerts when needed.  
 
### ✅ What We Monitor?  
✔️ **CPU Utilization** – Prevents EC2 overload  
✔️ **Disk Space** – Avoids system failures due to low storage  
✔️ **RDS Performance** – Tracks database connections & latency  
 
### **Terraform Code (CloudWatch Alarms)**  
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu_usage" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80.0
  alarm_description   = "EC2 CPU usage is too high!"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]
}
```
 
With CloudWatch in place, I can monitor application health and receive alerts if performance issues arise.

IAM Roles ensure **EC2 can securely access S3 & CloudWatch** without needing static credentials.  

### ✅ Why Use IAM Roles?  
✔️ **Increases security** – No hardcoded credentials  
✔️ **Grants Least Privilege Access** – Only necessary permissions are assigned  
✔️ **Allows EC2 to interact with AWS services like S3 & CloudWatch**  

### **Terraform Code (IAM Role for EC2)**  
```hcl
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}
```

This ensures that the EC2 instance can **securely access S3 for avatar storage** and **send logs/metrics to CloudWatch** without manual key management.

## 🚀 Deployment Steps  
Follow these steps to deploy the Grocery App using **Terraform and Docker** on AWS:  
### **1️⃣ Initialize Terraform**  
Run the following command to download necessary provider plugins and initialize Terraform:
```sh
terraform init
```
### **2️⃣ Plan the Infrastructure**  
Check what changes will be applied before deploying:
```sh
terraform plan
```
### **3️⃣ Apply Terraform Configuration**  
Deploy the infrastructure on AWS:
```sh
terraform apply -auto-approve
```
### **4️⃣ Connect to the EC2 Instance**  
Once the instance is running, SSH into it:
```sh
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```
### **5️⃣ Start the Application Using Docker**  
Navigate to the project directory and run Docker Compose:
```sh
cd /home/AWS_grocery
sudo docker-compose up -d --build
```
### **6️⃣ Verify the Deployment**  
Check if the containers are running:
```sh
sudo docker ps
```
Visit the **Application Load Balancer (ALB) DNS URL** in your browser to access the app.
### **7️⃣ Monitor with CloudWatch**  
View logs and metrics:
```sh
aws logs describe-log-groups
aws logs tail /aws/ec2/syslog --follow
```
### **8️⃣ Destroy Infrastructure when you are done**  
To remove all AWS resources:
```sh
terraform destroy -auto-approve
```
