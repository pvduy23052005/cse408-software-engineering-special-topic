# ==============================================================================
# BIẾN THAM SỐ TERRAFORM - CẤP PHÁT AWS EC2 LINUX FREE TIER (TUẦN 07)
# ==============================================================================

variable "aws_region" {
  description = "Vùng triển khai AWS (Singapore)"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tiền tố đặt tên tài nguyên (Tag Name & Security Group)"
  type        = string
  default     = "cse408-week07"
}

variable "instance_type" {
  description = "Loại máy chủ EC2 Linux"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Đường dẫn tới tệp khóa SSH công khai (.pub)"
  type        = string
  default     = "~/.ssh/aws_cse408_key.pub"
}

variable "ssh_private_key_path" {
  description = "Đường dẫn tới tệp khóa SSH bí mật để điền vào inventory.ini cho Ansible"
  type        = string
  default     = "~/.ssh/aws_cse408_key"
}

variable "root_volume_size" {
  description = "Dung lượng ổ cứng EBS gp3 (GB) - Tối đa 30GB trong gói AWS Free Tier"
  type        = number
  default     = 10
}
