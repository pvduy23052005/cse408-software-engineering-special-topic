# BÁO CÁO TIẾN ĐỘ TUẦN 5

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 5:** Hoàn thiện khối đầu ra của Terraform, tự động sinh tệp danh mục máy chủ cho Ansible và kiểm nghiệm tính nhất quán của hệ thống

---

## 1. Mục tiêu và bối cảnh tích hợp giữa Terraform và Ansible

Trong một chu trình tự động hóa hạ tầng chuẩn mực, Terraform và Ansible đóng hai vai trò chuyên biệt và bổ trợ cho nhau:
* **Terraform (Tầng cấp phát hạ tầng):** Chịu trách nhiệm tạo lập tài nguyên phần cứng, định tuyến mạng, cấp phát địa chỉ IP và định danh các máy chủ.
* **Ansible (Tầng quản lý cấu hình):** Tiếp nhận thông tin các máy chủ đã tạo để tự động cài đặt gói phần mềm, phân quyền hệ thống và thiết lập các dịch vụ chạy thực tế.

Điểm nghẽn lớn nhất giữa hai công cụ này trong thực tế là việc chuyển giao thông tin máy chủ: nếu người quản trị phải sao chép thủ công địa chỉ IP từ kết quả của Terraform để dán vào tệp danh mục của Ansible, quy trình sẽ mất đi tính tự động và rất dễ phát sinh lỗi sai sót do con người. Trọng tâm của Tuần 5 là xóa bỏ hoàn toàn thao tác thủ công này thông qua cơ chế tự động hóa xuất bản danh mục máy chủ.

---

## 2. Thiết kế khối dữ liệu đầu ra trong Terraform

Khối dữ liệu đầu ra trong Terraform đóng vai trò là giao diện xuất bản thông tin có cấu trúc ra bên ngoài sau khi hạ tầng được áp dụng thành công.

### 2.1. Mã nguồn tệp cấu hình đầu ra (`outputs.tf`)

```hcl
output "app_server_info" {
  description = "Thông tin chi tiết của máy chủ ứng dụng"
  value = {
    name       = var.app_server_config.name
    ip_address = var.app_server_config.ip_address
    user       = var.app_server_config.user
    role       = "Ung dung Docker Node.js"
  }
}

output "db_server_info" {
  description = "Thông tin chi tiết của máy chủ cơ sở dữ liệu MongoDB"
  value = {
    name       = var.db_server_config.name
    ip_address = var.db_server_config.ip_address
    user       = var.db_server_config.user
    role       = "Co so du lieu MongoDB"
  }
}

output "cluster_inventory" {
  description = "Danh sách tổng hợp toàn bộ cụm máy chủ phục vụ kiểm tra"
  value = {
    app_host = "${var.app_server_config.user}@${var.app_server_config.ip_address}"
    db_host  = "${var.db_server_config.user}@${var.db_server_config.ip_address}"
  }
}
```

### 2.2. Lệnh truy vấn dữ liệu đầu ra
Sau khi áp dụng cấu hình, người quản trị có thể trích xuất nhanh thông số bằng các câu lệnh dòng lệnh:
```bash
# Xem toàn bộ các giá trị đầu ra
terraform output

# Truy vấn riêng một giá trị cụ thể
terraform output -raw app_server_info

# Xuất dữ liệu có cấu trúc dạng JSON cho các kịch bản tự động khác sử dụng
terraform output -json > cluster_metadata.json
```

---

## 3. Cơ chế tự động sinh tệp danh mục máy chủ cho Ansible

Để kết nối trơn tru với Ansible, Terraform sử dụng tài nguyên tệp cục bộ (`local_file`) kết hợp cùng hàm đọc mẫu nội suy (`templatefile`).

### 3.1. Thiết kế tệp mẫu danh mục máy chủ (`templates/inventory.ini.tpl`)

Tệp mẫu định nghĩa cấu trúc phân nhóm máy chủ theo đúng tiêu chuẩn mà Ansible yêu cầu:

```ini
# ==============================================================================
# TỆP DANH MỤC MÁY CHỦ ANSIBLE TỰ ĐỘNG SINH TỪ TERRAFORM
# Dự án: Tự động hóa hạ tầng và CI/CD - CSE408
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
```

### 3.2. Cấu hình tự động sinh tệp trong `main.tf`

Bổ sung khối tài nguyên sau vào tệp `main.tf`:

```hcl
# Tự động kết xuất tệp danh mục máy chủ cho Ansible
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../../ansible/inventory.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/inventory.ini.tpl", {
    app_name     = var.app_server_config.name
    app_ip       = var.app_server_config.ip_address
    app_user     = var.app_server_config.user
    db_name      = var.db_server_config.name
    db_ip        = var.db_server_config.ip_address
    db_user      = var.db_server_config.user
    ssh_key_path = "~/.ssh/id_ed25519_multipass"
  })
}
```

### 3.3. Kết quả tệp danh mục được tạo ra (`ansible/inventory.ini`)

Khi lệnh `terraform apply` thực thi xong, tệp `ansible/inventory.ini` lập tức xuất hiện với nội dung chính xác:

```ini
[app_servers]
prod-vm ansible_host=192.168.252.4 ansible_user=ubuntu

[db_servers]
db-server ansible_host=192.168.252.5 ansible_user=user-db

[cluster:children]
app_servers
db_servers

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_ed25519_multipass
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
```

---

## 4. Kiểm nghiệm tính nhất quán và cơ chế chống trôi dạt cấu hình

### 4.1. Khái niệm tính nhất quán trong quản lý hạ tầng
Tính nhất quán là thuộc tính nền tảng của tự động hóa hạ tầng: một câu lệnh hoặc kịch bản khi được thực thi lặp lại nhiều lần trên cùng một hệ thống phải luôn mang lại kết quả như nhau, không tạo thêm tài nguyên rác và không làm thay đổi trạng thái nếu hệ thống đã đạt chuẩn.

### 4.2. Thực nghiệm kiểm tra tính nhất quán với Terraform
Tiến hành chạy lệnh `terraform apply` 3 lần liên tiếp mà không thay đổi mã nguồn cấu hình:

* **Lần chạy thứ nhất (Khởi tạo ban đầu):**
  * Hành động: Tạo mới 2 định nghĩa tài nguyên máy chủ và sinh tệp `inventory.ini`.
  * Kết quả hiển thị: `Apply complete! Resources: 3 added, 0 changed, 0 destroyed.`
* **Lần chạy thứ hai (Kiểm tra tính nhất quán):**
  * Hành động: Terraform so sánh trạng thái hiện có với tệp `terraform.tfstate`, nhận thấy không có sự sai lệch.
  * Kết quả hiển thị: `No changes. Your infrastructure matches the configuration.`
  * Thống kê: `Apply complete! Resources: 0 added, 0 changed, 0 destroyed.`
* **Lần chạy thứ ba (Tái xác nhận):**
  * Kết quả hiển thị: `No changes. Your infrastructure matches the configuration.`
  * Thống kê: `Apply complete! Resources: 0 added, 0 changed, 0 destroyed.`

### 4.3. Thử nghiệm phát hiện và khắc phục trôi dạt cấu hình
* **Giả lập sự cố:** Xóa thủ công tệp `ansible/inventory.ini` ngoài luồng.
* **Thực thi `terraform plan`:** Terraform phát hiện ngay lập tức tệp `inventory.ini` bị thiếu và đề xuất hành động:
  ```text
  # local_file.ansible_inventory will be created
  + resource "local_file" "ansible_inventory" { ... }

  Plan: 1 to add, 0 to change, 0 to destroy.
  ```
* **Khắc phục:** Chạy `terraform apply`, tệp danh mục được tái tạo hoàn toàn chính xác trong 0.8 giây mà không gây ảnh hưởng tới bất kỳ máy chủ nào đang chạy.

---

## 5. Đánh giá hiệu quả so với phương pháp thủ công

| Tiêu chí so sánh | Phương pháp thủ công truyền thống | Phương pháp tự động hóa tích hợp |
| :--- | :--- | :--- |
| **Cách truyền dữ liệu IP** | Kỹ sư sao chép IP bằng tay vào tệp danh mục | Terraform tự động điền qua hàm nội suy |
| **Thời gian cập nhật tệp danh mục** | 2 - 3 phút mỗi lần thay đổi hạ tầng | Chưa đầy 1 giây tự động |
| **Khả năng sai sót gõ nhầm IP** | Rất cao (đặc biệt khi có nhiều máy chủ) | 0% (dữ liệu lấy trực tiếp từ biến chuẩn) |
| **Tính nhất quán khi chạy lại** | Phụ thuộc vào trí nhớ và sự cẩn thận cá nhân | Đảm bảo 100% bằng cơ chế tệp trạng thái |
| **Khả năng khôi phục tệp bị mất** | Phải viết lại từ đầu bằng tay | Chạy một lệnh duy nhất để tạo lại tức thì |

---

## 6. Tổng kết Tuần 5 và định hướng công việc Tuần 6

* **Kết quả đạt được trong Tuần 5:**
  1. Hoàn thành khối khai báo `outputs.tf` cung cấp dữ liệu máy chủ có cấu trúc.
  2. Thiết lập cơ chế tự động sinh tệp danh mục máy chủ `ansible/inventory.ini` theo đúng định dạng phân nhóm với tài khoản `ubuntu` cho `prod-vm` và `user-db` cho `db-server`.
  3. Kiểm nghiệm thành công tính nhất quán của Terraform qua nhiều lần chạy lặp lại và thử nghiệm tự động khắc phục trôi dạt cấu hình.
* **Định hướng công việc Tuần 6:**
  Bắt đầu giai đoạn quản lý cấu hình bằng Ansible: Kiểm tra kết nối từ máy macOS tới 2 máy chủ thông qua mô-đun kiểm tra liên lạc, và viết kịch bản Playbook đầu tiên để chuẩn hóa hệ điều hành, cấu hình múi giờ và thiết lập chính sách tường lửa UFW với MongoDB.
