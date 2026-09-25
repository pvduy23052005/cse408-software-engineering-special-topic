# HƯỚNG DẪN THỰC HÀNH BÀI TẬP TUẦN 1: NỀN TẢNG TERRAFORM VÀ ANSIBLE

Bài thực hành này được thiết kế để bạn thực hành **ngay trên máy tính cá nhân** nhằm hiểu rõ bản chất của:
1. **Terraform:** Khởi tạo hạ tầng và quản lý tệp trạng thái.
2. **Ansible:** Quản lý cấu hình và kiểm chứng tính nhất quán.
3. **Mối liên kết:** Terraform tự động xuất dữ liệu làm danh mục máy chủ đầu vào cho Ansible.

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

## 2. Cấu trúc thư mục bài thực hành

```text
labs/week01-foundation/
├── terraform/
│   ├── main.tf              # Định nghĩa tài nguyên hạ tầng & sinh danh mục máy chủ cho Ansible
│   ├── variables.tf         # Tham số đầu vào (cổng, tên máy chủ, môi trường)
│   └── outputs.tf           # Xuất thông tin hạ tầng
└── ansible/
    ├── ansible.cfg          # Cấu hình Ansible chạy tối ưu cục bộ
    ├── inventory.ini        # Tệp danh mục máy chủ do Terraform tự động sinh ra
    ├── playbook.yml         # Kịch bản cấu hình máy chủ & triển khai trang web
    └── templates/
        └── index.html.j2    # Mẫu giao diện trang web động Jinja2
```

---

## 3. Các bước thực hành từng lệnh

### Bước 1: Khởi tạo và cấp phát hạ tầng với Terraform
Di chuyển vào thư mục `terraform`:
```bash
cd labs/week01-foundation/terraform
```

1. **Khởi tạo Terraform:**
   ```bash
   terraform init
   ```
   *Ý nghĩa:* Tải các thành phần bổ trợ cần thiết (như provider `local`) và khởi tạo thư mục `.terraform/`.

2. **Xem trước kế hoạch thay đổi:**
   ```bash
   terraform plan
   ```
   *Ý nghĩa:* So sánh giữa mã nguồn hiện tại và trạng thái thực tế (`terraform.tfstate`) để dự báo những gì sẽ được tạo mới, sửa đổi hoặc xóa bỏ.

3. **Áp dụng kế hoạch:**
   ```bash
   terraform apply -auto-approve
   ```
   *Ý nghĩa:* Cấp phát tài nguyên thực tế và tự động tạo ra tệp `../ansible/inventory.ini` chứa thông tin máy chủ.

4. **Quan sát tệp trạng thái:**
   ```bash
   cat terraform.tfstate
   ```
   *Ý nghĩa:* Xem cách Terraform lưu trữ trạng thái hạ tầng thực tế dưới định dạng JSON.

---

### Bước 2: Cấu hình và Quản trị với Ansible

Di chuyển sang thư mục `ansible`:
```bash
cd ../ansible
```

1. **Kiểm tra kết nối và danh mục máy chủ:**
   ```bash
   ansible all -i inventory.ini -m ping
   ```
   *Kết quả mong đợi:* `localhost | SUCCESS => { "ping": "pong" }`

2. **Chạy kịch bản cấu hình lần đầu:**
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```
   *Quan sát kết quả:*
   * Các tác vụ hiển thị màu vàng (`changed: [localhost]`).
   * Tóm tắt: `changed=...`, `ok=...`, `failed=0`.
   * Trang web HTML và cấu hình được tạo thành công tại `/tmp/cse408-web/index.html`.

3. **Kiểm chứng tính nhất quán (Chạy lại lần 2 không thay đổi gì):**
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```
   *Quan sát kết quả:*
   * Các tác vụ chuyển sang màu xanh lá (`ok: [localhost]`).
   * Tóm tắt: `changed=0`, `failed=0`.
   * *Bản chất:* Ansible kiểm tra thấy trạng thái mong muốn đã tồn tại nên **không thực hiện lại**, đảm bảo tính nhất quán tuyệt đối.

4. **Kiểm tra kết quả trang web đã được triển khai:**
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
3. Quan sát: Chỉ duy nhất tác vụ cập nhật tệp HTML báo `changed=1`, các tác vụ khác đều là `ok`. Đây chính là sức mạnh của tính nhất quán!

---

### Bước 4: Thu dọn tài nguyên
Sau khi thực hành xong, quay lại thư mục `terraform` để hủy hạ tầng:
```bash
cd ../terraform
terraform destroy -auto-approve
```
Xóa thư mục tạm của máy chủ web:
```bash
rm -rf /tmp/cse408-web
```
Hạ tầng trở về trạng thái sạch sẽ ban đầu.
