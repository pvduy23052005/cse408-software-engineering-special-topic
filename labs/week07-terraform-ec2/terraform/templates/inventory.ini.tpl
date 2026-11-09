[app_servers]
${host_alias} ansible_host=${public_ip} ansible_user=ubuntu instance_id=${instance_id} instance_type=${instance_type} private_ip=${private_ip}

[cluster:children]
app_servers

[all:vars]
ansible_ssh_private_key_file=${private_key_path}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
