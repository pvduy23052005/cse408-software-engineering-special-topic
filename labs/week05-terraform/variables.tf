variable "app_server_config" {
  description = "Thông số cấu hình máy chủ ảo ứng dụng chạy thử nghiệm (test node)"
  type = object({
    name       = string
    ip_address = string
    user       = string
    role       = string
    cpus       = number
    memory     = string
    disk       = string
  })
  default = {
    name       = "prod-vm"
    ip_address = "192.168.252.4"
    user       = "ubuntu"
    role       = "Test App Node"
    cpus       = 1
    memory     = "512MB"
    disk       = "3GB"
  }
}

variable "db_server_config" {
  description = "Thông số cấu hình máy chủ cơ sở dữ liệu chạy thử nghiệm (test node)"
  type = object({
    name       = string
    ip_address = string
    user       = string
    role       = string
    cpus       = number
    memory     = string
    disk       = string
  })
  default = {
    name       = "db-server"
    ip_address = "192.168.252.5"
    user       = "user-db"
    role       = "Test DB Node"
    cpus       = 1
    memory     = "512MB"
    disk       = "3GB"
  }
}

variable "ssh_private_key_path" {
  description = "Đường dẫn tới tệp khóa riêng tư SSH trên máy tính macOS phục vụ Ansible kết nối"
  type        = string
  default     = "~/.ssh/id_ed25519_multipass"
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
  default     = "testing"
}
