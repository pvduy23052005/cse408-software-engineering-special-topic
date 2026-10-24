output "server_info" {
  description = "Thông tin chi tiết của máy chủ ảo ứng dụng đã khởi tạo"
  value = {
    name        = multipass_instance.app_server.name
    ip_address  = multipass_instance.app_server.ipv4
    user        = var.app_server_config.user
    role        = "Ung dung Docker Node.js"
    environment = var.environment
  }
}

output "ssh_connection_string" {
  description = "Chuỗi câu lệnh kết nối SSH nhanh đến máy chủ"
  value       = "ssh -i ${var.ssh_public_key_path} ${var.app_server_config.user}@${multipass_instance.app_server.ipv4}"
}

output "server_spec_file" {
  description = "Đường dẫn tệp đặc tả thông số kỹ thuật máy chủ đã xuất bản"
  value       = local_file.server_spec.filename
}
