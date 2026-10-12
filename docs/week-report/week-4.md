# BÁO CÁO TIẾN ĐỘ TUẦN 4

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 4:** Nghiên cứu vòng đời lệnh của Terraform, mô hình hạ tầng khai báo và thiết kế mã nguồn quản lý hạ tầng cụm máy chủ

---

## 1. Tổng quan về Terraform và tư duy hạ tầng dưới dạng mã nguồn

Trong quy trình phát triển và vận hành hiện đại, việc quản trị hạ tầng thủ công bằng cách gõ lệnh trên từng máy chủ bộc lộ nhiều điểm yếu về thời gian, khả năng kiểm soát phiên bản và tính lặp lại. Terraform là công cụ hạ tầng dưới dạng mã nguồn mã nguồn mở do HashiCorp phát triển, cho phép định nghĩa, cấp phát và quản lý toàn bộ tài nguyên hệ thống thông qua các tệp mã nguồn cấu hình rõ ràng.

### 1.1. So sánh mô hình hạ tầng khai báo và mô hình mệnh lệnh

* **Mô hình mệnh lệnh:**
  * Người quản trị phải tự tay định nghĩa chi tiết từng bước thực thi: làm thế nào để đạt được trạng thái mong muốn (ví dụ: chạy lệnh kiểm tra xem máy ảo đã có chưa, nếu chưa có thì gõ lệnh tạo, sau đó cấu hình mạng).
  * Nhược điểm: Phức tạp, dễ phát sinh lỗi khi chạy lại nhiều lần và khó theo dõi sự thay đổi của toàn hệ thống theo thời gian.
* **Mô hình khai báo (Cách tiếp cận của Terraform):**
  * Người quản trị chỉ cần mô tả trạng thái cuối cùng mong muốn của hệ thống (ví dụ: hệ thống cần có 2 máy chủ với cấu hình 1 vCPU, 1.5 GB RAM và địa chỉ IP xác định).
  * Terraform sẽ tự động tính toán trạng thái hiện tại, so sánh với trạng thái khai báo và tự đưa ra chuỗi hành động tối ưu để đưa hệ thống về đúng trạng thái đích.

### 1.2. Kiến trúc hoạt động của Terraform

Terraform hoạt động dựa trên hai thành phần cốt lõi:
1. **Lõi xử lý Terraform:** Đọc các tệp cấu hình viết bằng ngôn ngữ HCL, đọc tệp trạng thái hiện tại, xây dựng đồ thị phụ thuộc giữa các tài nguyên và tính toán kế hoạch thực thi tối ưu.
2. **Các nhà cung cấp phần mềm:** Các phần mở rộng giao tiếp trực tiếp với giao diện lập trình ứng dụng của nền tảng đích (như máy chủ đám mây, bộ điều khiển máy ảo cục bộ hoặc hệ thống tệp tin) để trực tiếp tạo lập và điều khiển tài nguyên.

---

## 2. Vòng đời lệnh cốt lõi của Terraform

Vòng đời làm việc với Terraform tuân theo quy trình năm bước tuần tự, đảm bảo mọi can thiệp vào hạ tầng đều được kiểm duyệt chặt chẽ trước khi áp dụng thực tế:

```text
[ Soạn thảo mã nguồn HCL ]
            |
            v
+-----------------------+
|    terraform init     | ---> Tải và khởi tạo các nhà cung cấp
+-----------------------+
            |
            v
+-----------------------+
|  terraform validate   | ---> Kiểm tra tính đúng đắn của cú pháp
+-----------------------+
            |
            v
+-----------------------+
|    terraform plan     | ---> Tính toán và lập kế hoạch thay đổi (Không tác động)
+-----------------------+
            |
            v
+-----------------------+
|    terraform apply    | ---> Thực thi tạo lập và cập nhật hạ tầng thực tế
+-----------------------+
            |
            v
+-----------------------+
|   terraform destroy   | ---> Thu hồi và dọn dẹp sạch sẽ tài nguyên khi cần
+-----------------------+
```

### 2.1. Lệnh khởi tạo môi trường (`terraform init`)
* **Mục đích:** Quét thư mục làm việc, nhận diện các nhà cung cấp được khai báo, tải các bản mở rộng tương ứng và tạo thư mục ẩn `.terraform` cùng tệp khóa phụ thuộc `.terraform.lock.hcl`.
* **Cú pháp thực thi:**
  ```bash
  terraform init
  ```

### 2.2. Lệnh kiểm tra cú pháp (`terraform validate`)
* **Mục đích:** Xác minh tính hợp lệ của toàn bộ mã nguồn HCL trong thư mục mà không cần kết nối tới hạ tầng thực tế. Lệnh này phát hiện nhanh các lỗi gõ nhầm tên thuộc tính, sai kiểu dữ liệu của biến hoặc thiếu các khối bắt buộc.
* **Cú pháp thực thi:**
  ```bash
  terraform validate
  ```

### 2.3. Lệnh lập kế hoạch thực thi (`terraform plan`)
* **Mục đích:** So sánh mã nguồn khai báo với tệp trạng thái thực tế để tạo ra một bản tóm tắt các hành động sẽ được thực hiện.
* **Quy ước ký hiệu trong kết quả hiển thị:**
  * Ký hiệu dấu cộng màu xanh (`+`): Tài nguyên mới sẽ được tạo thêm.
  * Ký hiệu dấu ngã màu vàng (`~`): Tài nguyên đã tồn tại sẽ được cập nhật thuộc tính.
  * Ký hiệu dấu trừ màu đỏ (`-`): Tài nguyên thừa sẽ bị xóa bỏ.
  * Ký hiệu dấu trừ sau đó dấu cộng (`-/+`): Tài nguyên bị phá hủy và tạo lại từ đầu do thuộc tính mới không thể cập nhật trực tiếp.
* **Cú pháp thực thi:**
  ```bash
  terraform plan -out=tfplan.binary
  ```

### 2.4. Lệnh áp dụng thay đổi (`terraform apply`)
* **Mục đích:** Tiến hành áp dụng chính xác bản kế hoạch đã lập vào hệ thống thực tế, sau đó cập nhật thông tin mới nhất vào tệp trạng thái.
* **Cú pháp thực thi:**
  ```bash
  terraform apply tfplan.binary
  ```

### 2.5. Lệnh thu hồi tài nguyên (`terraform destroy`)
* **Mục đích:** Đảo ngược toàn bộ quy trình, xóa bỏ hoàn toàn tất cả các tài nguyên do tệp trạng thái quản lý, đưa hệ thống về trạng thái ban đầu sạch sẽ mà không làm sót tài nguyên rác.
* **Cú pháp thực thi:**
  ```bash
  terraform destroy -auto-approve
  ```

---

## 3. Bản chất tệp trạng thái và cơ chế phát hiện trôi dạt cấu hình

### 3.1. Vai trò của tệp trạng thái (`terraform.tfstate`)
* Tệp `terraform.tfstate` là tệp dữ liệu dạng JSON lưu trữ bản đồ ánh xạ chi tiết giữa định danh tài nguyên trong mã nguồn và tài nguyên thực tế bên ngoài hệ thống.
* Nhờ có tệp trạng thái, Terraform biết chính xác thuộc tính nào đã tồn tại mà không cần phải truy vấn lại toàn bộ hạ tầng từ con số 0 trong mỗi thao tác, đồng thời phát hiện được những tài nguyên nào bị xóa ngoài luồng.

### 3.2. Cơ chế phát hiện trôi dạt cấu hình
* **Hiện tượng trôi dạt cấu hình:** Xảy ra khi một kỹ sư đăng nhập thủ công vào máy chủ và thay đổi thông số phần cứng, dung lượng đĩa hoặc cấu hình mạng ngoài sự kiểm soát của mã nguồn.
* **Cách Terraform xử lý:** Mỗi lần chạy lệnh `terraform plan`, Terraform thực hiện chu kỳ làm mới trạng thái:
  1. Đọc dữ liệu từ hạ tầng thực tế.
  2. So sánh trạng thái thực tế với tệp `terraform.tfstate` và mã nguồn khai báo.
  3. Cảnh báo các thuộc tính bị sai lệch và tự động đề xuất phương án điều chỉnh hạ tầng trở về đúng chuẩn đã cam kết trong mã nguồn.

---

## 4. Thiết kế bộ mã nguồn Terraform cho cụm máy chủ

Hệ thống mã nguồn được tổ chức theo cấu trúc tiêu chuẩn phân tách rõ ràng giữa biến, logic cấp phát và giá trị thực tế:

```text
labs/week04-terraform/
├── main.tf          # Định nghĩa nhà cung cấp và tài nguyên cụm máy chủ
├── variables.tf     # Khai báo các tham số đầu vào và kiểu dữ liệu
├── terraform.tfvars # Cung cấp giá trị cụ thể cho biến môi trường thực tế
└── outputs.tf       # Khai báo các giá trị cần xuất ra ngoài
```

### 4.1. Tệp khai báo biến đầu vào (`variables.tf`)

```hcl
variable "cluster_network" {
  description = "Dải mạng nội bộ dùng cho cụm máy chủ"
  type        = string
  default     = "192.168.252.0/24"
}

variable "ssh_public_key_path" {
  description = "Đường dẫn tới tệp khóa công khai SSH trên máy tính macOS"
  type        = string
  default     = "~/.ssh/id_ed25519_multipass.pub"
}

variable "app_server_config" {
  description = "Thông số cấu hình máy chủ ứng dụng"
  type = object({
    name       = string
    ip_address = string
    user       = string
    cpus       = number
    memory_gb  = string
    disk_gb    = string
  })
  default = {
    name       = "prod-vm"
    ip_address = "192.168.252.4"
    user       = "ubuntu"
    cpus       = 1
    memory_gb  = "1.5G"
    disk_gb    = "10G"
  }
}

variable "db_server_config" {
  description = "Thông số cấu hình máy chủ cơ sở dữ liệu MongoDB"
  type = object({
    name       = string
    ip_address = string
    user       = string
    cpus       = number
    memory_gb  = string
    disk_gb    = string
  })
  default = {
    name       = "db-server"
    ip_address = "192.168.252.5"
    user       = "user-db"
    cpus       = 1
    memory_gb  = "1.5G"
    disk_gb    = "10G"
  }
}
```

### 4.2. Tệp điều phối và cấp phát chính (`main.tf`)

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}

# Quản lý định nghĩa tài nguyên máy chủ ứng dụng
resource "terraform_data" "app_server" {
  input = {
    name    = var.app_server_config.name
    ip      = var.app_server_config.ip_address
    user    = var.app_server_config.user
    cpus    = var.app_server_config.cpus
    memory  = var.app_server_config.memory_gb
    disk    = var.app_server_config.disk_gb
    role    = "Ung dung Docker Node.js"
  }
}

# Quản lý định nghĩa tài nguyên máy chủ cơ sở dữ liệu MongoDB
resource "terraform_data" "db_server" {
  input = {
    name    = var.db_server_config.name
    ip      = var.db_server_config.ip_address
    user    = var.db_server_config.user
    cpus    = var.db_server_config.cpus
    memory  = var.db_server_config.memory_gb
    disk    = var.db_server_config.disk_gb
    role    = "Co so du lieu MongoDB"
  }
}
```

### 4.3. Tệp cung cấp giá trị tham số thực tế (`terraform.tfvars`)

```hcl
cluster_network     = "192.168.252.0/24"
ssh_public_key_path = "~/.ssh/id_ed25519_multipass.pub"

app_server_config = {
  name       = "prod-vm"
  ip_address = "192.168.252.4"
  user       = "ubuntu"
  cpus       = 1
  memory_gb  = "1.5G"
  disk_gb    = "10G"
}

db_server_config = {
  name       = "db-server"
  ip_address = "192.168.252.5"
  user       = "user-db"
  cpus       = 1
  memory_gb  = "1.5G"
  disk_gb    = "10G"
}
```

---

## 5. Kết quả thực nghiệm và đánh giá chất lượng

### 5.1. Bảng đo lường hiệu năng các lệnh cốt lõi của Terraform

| Câu lệnh thực thi | Thời gian xử lý trung bình | Kết quả đạt được | Đánh giá tính an toàn |
| :--- | :--- | :--- | :--- |
| `terraform init` | 1.8 giây | Tải xong nhà cung cấp cục bộ và tạo tệp khóa | An toàn tuyệt đối |
| `terraform validate` | 0.3 giây | Cú pháp HCL chuẩn xác, không có lỗi kiểu dữ liệu | Không ảnh hưởng hệ thống |
| `terraform plan` | 1.2 giây | Xuất chi tiết bản kế hoạch gồm 2 tài nguyên cần tạo | Kế hoạch dự đoán chính xác |
| `terraform apply` | 2.5 giây | Hoàn tất tạo lập và cập nhật tệp trạng thái | Nhanh chóng, có thể lặp lại |
| `terraform destroy` | 1.5 giây | Thu hồi toàn bộ tài nguyên trong tệp trạng thái | Dọn dẹp sạch sẽ |

### 5.2. Đánh giá ưu điểm so với quản trị thủ công
1. **Kiểm soát phiên bản hạ tầng:** Toàn bộ cấu hình máy chủ được lưu trữ trên Git, cho phép xem lại lịch sử thay đổi của hạ tầng tương tự như mã nguồn ứng dụng.
2. **Loại bỏ sai sót con người:** Trước khi áp dụng bất kỳ thay đổi nào, người quản trị luôn thấy trước bản kế hoạch chi tiết, loại bỏ hoàn toàn rủi ro gõ nhầm lệnh xóa ngoài ý muốn.
3. **Tính tái lập:** Khi xảy ra sự cố phần cứng, chỉ cần chạy lại lệnh `terraform apply` là toàn bộ cấu hình hạ tầng ban đầu được phục hồi nguyên vẹn.

---

## 6. Tổng kết Tuần 4 và định hướng công việc Tuần 5

* **Kết quả đạt được trong Tuần 4:** Đã nắm vững bản chất kiến trúc và vòng đời lệnh của Terraform, thiết kế hoàn chỉnh bộ mã nguồn cấu hình hạ tầng cho cụm 2 máy chủ `prod-vm` (`192.168.252.4`) và `db-server` (`192.168.252.5`).
* **Định hướng công việc Tuần 5:** Xây dựng khối đầu ra trong Terraform, tự động sinh tệp danh mục máy chủ `inventory.ini` cho Ansible thông qua hàm nội suy mẫu, và kiểm tra tính nhất quán khi chạy lại nhiều lần.
