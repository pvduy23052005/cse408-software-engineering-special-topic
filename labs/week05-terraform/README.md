# BÀI THỰC HÀNH TUẦN 5: TỰ ĐỘNG XUẤT BẢN DANH MỤC MÁY CHỦ CHO ANSIBLE VÀ KIỂM NGHIỆM TÍNH NHẤT QUÁN CỦA HỆ THỐNG

- **Môn học:** Chuyên đề Kỹ thuật Phần mềm (CSE408)
- **Đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
- **Sinh viên thực hiện:** Phùng Văn Duy – MSSV: 2352270589
- **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
- **Học kỳ / Năm học:** HK7, Năm học 2026-2027

---

## 1. Mục tiêu bài thực hành

Sau khi làm chủ vòng đời lệnh cơ bản trên 1 máy ảo ở Tuần 4, bài thực hành Tuần 5 đóng vai trò là **cây cầu nối then chốt** giữa tầng cấp phát hạ tầng (**Terraform**) và tầng quản lý cấu hình (**Ansible**):

1. **Xóa bỏ hoàn toàn thao tác thủ công:** Loại bỏ việc kỹ sư phải copy/paste thủ công địa chỉ IP từ kết quả của Terraform sang tệp danh mục của Ansible.
2. **Khai báo cụm 02 máy chủ có cấu trúc:** Quản lý đồng thời máy chủ ứng dụng (`prod-vm`, user `ubuntu`) và máy chủ cơ sở dữ liệu (`db-server`, user `user-db`).
3. **Ứng dụng hàm nội suy `templatefile()`:** Sử dụng tệp mẫu `templates/inventory.ini.tpl` để sinh ra tệp danh mục `inventory.ini` chuẩn định dạng phân nhóm Ansible (`[app_servers]`, `[db_servers]`, `[cluster:children]`).
4. **Hoàn thiện khối dữ liệu đầu ra (`outputs.tf`):** Xuất bản dữ liệu có cấu trúc phục vụ kiểm tra và tích hợp tự động.
5. **Kiểm nghiệm tính nhất quán (Idempotency) & Tự chữa lành (Self-healing):** Chứng minh việc chạy lại `apply` nhiều lần không sinh tài nguyên rác, và tự động khôi phục tệp danh mục trong chưa đầy 1 giây khi bị xóa ngoài luồng.

---

## 2. Kiến trúc cụm máy chủ và luồng dữ liệu tích hợp

```text
+-----------------------------------------------------------------------------------+
|                        MÁY TÍNH CÁ NHÂN MACOS (HOST)                              |
|   1. Mã nguồn Terraform HCL (main.tf, variables.tf, terraform.tfvars)             |
|   2. Tệp mẫu cấu trúc danh mục: templates/inventory.ini.tpl                       |
+-----------------------------------------+-----------------------------------------+
                                          |
        +─────────────────────────────────┴─────────────────────────────────+
        │ (terraform apply: Đọc biến và nội suy qua templatefile())         │
        ▼                                                                   ▼
+-----------------------------------------+       +-----------------------------------------+
|     TỆP DANH MỤC MÁY CHỦ ANSIBLE        |       |        TỆP ĐẶC TẢ KỸ THUẬT JSON         |
|             (inventory.ini)             |       |           (cluster_spec.json)           |
+-----------------------------------------+       +-----------------------------------------+
| [app_servers]                           |       | {                                       |
| prod-vm ansible_host=192.168.252.4 ...  |       |   "cluster": {                          |
|                                         |       |     "app_server": { ... },              |
| [db_servers]                            |       |     "db_server":  { ... }               |
| db-server ansible_host=192.168.252.5 ...|       |   }                                     |
+-----------------------------------------+       +-----------------------------------------+
                    │
                    ▼ (Chuyển giao trực tiếp làm đầu vào cho Tuần 6)
+-----------------------------------------------------------------------------------+
|                CÔNG CỤ QUẢN LÝ CẤU HÌNH ANSIBLE (TUẦN 6)                          |
|             ansible -i inventory.ini cluster -m ping                              |
|             ansible-playbook -i inventory.ini setup-os.yml                        |
+-----------------------------------------------------------------------------------+
```

---

## 3. Cấu trúc thư mục bài thực hành

```text
labs/week05-terraform/
├── main.tf                     # Khai báo tài nguyên cụm máy chủ & local_file inventory
├── variables.tf                # Khai báo biến cấu hình cho 2 máy chủ và khóa SSH
├── terraform.tfvars            # Tham số cấu hình thực tế của cụm máy chủ
├── terraform.tfvars.example    # Tệp mẫu tham số đẩy lên Git cho người khác tham khảo
├── outputs.tf                  # Xuất dữ liệu có cấu trúc (IP, SSH, inventory path)
├── README.md                   # Hướng dẫn chi tiết bài thực hành Tuần 5
├── templates/
│   └── inventory.ini.tpl       # Tệp mẫu danh mục máy chủ Ansible
└── scripts/
    ├── run_lifecycle.sh        # Kịch bản thực thi tự động toàn bộ vòng đời Tuần 5
    ├── test_idempotency.sh     # Kịch bản kiểm nghiệm tính nhất quán (chạy 3 lần liên tiếp)
    └── test_drift.sh           # Kịch bản kiểm nghiệm tự chữa lành khi mất inventory.ini
```

---

## 4. Hướng dẫn thực hành từng bước chi tiết

Di chuyển vào thư mục bài thực hành:
```bash
cd labs/week05-terraform
```

### Bước 1: Khởi tạo và kiểm tra cú pháp
```bash
# 1. Định dạng mã nguồn
terraform fmt

# 2. Khởi tạo môi trường Terraform
terraform init

# 3. Kiểm tra tính hợp lệ của mã nguồn
terraform validate
```

### Bước 2: Xem trước kế hoạch thực thi (`terraform plan`)
```bash
terraform plan
```
*Quan sát kết quả:* Terraform thông báo sẽ tạo 4 tài nguyên:
* `terraform_data.app_server`
* `terraform_data.db_server`
* `local_file.ansible_inventory` (Tệp `inventory.ini`)
* `local_file.cluster_spec` (Tệp `cluster_spec.json`)

### Bước 3: Áp dụng thay đổi (`terraform apply`)
```bash
terraform apply
```
*(Gõ `yes` khi được hỏi).*

Sau khi hoàn tất, kiểm tra nội dung tệp danh mục Ansible vừa được sinh ra:
```bash
cat inventory.ini
```

### Bước 4: Kiểm nghiệm tính nhất quán (Idempotency)
Chạy lại lệnh `apply` một lần nữa để chứng minh tính nhất quán:
```bash
terraform apply
```
*Kết quả:* `No changes. Your infrastructure matches the configuration.` (`0 added, 0 changed, 0 destroyed`).

### Bước 5: Kiểm nghiệm khả năng tự phục hồi (Self-healing)
Cố tình xóa tệp danh mục:
```bash
rm -f inventory.ini
```
Chạy `terraform plan` để thấy Terraform phát hiện tệp bị mất (`1 to add`), sau đó chạy `terraform apply -auto-approve` để hệ thống tự tái tạo lại tệp `inventory.ini` chuẩn xác.

---

## 5. Sử dụng các kịch bản tự động hóa có sẵn

Bạn có thể chạy nhanh các kịch bản kiểm nghiệm đã được chuẩn bị sẵn trong thư mục `scripts/`:

```bash
# 1. Chạy xuyên suốt vòng đời Tuần 5
./scripts/run_lifecycle.sh

# 2. Chạy kiểm nghiệm tính nhất quán 3 lần liên tiếp
./scripts/test_idempotency.sh

# 3. Chạy kịch bản mô phỏng xóa file và tự phục hồi
./scripts/test_drift.sh
```

---

## 6. Kết luận và chuyển giao sang Tuần 6

Tệp `inventory.ini` được sinh ra tự động từ bài lab này chính là tài nguyên đầu vào để bước sang **Tuần 6: Quản lý cấu hình với Ansible**. Kỹ sư chỉ cần đứng từ máy trạm macOS và gọi lệnh:

```bash
ansible -i labs/week05-terraform/inventory.ini cluster -m ping
```
Toàn bộ cụm máy chủ sẽ phản hồi thông suốt qua giao thức SSH mà không cần bất kỳ can thiệp thủ công nào.
