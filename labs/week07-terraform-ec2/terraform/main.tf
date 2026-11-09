terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Course    = "CSE408"
      Week      = "Week07"
      ManagedBy = "Terraform"
    }
  }
}

# 1. Tự động tra cứu AMI Ubuntu 24.04 LTS x86_64 mới nhất từ Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical Official AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 2. Sử dụng Default VPC sẵn có của vùng ap-southeast-1
data "aws_vpc" "default" {
  default = true
}

# 3. Đẩy Public Key lên AWS EC2 để cấp quyền đăng nhập SSH cho user ubuntu
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

# 4. Tạo Security Group riêng biệt (tường lửa tầng AWS VPC), mở cổng 22, 80, 443
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Security Group for CSE408 Week 07 Linux EC2 (SSH, HTTP, HTTPS)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH remote administration and Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access for containerized web apps"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS secure web access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound Internet access for APT and Docker pulls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# 5. Khởi tạo 01 máy chủ ảo Linux EC2 (Gói AWS Free Tier)
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required" # Bắt buộc IMDSv2 tăng cường bảo mật Cloud
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${var.project_name}-app-server"
    Role = "app-server"
    OS   = "Ubuntu-24.04-LTS"
  }
}

# 6. Cầu nối Terraform -> Ansible: Tự động sinh tệp ansible/inventory.ini chứa Public IP thật
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/inventory.ini.tpl", {
    host_alias       = "aws-ec2-prod"
    public_ip        = aws_instance.app_server.public_ip
    private_ip       = aws_instance.app_server.private_ip
    instance_id      = aws_instance.app_server.id
    instance_type    = aws_instance.app_server.instance_type
    private_key_path = pathexpand(var.ssh_private_key_path)
  })
}
