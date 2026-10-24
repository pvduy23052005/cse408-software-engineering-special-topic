output "app_server_info" {
  description = "Thông tin chi tiết của máy chủ ứng dụng"
  value = {
    name       = var.app_server_config.name
    ip_address = var.app_server_config.ip_address
    user       = var.app_server_config.user
    role       = var.app_server_config.role
  }
}

output "db_server_info" {
  description = "Thông tin chi tiết của máy chủ cơ sở dữ liệu MongoDB"
  value = {
    name       = var.db_server_config.name
    ip_address = var.db_server_config.ip_address
    user       = var.db_server_config.user
    role       = var.db_server_config.role
  }
}

output "cluster_inventory" {
  description = "Danh sách tổng hợp toàn bộ cụm máy chủ phục vụ kiểm tra"
  value = {
    app_host = "${var.app_server_config.user}@${var.app_server_config.ip_address}"
    db_host  = "${var.db_server_config.user}@${var.db_server_config.ip_address}"
  }
}

output "ansible_inventory_file" {
  description = "Đường dẫn tệp danh mục máy chủ Ansible tự động sinh ra"
  value       = local_file.ansible_inventory.filename
}

output "cluster_spec_file" {
  description = "Đường dẫn tệp đặc tả kỹ thuật cụm máy chủ dạng JSON"
  value       = local_file.cluster_spec.filename
}

output "ssh_commands" {
  description = "Các câu lệnh SSH kết nối nhanh tới từng máy chủ trong cụm"
  value = {
    app_server = "ssh -i ${var.ssh_private_key_path} ${var.app_server_config.user}@${var.app_server_config.ip_address}"
    db_server  = "ssh -i ${var.ssh_private_key_path} ${var.db_server_config.user}@${var.db_server_config.ip_address}"
  }
}
