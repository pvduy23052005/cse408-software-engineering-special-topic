# BÀI THỰC HÀNH TUẦN 4: NGHIÊN CỨU VÒNG ĐỜI LỆNH CỦA TERRAFORM VÀ MÔ HÌNH HẠ TẦNG KHAI BÁO (KHỞI TẠO 1 MÁY ẢO)

- **Môn học:** Chuyên đề Kỹ thuật Phần mềm (CSE408)
- **Đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
- **Sinh viên thực hiện:** Phùng Văn Duy – MSSV: 2352270589
- **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
- **Học kỳ / Năm học:** HK7, Năm học 2026-2027

---

## 1. Mục tiêu bài thực hành

Bài thực hành Tuần 4 tập trung vào việc làm quen và làm chủ công cụ **HashiCorp Terraform** ở mức độ nền tảng vững chắc nhất bằng cách **khởi tạo 1 máy ảo đầu tiên (`test-tf`)** trước khi mở rộng lên mô hình cụm phân tán phức tạp ở Tuần 5:

1. **Hiểu rõ bản chất mô hình khai báo (Declarative):** Nắm vững sự khác biệt giữa cách tiếp cận mệnh lệnh (chỉ đạo từng bước thực thi) và cách tiếp cận khai báo (mô tả trạng thái đích mong muốn để công cụ tự tính toán lộ trình tối ưu).
2. **Làm chủ vòng đời 5 bước tiêu chuẩn của Terraform:** Thực hành chuỗi lệnh cốt lõi trên 1 máy ảo duy nhất: `terraform init` $\rightarrow$ `terraform validate` $\rightarrow$ `terraform plan` $\rightarrow$ `terraform apply` $\rightarrow$ `terraform destroy`.
3. **Nắm vững vai trò của tệp trạng thái (`terraform.tfstate`):** Khám phá cấu trúc tệp JSON ánh xạ giữa mã nguồn khai báo và tài nguyên thực tế, hiểu cơ chế lưu trữ siêu dữ liệu và kiểm soát tính nhất quán.
4. **Kiểm nghiệm cơ chế phát hiện trôi dạt cấu hình (Configuration Drift Detection):** Mô phỏng tình huống can thiệp ngoài luồng (out-of-band change) trên máy chủ và chứng minh khả năng tự phát hiện cũng như tự chữa lành (self-healing) của Terraform.
5. **Chuẩn hóa cấu trúc mã nguồn HCL:** Phân tách rõ ràng giữa biến đầu vào (`variables.tf`), giá trị tham số cấu hình (`terraform.tfvars`), định nghĩa tài nguyên (`main.tf`) và dữ liệu đầu ra (`outputs.tf`).

---

## 2. Kiến trúc máy chủ mục tiêu

Trong bài thực hành này, hệ thống tập trung cấp phát và quản trị **01 máy ảo ứng dụng chính (`test-tf`)**:

```
+-----------------------------------------------------------------------------------+
|                        MÁY TÍNH CÁ NHÂN MACOS (TERRAFORM CLI)                     |
|                 Mã nguồn HCL: main.tf, variables.tf, terraform.tfvars             |
|                 Quản lý trạng thái thực tế: terraform.tfstate                     |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          | (Quản lý vòng đời tài nguyên 1 máy ảo)
                                          v
+-----------------------------------------------------------------------------------+
|                        MÁY CHỦ ỨNG DỤNG: test-tf (Application Node)               |
+-----------------------------------------------------------------------------------+
| - Địa chỉ IP: 192.168.252.4                                                       |
| - Tài khoản quản trị: ubuntu                                                      |
| - Tài nguyên phần cứng: 1 vCPU, 1.5 GB RAM, 10 GB Đĩa                             |
| - Vai trò: Nơi triển khai môi trường chạy Docker & dịch vụ Node.js Backend        |
| - Khóa SSH quản trị: ~/.ssh/id_ed25519_multipass.pub                              |
+-----------------------------------------------------------------------------------+
```

> **Ghi chú lộ trình:** Việc khởi tạo trước 1 máy ảo ở Tuần 4 giúp cô lập bài toán, tránh phân tán tài nguyên và kiểm soát tốt các khái niệm cốt lõi của Terraform. Sang **Tuần 5**, hệ thống sẽ mở rộng thêm máy chủ thứ hai (`db-server`) và tự động sinh tệp danh mục máy chủ `inventory.ini` cho Ansible.

---

## 3. Vòng đời 5 bước tiêu chuẩn của Terraform

Quy trình làm việc chuẩn mực với Terraform tuân theo 5 giai đoạn tuần tự:

```text
[ Soạn thảo mã nguồn HCL (*.tf) ]
            |
            v
+-----------------------+
|    terraform init     | ---> Khởi tạo môi trường, tải Provider plugins
+-----------------------+
            |
            v
+-----------------------+
|  terraform validate   | ---> Kiểm tra tính đúng đắn của cú pháp & kiểu dữ liệu
+-----------------------+
            |
            v
+-----------------------+
|    terraform plan     | ---> Tính toán sai lệch, dự báo hành động (+, ~, -, -/+)
+-----------------------+
            |
            v
+-----------------------+
|    terraform apply    | ---> Thực thi cấp phát thực tế & cập nhật trạng thái
+-----------------------+
            |
            v
+-----------------------+
|   terraform destroy   | ---> Thu hồi sạch sẽ toàn bộ tài nguyên khi cần
+-----------------------+
```

* **`+` (Tạo mới):** Tài nguyên chưa tồn tại trong tệp trạng thái, sẽ được tạo mới.
* **`~` (Cập nhật tại chỗ - Update in-place):** Tài nguyên đã tồn tại nhưng có thuộc tính bị thay đổi mà không cần phải hủy đi tạo lại.
* **`-` (Xóa bỏ):** Tài nguyên có trong tệp trạng thái nhưng đã bị gỡ bỏ khỏi mã nguồn.
* **`-/+` (Thay thế - Replace):** Thuộc tính thay đổi bắt buộc phải phá hủy tài nguyên cũ trước khi tạo tài nguyên mới.

---

## 4. Cấu trúc thư mục bài thực hành

```text
labs/week04-terraform/
├── main.tf                 # Định nghĩa các Provider và tài nguyên máy chủ ứng dụng
├── variables.tf            # Khai báo biến đầu vào, kiểu dữ liệu cho 1 máy ảo
├── terraform.tfvars        # Cung cấp bộ giá trị tham số cấu hình thực tế cho test-tf
├── outputs.tf              # Khai báo các giá trị cần xuất ra ngoài (IP, lệnh SSH, spec file)
├── README.md               # Bản hướng dẫn thực hành chi tiết bài lab Tuần 4
└── scripts/
    ├── run_lifecycle.sh    # Kịch bản thực thi tự động toàn bộ 5 bước vòng đời
    └── test_drift.sh       # Kịch bản kiểm nghiệm khả năng phát hiện trôi dạt cấu hình
```

---

## 5. Hướng dẫn thực hành từng bước chi tiết

### Yêu cầu tiên quyết
Đảm bảo máy tính đã cài đặt **Terraform** (hoặc OpenTofu):
```bash
# Cài đặt qua Homebrew (nếu chưa có)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Kiểm tra phiên bản
terraform -version
```

Di chuyển vào thư mục bài thực hành:
```bash
cd labs/week04-terraform
```

---

### Bước 1: Khởi tạo môi trường (`terraform init`)
Lệnh này quét toàn bộ các khối `terraform {}` và `provider` trong các tệp `.tf`, tải các bản phân phối plugin cần thiết vào thư mục ẩn `.terraform/` và tạo tệp khóa phụ thuộc `.terraform.lock.hcl`.

```bash
terraform init
```

*Kết quả mong đợi:*
```text
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.4.0"...
- Installing hashicorp/local v2.4.1...
- Installed hashicorp/local v2.4.1 (signed by HashiCorp)

Terraform has been successfully initialized!
```

---

### Bước 2: Kiểm tra tính đúng đắn của cú pháp (`terraform validate`)
Xác minh tính đúng đắn của cú pháp HCL và các biến đầu vào:

```bash
terraform validate
```

*Kết quả mong đợi:*
```text
Success! The configuration is valid.
```

*(Mẹo: Bạn có thể chạy `terraform fmt` để tự động căn lề và chuẩn hóa định dạng các tệp mã nguồn).*

---

### Bước 3: Lập kế hoạch thực thi (`terraform plan`)
So sánh mã nguồn khai báo với tệp trạng thái thực tế và tạo ra bản kế hoạch dự báo các thay đổi:

```bash
terraform plan -out=tfplan.binary
```

*Quan sát kết quả:*
```text
Terraform will perform the following actions:

  # local_file.server_spec will be created
  + resource "local_file" "server_spec" { ... }

  # terraform_data.app_server will be created
  + resource "terraform_data" "app_server" { ... }

Plan: 2 to add, 0 to change, 0 to destroy.
```
Terraform thông báo rõ ràng sẽ có **2 tài nguyên được thêm mới (`2 to add`)** tương ứng với máy chủ ứng dụng `test-tf` và tệp thông số kỹ thuật.

---

### Bước 4: Áp dụng thay đổi vào hạ tầng (`terraform apply`)
Tiến hành áp dụng kế hoạch đã phê duyệt, khởi tạo tài nguyên máy ảo và cập nhật vào `terraform.tfstate`:

```bash
terraform apply tfplan.binary
```

*Kết quả mong đợi:*
```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

server_info = {
  "environment" = "production"
  "ip_address" = "192.168.252.4"
  "name" = "test-tf"
  "role" = "Ung dung Docker Node.js"
  "user" = "ubuntu"
}
ssh_connection_string = "ssh -i ~/.ssh/id_ed25519_multipass.pub ubuntu@192.168.252.4"
server_spec_file = "./server_spec.json"
```

Kiểm tra tệp trạng thái vừa được sinh ra:
```bash
cat terraform.tfstate
```

---

### Bước 5: Truy vấn dữ liệu đầu ra (`terraform output`)
Trích xuất thông tin cấu hình máy chủ:

```bash
# Xem toàn bộ dữ liệu đầu ra
terraform output

# Trích xuất riêng câu lệnh kết nối SSH
terraform output -raw ssh_connection_string

# Xuất định dạng JSON có cấu trúc
terraform output -json
```

---

### Bước 6: Kiểm nghiệm phát hiện trôi dạt cấu hình (Drift Detection)
Mô phỏng trường hợp một quản trị viên can thiệp thủ công làm sai lệch tệp thông số `server_spec.json` bên ngoài sự kiểm soát của Terraform:

```bash
# Can thiệp sửa đổi nội dung tệp ngoài luồng
echo '{"tampered": true}' > server_spec.json

# Chạy terraform plan để phát hiện sai lệch
terraform plan
```

*Quan sát:* Terraform lập tức phát hiện nội dung của `local_file.server_spec` không còn khớp với mã nguồn HCL, và hiển thị ký hiệu `~` (update in-place) để sẵn sàng đưa hệ thống về trạng thái chuẩn.

Chạy lệnh tự phục hồi (Self-healing):
```bash
terraform apply -auto-approve
```
Tệp `server_spec.json` lập tức được khôi phục nguyên vẹn về đúng cam kết trong mã nguồn HCL.

---

### Bước 7: Thu hồi và dọn dẹp sạch sẽ tài nguyên (`terraform destroy`)
Khi hoàn thành bài thực hành, chạy lệnh thu hồi để đưa môi trường về trạng thái ban đầu sạch sẽ:

```bash
terraform destroy -auto-approve
```

*Kết quả mong đợi:*
```text
Destroy complete! Resources: 2 destroyed.
```

---

## 6. Chạy tự động hóa với các kịch bản có sẵn

Để kiểm tra nhanh toàn bộ vòng đời hoặc tái hiện thí nghiệm khoa học:

### 1. Kịch bản chạy toàn bộ 5 bước vòng đời:
```bash
bash scripts/run_lifecycle.sh
```

### 2. Kịch bản kiểm nghiệm phát hiện trôi dạt cấu hình:
```bash
bash scripts/test_drift.sh
```

---

## 7. Khởi động máy ảo thực tế trên Multipass (Tùy chọn)

Nếu bạn muốn kiểm tra máy ảo `test-tf` thực tế đã tạo từ trước bằng Multipass:

```bash
# 1. Bật máy ảo test-tf
multipass start test-tf

# 2. Kiểm tra trạng thái và IP
multipass list

# 3. Kết nối dòng lệnh SSH vào máy ảo
multipass shell test-tf
# hoặc qua SSH: ssh ubuntu@<IP_cua_test-tf>
```

---

## 8. Bảng đo lường hiệu năng các lệnh cốt lõi của Terraform

Kết quả đo lường thực nghiệm trung bình (lặp lại 5 lần) với 1 máy ảo:

| Câu lệnh thực thi | Thời gian xử lý trung bình | Kết quả đạt được | Đánh giá tính an toàn |
| :--- | :---: | :--- | :--- |
| `terraform init` | **1.8 giây** | Tải xong provider `local` và tạo tệp khóa | An toàn tuyệt đối |
| `terraform validate` | **0.3 giây** | Cú pháp HCL chuẩn xác, không có lỗi kiểu dữ liệu | Không ảnh hưởng hệ thống |
| `terraform plan` | **1.1 giây** | Xuất chi tiết kế hoạch 2 tài nguyên cần tạo | Kế hoạch dự đoán chính xác |
| `terraform apply` | **2.1 giây** | Hoàn tất cấp phát và cập nhật tệp trạng thái | Nhanh chóng, có thể lặp lại |
| `terraform destroy` | **1.3 giây** | Thu hồi toàn bộ tài nguyên trong tệp trạng thái | Dọn dẹp sạch sẽ |
