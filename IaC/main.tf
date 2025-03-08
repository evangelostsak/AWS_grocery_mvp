terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }

}


provider "aws" {
  region = "eu-central-1"
}

resource "aws_key_pair" "existing_key" {
  key_name   = "my-existing-key"
  public_key = file("/Users/tsakoudis/VisualStudioCode/Masterschool/Cloud-Engineering/demotestkey.pub")
}
  
resource "aws_security_group" "ec2_sg" {
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "aws_grocery_terraform" {
  ami                    = "ami-099b9a78992042e1f"
  instance_type          = "t2.micro"
  security_groups        = [aws_security_group.ec2_sg.name]
  key_name               = aws_key_pair.existing_key.key_name
}

resource "aws_security_group" "rds_sg" {
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  username           = "admindb"
  password           = "rdsadminpassword"
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot   = true
}

data "aws_vpc" "default" {
  default = true
}