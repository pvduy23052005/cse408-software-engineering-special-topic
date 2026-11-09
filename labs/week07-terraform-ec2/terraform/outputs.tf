output "ec2_instance_id" {
  description = "ID của máy chủ EC2 vừa khởi tạo trên AWS"
  value       = aws_instance.app_server.id
}

output "ec2_public_ip" {
  description = "Địa chỉ Public IP dùng để kết nối SSH, Ansible và chạy ứng dụng container"
  value       = aws_instance.app_server.public_ip
}

output "ec2_private_ip" {
  description = "Địa chỉ Private IP nội bộ trong AWS VPC"
  value       = aws_instance.app_server.private_ip
}

output "ec2_instance_type" {
  description = "Loại máy chủ EC2 đang sử dụng (Free Tier)"
  value       = aws_instance.app_server.instance_type
}

output "ami_used" {
  description = "Ubuntu 24.04 LTS AMI ID được Canonical phát hành và Terraform tự động tra cứu"
  value       = "${data.aws_ami.ubuntu.id} (${data.aws_ami.ubuntu.name})"
}

output "ansible_inventory_path" {
  description = "Đường dẫn tệp inventory.ini vừa được Terraform tự động tạo cho Ansible"
  value       = local_file.ansible_inventory.filename
}

output "ssh_command" {
  description = "Lệnh SSH kết nối trực tiếp vào máy chủ Linux EC2"
  value       = "ssh -i ${pathexpand(var.ssh_private_key_path)} ubuntu@${aws_instance.app_server.public_ip}"
}
