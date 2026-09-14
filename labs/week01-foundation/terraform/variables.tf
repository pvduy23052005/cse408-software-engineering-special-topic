variable "server_name" {
  type        = string
  description = "Tên định danh của máy chủ mục tiêu"
  default     = "cse408-app-server"
}

variable "environment" {
  type        = string
  description = "Môi trường triển khai (development, staging, production)"
  default     = "development"
}

variable "http_port" {
  type        = number
  description = "Cổng dịch vụ Web HTTP"
  default     = 8080
}

variable "server_ip" {
  type        = string
  description = "Địa chỉ IP hoặc hostname kết nối đến máy chủ"
  default     = "localhost"
}
