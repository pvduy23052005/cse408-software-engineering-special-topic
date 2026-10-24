variable "app_server_config" {
  description = "Thông số cấu hình máy chủ ảo ứng dụng (test-tf) qua Multipass"
  type = object({
    name   = string
    user   = string
    image  = string
    cpus   = number
    memory = string
    disk   = string
  })
  default = {
    name   = "erraform-init"
    user   = "ubuntu"
    image  = "22.04"
    cpus   = 1
    memory = "1536MiB"
    disk   = "5GiB"
  }
}

variable "ssh_public_key_path" {
  description = "Đường dẫn tới tệp khóa công khai SSH trên máy tính macOS"
  type        = string
  default     = "~/.ssh/db-server-key.pub"
}

variable "environment" {
  description = "Môi trường triển khai của máy chủ"
  type        = string
  default     = "production"
}
