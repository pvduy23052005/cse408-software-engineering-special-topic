# Tuần 07: Cấp phát AWS EC2 Linux (Free Tier) bằng Terraform & Tự động hóa Docker bằng Ansible

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Sinh viên:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** ThS. Nguyễn Thọ Thông

---

## 1. Kiến trúc tổng quan

Tuần 07 triển khai toàn bộ quy trình **IaC + Configuration Management** lên nền tảng đám mây thực tế **AWS EC2 (Region Singapore `ap-southeast-1`)** thuộc gói **AWS Free Tier** để chuẩn bị môi trường chạy container cho Tuần 8:

1. **HashiCorp Terraform (`terraform/`):**
   * Tự động tra cứu AMI **Ubuntu Server 24.04 LTS (`x86_64`)** chính thức mới nhất từ Canonical (`099720109477`).
   * Khởi tạo **EC2 Instance `t3.micro`** (Linux, 2 vCPU, 1 GB RAM, ổ cứng `20 GB gp3` có `delete_on_termination = true`) — hợp lệ **AWS Free Tier** trên tài khoản hiện tại.
   * Tạo **AWS Key Pair (`cse408-week07-key`)** và **Security Group (`cse408-week07-sg`)** mở sẵn cổng `22` (SSH), `80` (HTTP), `443` (HTTPS) cho các container ứng dụng web ở Tuần 8.
   * Tách biệt hoàn toàn bằng tag `Project = cse408-week07`, **không ảnh hưởng** tới các EC2 có sẵn khác (ví dụ `server-nano-box`).
   * Tự động sinh tệp **`ansible/inventory.ini`** chứa Public IP thật qua `local_file` + `templatefile`.
2. **Ansible (`ansible/`):**
   * `setup-os.yml`: Đợi SSH + `cloud-init` hoàn tất, chuẩn hóa múi giờ `Asia/Ho_Chi_Minh`, cài công cụ mạng & kích hoạt tường lửa **UFW** (`deny incoming`, mở `22/80/443`).
   * `install-docker.yml`: Nạp GPG Key chính thức, thêm kho **Docker DEB822** (`download.docker.com`), cài đặt **Docker Engine (`docker-ce`) + Docker Compose V2 (`docker-compose-plugin`)**, đưa user `ubuntu` vào nhóm `docker` và chạy thử `hello-world` **không cần `sudo`**.
   * `site.yml`: Master Playbook gom cả 2 kịch bản thành một luồng khép kín, hỗ trợ kiểm chứng tính nhất quán **Idempotency** (`changed = 0` khi chạy lại).

---

## 2. Cấu trúc thư mục

```text
labs/week07-terraform-ec2/
├── .gitignore
├── README.md
├── terraform/
│   ├── main.tf                       # Khai báo AMI, Key Pair, SG, EC2 Free Tier & sinh inventory.ini
│   ├── variables.tf                  # Biến tham số (region, t3.micro, 20GB gp3, SSH key)
│   ├── outputs.tf                    # Xuất Instance ID, Public IP, AMI và lệnh SSH
│   ├── terraform.tfvars.example      # Mẫu tùy biến biến (t3.micro / t3.small Free Tier)
│   └── templates/
│       └── inventory.ini.tpl         # Khuôn mẫu tự động sinh Inventory cho Ansible
└── ansible/
    ├── ansible.cfg                   # Cấu hình SSH, YAML callback & become
    └── playbooks/
        ├── setup-os.yml              # Chuẩn hóa OS, cloud-init wait & UFW Firewall
        ├── install-docker.yml        # Cài Docker Engine & Docker Compose V2 (DEB822)
        └── site.yml                  # Master Playbook tổng hợp
```

---

## 3. Hướng dẫn thực hành bằng lệnh gốc

### Bước 0: Chuẩn bị khóa SSH chuyên dụng (chỉ làm 1 lần đầu)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/aws_cse408_key -N "" -C "cse408-week07-aws"
```

### Bước 1: Cấp phát máy chủ Linux EC2 (Free Tier) bằng Terraform
```bash
cd /Users/macbook/Documents/hk7/cse408-software-engineering-special-topic/labs/week07-terraform-ec2/terraform
terraform init
terraform validate
terraform apply        # Kiểm tra kế hoạch và gõ 'yes'
```
* Kiểm tra lại thông tin EC2 vừa tạo (Public IP, Instance ID, lệnh SSH):
  ```bash
  terraform output
  ```

### Bước 2: Kiểm tra kết nối & chạy Ansible cấu hình OS + UFW + Docker
```bash
cd ../ansible
cat inventory.ini                      # Xem Public IP Terraform vừa tự điền
ansible cluster -m ping                # Đợi ~15s sau khi apply nếu SSH đang boot
ansible-playbook playbooks/site.yml    # Lần 1: Cài OS + UFW + Docker Engine + Compose V2
```
* **Kiểm chứng tính nhất quán (Idempotency):** Chạy lại lệnh trên lần thứ 2 để xác nhận **`changed=0`**:
  ```bash
  ansible-playbook playbooks/site.yml
  ```

### Bước 3: Kiểm chứng trực tiếp trên AWS & EC2
```bash
# Kiểm tra Docker không cần sudo trên EC2
ansible app_servers -e "ansible_become=false" -m shell -a "docker --version && docker compose version && docker run --rm hello-world"

# Kiểm tra trạng thái dịch vụ Docker & tường lửa UFW
ansible app_servers -m shell -a "systemctl is-active docker && ufw status"
```

### Bước 4: Thu hồi tài nguyên khi không sử dụng (bắt buộc để tối ưu Free Tier)
```bash
cd ../terraform
terraform destroy      # Gõ 'yes' để xóa sạch EC2, EBS gp3, Security Group và Key Pair
```
