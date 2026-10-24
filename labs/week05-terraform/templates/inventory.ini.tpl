# ==============================================================================
# TỆP DANH MỤC MÁY CHỦ ANSIBLE TỰ ĐỘNG SINH TỪ TERRAFORM - TUẦN 5
# Đề tài: Tự động hóa hạ tầng và CI/CD với Docker, Terraform và Ansible
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
# ==============================================================================

[app_servers]
${app_name} ansible_host=${app_ip} ansible_user=${app_user}

[db_servers]
${db_name} ansible_host=${db_ip} ansible_user=${db_user}

[cluster:children]
app_servers
db_servers

[all:vars]
ansible_ssh_private_key_file=${ssh_key_path}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
