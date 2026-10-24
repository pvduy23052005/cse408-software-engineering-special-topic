terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}

# 1. Quản lý định nghĩa tài nguyên máy chủ ứng dụng (prod-vm)
resource "terraform_data" "app_server" {
  input = {
    name        = var.app_server_config.name
    ip          = var.app_server_config.ip_address
    user        = var.app_server_config.user
    role        = var.app_server_config.role
    cpus        = var.app_server_config.cpus
    memory      = var.app_server_config.memory
    disk        = var.app_server_config.disk
    environment = var.environment
  }
}

# 2. Quản lý định nghĩa tài nguyên máy chủ cơ sở dữ liệu (db-server)
resource "terraform_data" "db_server" {
  input = {
    name        = var.db_server_config.name
    ip          = var.db_server_config.ip_address
    user        = var.db_server_config.user
    role        = var.db_server_config.role
    cpus        = var.db_server_config.cpus
    memory      = var.db_server_config.memory
    disk        = var.db_server_config.disk
    environment = var.environment
  }
}

# 3. Tự động sinh tệp danh mục máy chủ Ansible từ tệp mẫu templatefile
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/inventory.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/inventory.ini.tpl", {
    app_name     = var.app_server_config.name
    app_ip       = var.app_server_config.ip_address
    app_user     = var.app_server_config.user
    db_name      = var.db_server_config.name
    db_ip        = var.db_server_config.ip_address
    db_user      = var.db_server_config.user
    ssh_key_path = var.ssh_private_key_path
  })
}

# 4. Xuất bản tệp đặc tả thông số kỹ thuật cụm máy chủ dạng JSON
resource "local_file" "cluster_spec" {
  filename        = "${path.module}/cluster_spec.json"
  file_permission = "0644"

  content = jsonencode({
    project     = "CSE408 - He thong tu dong hoa ha tang va CI/CD"
    provisioner = "HashiCorp Terraform"
    environment = var.environment
    cluster = {
      app_server = {
        name      = var.app_server_config.name
        role      = var.app_server_config.role
        ip        = var.app_server_config.ip_address
        user      = var.app_server_config.user
        resources = "${var.app_server_config.cpus} vCPU, ${var.app_server_config.memory} RAM, ${var.app_server_config.disk} Disk"
      }
      db_server = {
        name      = var.db_server_config.name
        role      = var.db_server_config.role
        ip        = var.db_server_config.ip_address
        user      = var.db_server_config.user
        resources = "${var.db_server_config.cpus} vCPU, ${var.db_server_config.memory} RAM, ${var.db_server_config.disk} Disk"
      }
    }
    ansible_integration = {
      inventory_file = local_file.ansible_inventory.filename
      ssh_key_used   = var.ssh_private_key_path
    }
  })
}
