terraform {
  required_version = ">= 1.0.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# 1. Khởi tạo tài nguyên hạ tầng mô phỏng
resource "local_file" "server_spec" {
  filename = "${path.module}/server_spec.json"
  content = jsonencode({
    server_name   = var.server_name
    environment   = var.environment
    http_port     = var.http_port
    created_at    = timestamp()
    provisioned_by = "Terraform"
  })
}

# 2. Tự động sinh tệp danh mục máy chủ cho Ansible
# Cầu nối giữa khâu khởi tạo hạ tầng của Terraform và khâu quản lý cấu hình của Ansible
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOT
# Tệp này được sinh TỰ ĐỘNG bởi Terraform. KHÔNG chỉnh sửa thủ công!
# Thời gian sinh: ${timestamp()}

[webservers]
${var.server_ip} ansible_connection=local server_alias=${var.server_name} http_port=${var.http_port} env=${var.environment}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
managed_by=Terraform_Ansible_Pipeline
EOT
}
