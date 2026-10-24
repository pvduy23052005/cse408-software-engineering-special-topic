terraform {
  required_version = ">= 1.5.0"
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "~> 1.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}

provider "multipass" {}

# Đọc và render tệp cấu hình Cloud-init với khóa công khai SSH thực tế
locals {
  ssh_pub_key = file(pathexpand(var.ssh_public_key_path))
}

resource "local_file" "cloud_init" {
  filename = "${path.module}/cloud-init.yaml"
  content = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    user           = var.app_server_config.user
    ssh_public_key = local.ssh_pub_key
  })
}

# Khởi tạo máy ảo thực tế trên macOS qua Canonical Multipass Provider
resource "multipass_instance" "app_server" {
  name           = var.app_server_config.name
  image          = var.app_server_config.image
  cpus           = var.app_server_config.cpus
  memory         = var.app_server_config.memory
  disk           = var.app_server_config.disk
  cloudinit_file = local_file.cloud_init.filename

  depends_on = [local_file.cloud_init]
}

# Lưu trữ đặc tả thông số kỹ thuật máy chủ ảo đã cấp phát ra tệp JSON
resource "local_file" "server_spec" {
  filename = "${path.module}/server_spec.json"
  content = jsonencode({
    project     = "CSE408 - He thong tu dong hoa ha tang va CI/CD"
    provisioner = "HashiCorp Terraform (larstobi/multipass provider)"
    environment = var.environment
    server = {
      name      = multipass_instance.app_server.name
      role      = "Application Node (Node.js & Nginx)"
      ip        = multipass_instance.app_server.ipv4
      user      = var.app_server_config.user
      resources = "${var.app_server_config.cpus} vCPU, ${var.app_server_config.memory} RAM, ${var.app_server_config.disk} Disk"
      ssh_key   = var.ssh_public_key_path
    }
  })
}
