output "server_name" {
  description = "Tên định danh máy chủ đã cấp phát"
  value       = var.server_name
}

output "inventory_file_path" {
  description = "Đường dẫn tệp Inventory đã sinh cho Ansible"
  value       = local_file.ansible_inventory.filename
}

output "assigned_ip" {
  description = "Địa chỉ IP của máy chủ"
  value       = var.server_ip
}
