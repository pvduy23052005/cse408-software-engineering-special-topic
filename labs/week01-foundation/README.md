# HƯỚNG DẪN THỰC HÀNH MINI-LAB TUẦN 1: TERRAFORM & ANSIBLE FOUNDATION

Mini-lab này được thiết kế để bạn thực hành **ngay trên máy tính cá nhân (100% Local)** nhằm hiểu rõ bản chất của:
1. **Terraform:** Cấp phát hạ tầng (Provisioning) và quản lý State.
2. **Ansible:** Quản lý cấu hình (Configuration Management) và kiểm chứng tính **Idempotence**.
3. **Mối liên kết:** Terraform tự động xuất dữ liệu (Output) làm đầu vào (Inventory) cho Ansible.

---

## 1. Cài đặt công cụ trên macOS

Nếu máy tính của bạn chưa có Terraform và Ansible, mở Terminal và chạy:

```bash
# 1. Cài đặt Terraform (qua HashiCorp Homebrew tap)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# 2. Cài đặt Ansible (hoặc cài qua pip trong Python virtual environment)
brew install ansible
# Hoặc cài qua pip nếu không muốn cài qua brew:
# python3 -m venv ~/.ansible-env && source ~/.ansible-env/bin/activate && pip install ansible

# 3. Kiểm tra phiên bản
terraform -version
ansible --version
```

---

## 2. Cấu trúc thư mục Mini-Lab

```text
labs/week01-foundation/
├── terraform/
│   ├── main.tf              # Định nghĩa tài nguyên hạ tầng & sinh inventory cho Ansible
│   ├── variables.tf         # Tham số đầu vào (cổng, tên máy chủ, môi trường)
│   └── outputs.tf           # Xuất thông tin hạ tầng
└── ansible/
    ├── ansible.cfg          # Cấu hình Ansible chạy tối ưu local
    ├── inventory.ini        # Tệp Inventory do Terraform tự động sinh ra
    ├── playbook.yml         # Kịch bản cấu hình máy chủ & deploy website
    └── templates/
        └── index.html.j2    # Mẫu giao diện web động (Jinja2)
```

---

## 3. Các bước thực hành từng lệnh

### Bước 1: Khởi tạo và cấp phát hạ tầng với Terraform
Di chuyển vào thư mục `terraform`:
```bash
cd labs/week01-foundation/terraform
```

1. **Khởi tạo Terraform (Tải provider):**
   ```bash
   terraform init
   ```
   *Ý nghĩa:* Tải các plugin cần thiết (như provider `local`) và khởi tạo thư mục `.terraform/`.

2. **Xem trước kế hoạch thay đổi (Dry-run):**
   ```bash
   terraform plan
   ```
   *Ý nghĩa:* So sánh giữa mã nguồn hiện tại và trạng thái thực tế (`terraform.tfstate`) để dự báo những gì sẽ được tạo mới, sửa đổi hoặc xóa bỏ.

3. **Áp dụng kế hoạch (Tạo hạ tầng):**
   ```bash
   terraform apply -auto-approve
   ```
   *Ý nghĩa:* Cấp phát tài nguyên thực tế và tự động tạo ra file `../ansible/inventory.ini` chứa metadata máy chủ.

4. **Quan sát tệp State:**
   ```bash
   cat terraform.tfstate
   ```
   *Ý nghĩa:* Xem cách Terraform lưu trữ trạng thái hạ tầng thực tế dưới dạng JSON.

---

### Bước 2: Cấu hình và Quản trị với Ansible

Di chuyển sang thư mục `ansible`:
```bash
cd ../ansible
```

1. **Kiểm tra kết nối và Inventory:**
   ```bash
   ansible all -i inventory.ini -m ping
   ```
   *Kết quả mong đợi:* `localhost | SUCCESS => { "ping": "pong" }`

2. **Chạy Playbook cấu hình lần đầu:**
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```
   *Quan sát kết quả:*
   * Các task hiển thị màu vàng (`changed: [localhost]`).
   * Summary: `changed=...`, `ok=...`, `failed=0`.
   * Trang web HTML và cấu hình được tạo thành công tại `/tmp/cse408-web/index.html`.

3. **Kiểm chứng tính Idempotence (Chạy lại lần 2 không thay đổi gì):**
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```
   *Quan sát kết quả:*
   * Các task chuyển sang màu xanh lá (`ok: [localhost]`).
   * Summary: `changed=0`, `failed=0`.
   * *Bản chất:* Ansible kiểm tra thấy trạng thái mong muốn đã tồn tại nên **không thực hiện lại**, không gây lỗi.

4. **Kiểm tra kết quả website đã được deploy:**
   ```bash
   cat /tmp/cse408-web/index.html
   ```

---

### Bước 3: Thử nghiệm thay đổi cấu hình & Chạy lại
1. Sửa biến trong `ansible/playbook.yml` (ví dụ đổi `app_version: "2.0.0"` hoặc đổi `environment_name: "production"`).
2. Chạy lại:
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```
3. Quan sát: Chỉ duy nhất task cập nhật file HTML báo `changed=1`, các task khác đều là `ok`. Đây chính là sức mạnh của Idempotence!

---

### Bước 4: Thu dọn tài nguyên (Cleanup / Destroy)
Sau khi thực hành xong, quay lại thư mục `terraform` để hủy hạ tầng:
```bash
cd ../terraform
terraform destroy -auto-approve
```
Xóa thư mục tạm của web server:
```bash
rm -rf /tmp/cse408-web
```
Hạ tầng trở về trạng thái sạch sẽ ban đầu (Clean slate).
