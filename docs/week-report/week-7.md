# BÁO CÁO TIẾN ĐỘ TUẦN 7

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** ThS. Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 7:** Chuyển dịch hạ tầng thực thi lên nền tảng Cloud thực tế (**AWS EC2 Linux Free Tier**): Dùng **Terraform** cấp phát hạ tầng AWS (`aws_instance`, Security Group, Key Pair) tự động sinh Ansible Inventory, sau đó dùng **Ansible** chuẩn hóa OS/UFW và cài đặt **Docker Engine + Docker Compose V2** chính thức

---

## 1. Mục tiêu và phạm vi công việc Tuần 7

Từ Tuần 6 trở về trước, các thử nghiệm hạ tầng và cấu hình hệ thống được thiết kế trên môi trường mô phỏng nội bộ. Bước sang Tuần 7, đề tài chuyển trực tiếp sang nền tảng **Public Cloud thực tế (AWS Region `ap-southeast-1` Singapore)** với 01 máy chủ **Linux Ubuntu 24.04 LTS thuộc gói AWS Free Tier**, hoàn thiện môi trường chạy container trước khi kết nối vào đường ống CI/CD ở Tuần 8.

### 1.1. Mục tiêu cụ thể
1. **Cấp phát hạ tầng AWS EC2 Linux hoàn toàn bằng Terraform (IaC):**
   * Tự động tra cứu AMI **Ubuntu Server 24.04 LTS (`x86_64`)** mới nhất từ tài khoản chính thức Canonical (`099720109477`).
   * Tạo **Key Pair**, **Security Group** (mở sẵn cổng TCP `22`, `80`, `443` cho ứng dụng container) và khởi tạo EC2 Instance **`t3.micro`** (hợp lệ trong danh mục Free Tier của tài khoản, kèm ổ đĩa `20 GB gp3` tự động xóa khi thu hồi `delete_on_termination = true`, bật bắt buộc IMDSv2).
2. **Tự động hóa cầu nối Terraform $\rightarrow$ Ansible (`inventory.ini`):**
   * Terraform sử dụng `local_file` và `templatefile` tự động trích xuất Public IP động vừa cấp phát từ AWS để ghi vào `ansible/inventory.ini`, loại bỏ thao tác copy-paste IP thủ công.
3. **Chuẩn hóa OS & Cài đặt Docker Engine + Docker Compose V2 chính thức bằng Ansible:**
   * Xử lý các đặc thù khởi động lần đầu của Cloud VM (`wait_for_connection`, `cloud-init status --wait`, APT `lock_timeout`).
   * Thiết lập tường lửa UFW (`deny incoming`, mở `22/80/443`), cấu hình kho **Docker APT DEB822** (`download.docker.com`), cài đặt `docker-ce`, `containerd.io`, `docker-compose-plugin` (Compose V2) và cấp quyền nhóm `docker` cho tài khoản `ubuntu` (chạy container không cần `sudo`).
   * Toàn bộ ứng dụng web hoặc Reverse Proxy ở các tuần sau sẽ chạy đóng gói trực tiếp trong container Docker thay vì cài rải rác trực tiếp trên hệ điều hành chủ.
4. **Kiểm nghiệm tính nhất quán (Idempotency) & Quản trị chi phí Cloud:**
   * Đo đạc chỉ số `changed = 0` khi chạy lại Master Playbook `site.yml` và thực hành thu hồi sạch tài nguyên bằng `terraform destroy` để đảm bảo chi phí `$0.00`.

---

## 2. Cơ sở lý luận & Kiến trúc kỹ thuật

### 2.1. Lựa chọn cấu hình AWS EC2 Linux Free Tier phù hợp

Qua kiểm tra trực tiếp bằng **AWS CLI** (`aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true"` tại vùng `ap-southeast-1`), danh mục máy chủ Free Tier trên tài khoản hiện tại hỗ trợ thế hệ mới như **`t3.micro`**, **`t3.small`**, **`t4g.micro`**, **`t4g.small`**, thay vì dòng cũ `t2.micro`.

| Thông số kỹ thuật | Lựa chọn mặc định (`t3.micro`) | Phương án mở rộng (`t3.small`) | Ghi chú tối ưu Free Tier |
| :--- | :--- | :--- | :--- |
| **Kiến trúc CPU** | `x86_64` (2 vCPU) | `x86_64` (2 vCPU) | Tương thích rộng rãi mọi Docker Image |
| **Bộ nhớ RAM** | 1.0 GiB (1024 MiB) | 2.0 GiB (2048 MiB) | Đủ chạy OS + Docker Engine + Container |
| **Hệ điều hành** | Ubuntu Server 24.04 LTS (Linux) | Ubuntu Server 24.04 LTS (Linux) | AMI chính chủ Canonical (`099720109477`) |
| **Ổ cứng hệ thống** | 20 GB EBS `gp3` | 20 GB EBS `gp3` | Giới hạn Free Tier EBS lên tới 30 GB |
| **Chi phí dự kiến** | **0 USD** (trong hạn mức Free Tier) | **0 USD** (trong hạn mức Free Tier) | Thu hồi sạch qua `terraform destroy` |

### 2.2. Kiến trúc phân tầng và luồng tự động hóa Cloud

```text
[ Máy trạm macOS (Terraform + Ansible + AWS CLI) ]
       │
       ├──(1) Terraform Apply ──► AWS API (ap-southeast-1)
       │                             ├─ aws_key_pair (cse408-week07-key)
       │                             ├─ aws_security_group (TCP 22, 80, 443)
       │                             └─ aws_instance (aws-ec2-prod: t3.micro, Ubuntu 24.04)
       │
       ├──(2) local_file ───────► Tự động sinh ansible/inventory.ini (chứa Public IP thật)
       │
       └──(3) Ansible SSH ──────► [ AWS EC2: aws-ec2-prod ]
                                    ├─ UFW Firewall (Deny Incoming, Allow 22/80/443)
                                    └─ Docker Engine + Compose V2 (user ubuntu non-sudo)
```

### 2.3. Phân biệt Docker Compose V1 và Docker Compose V2

| Tiêu chí | Docker Compose V1 (Đã ngừng hỗ trợ) | Docker Compose V2 (Chuẩn hiện nay) |
| :--- | :--- | :--- |
| **Ngôn ngữ phát triển** | Python | Go (đồng nhất với Docker Engine) |
| **Cú pháp dòng lệnh** | `docker-compose` (lệnh rời) | `docker compose` (tích hợp trực tiếp vào Docker CLI) |
| **Gói cài đặt Ansible** | Cài thủ công binary Python cũ | Gói chính thức `docker-compose-plugin` qua APT |

---

## 3. Nội dung thực hiện chi tiết (`labs/week07-terraform-ec2/`)

### 3.1. Lớp Hạ tầng Terraform (`terraform/`)
* **`main.tf`:**
  * Sử dụng `hashicorp/aws ~> 5.0` kết hợp `default_tags` (`Project = "cse408-week07"`, `Course = "CSE408"`, `Week = "Week07"`) để phân tách tài nguyên mới, tránh xung đột với các máy chủ có sẵn trên tài khoản AWS.
  * Sử dụng `pathexpand()` và `trimspace()` để đọc khóa công khai SSH an toàn, không lỗi đường dẫn `~`.
  * Thiết lập `metadata_options { http_tokens = "required" }` (IMDSv2) nhằm phòng chống lỗ hổng truy cập trái phép metadata trên Cloud.
* **`outputs.tf`:** Xuất `ec2_instance_id`, `ec2_public_ip`, `ec2_private_ip`, `ami_used`, `ansible_inventory_path` và `ssh_command`.

### 3.2. Lớp Cấu hình Ansible (`ansible/playbooks/`)
1. **`setup-os.yml`:**
   * Dùng `wait_for_connection` và `cloud-init status --wait` (kết hợp `lock_timeout: 120` cho APT) để khắc phục triệt để lỗi xung đột khóa APT khi Cloud VM vừa khởi động.
   * Cấu hình múi giờ `Asia/Ho_Chi_Minh`, cài `curl`, `wget`, `htop`, `net-tools`, `python3-debian`, `ufw` và mở sẵn cổng `22`, `80`, `443` trước khi bật `enabled` cho UFW.
2. **`install-docker.yml`:**
   * Tải khóa GPG từ `download.docker.com` vào `/etc/apt/keyrings/docker.asc`.
   * Dùng module hiện đại **`ansible.builtin.deb822_repository`** (chuẩn Ubuntu 24.04 Noble và tương thích không cảnh báo với `ansible-core 2.21+`) để khai báo kho Docker chính thức.
   * Cài `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`.
   * Đưa `ubuntu` vào nhóm `docker`, gọi `meta: reset_connection` để nạp ngay quyền nhóm mới trong cùng phiên Playbook và kiểm thử chạy `docker run --rm hello-world` dưới quyền `ubuntu` (không dùng `sudo`).
3. **`site.yml`:** Master Playbook kết hợp tuần tự `setup-os.yml` $\rightarrow$ `install-docker.yml`.

---

## 4. Quy trình kiểm thử và tiêu chí Idempotency

| Tiêu chí kiểm tra | Lệnh thực hiện gốc | Kết quả kỳ vọng |
| :--- | :--- | :--- |
| **Xác thực cú pháp IaC & Playbook** | `terraform validate`, `ansible-playbook playbooks/site.yml --syntax-check` | Hợp lệ 100%, 0 lỗi và 0 deprecated warning |
| **Khởi tạo & Cấp phát Cloud** | `terraform apply` | 01 EC2 `t3.micro` trạng thái `running`, tự sinh `ansible/inventory.ini` |
| **Cấu hình lần 1 (Bootstrap)** | `ansible-playbook playbooks/site.yml` | Hoàn tất OS, UFW, Docker CE, Compose V2, chạy `hello-world` OK |
| **Chạy lại lần 2 (Idempotency)** | `ansible-playbook playbooks/site.yml` (lần 2) | **`changed = 0`**, thời gian thực thi nhanh hơn >80% |
| **Thu hồi sạch tài nguyên** | `terraform destroy` | Xóa sạch EC2, EBS `gp3`, Security Group, Key Pair (`0` tài nguyên dư) |

---

## 5. Đánh giá và định hướng kế hoạch Tuần 8

1. **Giá trị đạt được trong Tuần 7:**
   * Đề tài đã sở hữu một máy chủ **Linux Cloud Docker Host (`aws-ec2-prod`)** hoàn chỉnh được quản trị qua mã nguồn (**Terraform + Ansible**), sẵn sàng chạy container đóng gói mà không cần cài dịch vụ ứng dụng rườm rà lên hệ điều hành chủ.
   * Quy trình hoàn toàn có thể thu hồi (`terraform destroy`) và tái lập lại y hệt (`terraform apply` + `site.yml`) chỉ với vài câu lệnh, tối ưu chi phí Free Tier.
2. **Định hướng Tuần 8:**
   * Xây dựng **đường ống CI/CD khép kín với GitHub Actions** (`.github/workflows/deploy.yml`):
     * Tự động kiểm thử mã nguồn ứng dụng và build Docker Image khi `push` code lên GitHub.
     * Đẩy Image lên Container Registry (Docker Hub / GitHub Container Registry).
     * Kết nối SSH vào máy chủ **AWS EC2** để tự động kéo Image mới và triển khai container qua `docker compose up -d`.
