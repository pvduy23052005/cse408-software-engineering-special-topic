# BÀI THỰC HÀNH TUẦN 3: THIẾT LẬP MÔI TRƯỜNG CỤM MÁY ẢO VỚI MULTIPASS VÀ TỰ ĐỘNG HÓA CẤU HÌNH CLOUD-INIT

- **Môn học:** Chuyên đề Kỹ thuật Phần mềm (CSE408)
- **Đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
- **Sinh viên thực hiện:** Phùng Văn Duy – MSSV: 2352270589
- **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
- **Học kỳ / Năm học:** HK7, Năm học 2026-2027

---

## 1. Mục tiêu bài thực hành

Bài thực hành Tuần 3 tập trung vào việc kiến tạo nền tảng hạ tầng máy ảo mô phỏng môi trường máy chủ sản xuất cục bộ, phục vụ trực tiếp cho việc triển khai tự động hóa hạ tầng bằng Terraform và Ansible trong các tuần học kế tiếp:

1. **Chuẩn bị môi trường máy ảo hóa nhẹ:** Khai thác công cụ Canonical Multipass trên hệ điều hành macOS nhằm khởi tạo nhanh chóng các máy ảo Ubuntu Linux chuẩn mực mà không gây tốn tài nguyên phần cứng như các phần mềm ảo hóa truyền thống.
2. **Khởi tạo cụm 2 máy chủ độc lập:**
   - **Máy chủ ứng dụng (`app-server`):** Đóng vai trò máy chủ tiếp nhận triển khai mã nguồn dịch vụ backend Node.js, gói ứng dụng Docker và vùng chứa ứng dụng.
   - **Máy chủ cơ sở dữ liệu và giám sát (`db-monitor-server`):** Đóng vai trò máy chủ lưu trữ hệ quản trị cơ sở dữ liệu PostgreSQL và các thành phần theo dõi thu thập chỉ số hệ thống.
3. **Tự động hóa khởi tạo ban đầu với Cloud-init:** Thiết lập thông số ban đầu ngay trong giai đoạn khởi động máy ảo: cấp quyền quản trị không mật khẩu, nạp khóa công khai SSH, cấm đăng nhập bằng mật khẩu thường và định cấu hình bảo vệ tường lửa UFW cơ bản.
4. **Cấu hình xác thực SSH không mật khẩu:** Thiết lập cặp khóa mã hóa ed25519 và cấu hình tệp quản lý SSH Client của máy tính cá nhân để thực hiện truy cập dòng lệnh vào các máy ảo mà không cần nhập mật khẩu.
5. **Kiểm tra thông suốt mạng nội bộ:** Đảm bảo kết nối mạng hai chiều giữa máy tính cá nhân (host) và 2 máy ảo, cũng như kết nối nội bộ giữa 2 máy ảo với nhau.

---

## 2. Kiến trúc cụm máy ảo thực hành

Hệ thống bao gồm máy tính cá nhân và 2 máy ảo được cấp phát mạng nội bộ dạng cầu nối ảo:

```
+-----------------------------------------------------------------------+
|                         MÁY TÍNH CÁ NHÂN (HOST)                       |
|                   Hệ điều hành: macOS (Multipass CLI)                 |
|               Khóa SSH riêng tư: ~/.ssh/id_ed25519_multipass          |
+-----------------------------------+-----------------------------------+
                                    |
          +-------------------------+-------------------------+
          | (Mạng cục bộ ảo - Giao thức SSH / Cổng 22)        |
          v                                                   v
+-----------------------------------+   +-----------------------------------+
|         MÁY ẢO 1: app-server      |   |    MÁY ẢO 2: db-monitor-server    |
+-----------------------------------+   +-----------------------------------+
| - Hệ điều hành: Ubuntu 22.04 LTS  |   | - Hệ điều hành: Ubuntu 22.04 LTS  |
| - Tài nguyên: 1 vCPU, 1.5 GB RAM  |   | - Tài nguyên: 1 vCPU, 1.5 GB RAM  |
| - Ổ đĩa: 10 GB                    |   | - Ổ đĩa: 10 GB                    |
| - Tường lửa: Mở cổng 22, 80, 443  |   | - Tường lửa: Mở cổng 22, 5432, 9090|
| - Vai trò: Nơi chạy Docker Node.js|   | - Vai trò: PostgreSQL & Giám sát  |
+-----------------------------------+   +-----------------------------------+
          |                                                   ^
          +--- (Kết nối mạng nội bộ giữa 2 máy ảo) -----------+
```

---

## 3. Cấu hình tự động hóa với Cloud-init

Tệp mẫu cấu hình `cloud-init.yaml.template` được chuẩn bị để Canonical Cloud-init tự động áp dụng ngay khi máy ảo được khởi động lần đầu tiên:

```yaml
#cloud-config
package_update: true
package_upgrade: false

packages:
  - curl
  - wget
  - git
  - ufw
  - ca-certificates
  - gnupg
  - lsb-release
  - htop
  - net-tools

users:
  - name: ubuntu
    gecos: Ubuntu Default User
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - __SSH_PUBLIC_KEY__

timezone: Asia/Ho_Chi_Minh

runcmd:
  # Cấu hình tường lửa căn bản UFW
  - ufw --force reset
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow 22/tcp comment 'SSH Port'
  - ufw allow 80/tcp comment 'HTTP Port'
  - ufw allow 443/tcp comment 'HTTPS Port'
  - ufw allow 5432/tcp comment 'PostgreSQL Port'
  - ufw allow 9090/tcp comment 'Metrics Prometheus Port'
  - ufw --force enable
  - systemctl restart ufw
```

**Các điểm thiết kế quan trọng:**
- **Không sử dụng mật khẩu:** Tài khoản mặc định `ubuntu` được mở khóa và ủy quyền thực thi đặc quyền qua `sudo` không cần gõ mật khẩu, giúp các công cụ tự động hóa như Ansible sau này thực thi trơn tru.
- **Tiêm khóa công khai SSH:** Khóa công khai của máy tính cá nhân được đưa vào danh sách khóa được phép đăng nhập (`ssh_authorized_keys`).
- **An toàn mạng:** Kích hoạt tường lửa UFW ngay từ đầu, chỉ cho phép các cổng dịch vụ cần thiết trong bài thực hành.

---

## 4. Hướng dẫn thực thi tự động qua kịch bản

Thư mục bài thực hành đã được xây dựng sẵn 3 kịch bản Bash nhằm chuẩn hóa và tối ưu thao tác:

```
labs/week03-multipass/
├── cloud-init.yaml.template     # Mẫu khai báo cấu hình tự động
├── scripts/
│   ├── setup.sh                 # Kịch bản khởi tạo cụm 2 máy ảo tự động
│   ├── verify.sh                # Kịch bản kiểm tra kết nối mạng và tài nguyên
│   └── cleanup.sh               # Kịch bản thu hồi và xóa sạch máy ảo
└── README.md                    # Tài liệu hướng dẫn chi tiết
```

### Bước 4.1. Chạy kịch bản khởi tạo cụm máy ảo

Di chuyển vào thư mục bài thực hành và chạy kịch bản khởi tạo:

```bash
cd labs/week03-multipass
bash scripts/setup.sh
```

**Quá trình thực hiện tự động của kịch bản:**
1. Kiểm tra sự tồn tại của công cụ Multipass trên máy tính.
2. Kiểm tra hoặc tự sinh cặp khóa SSH chuyên dụng `~/.ssh/id_ed25519_multipass`.
3. Sinh tệp cấu hình `cloud-init.yaml` với khóa công khai được điền chính xác.
4. Lần lượt khởi chạy máy ảo `app-server` và `db-monitor-server` (1 vCPU, 1.5 GB RAM, 10 GB ổ đĩa).
5. Tự động lấy địa chỉ IP của từng máy ảo và ghi khối cấu hình định danh vào tệp `~/.ssh/config`.
6. Xuất bản tóm tắt thông tin cụm vào tệp `cluster-info.txt`.

### Bước 4.2. Chạy kịch bản kiểm tra hệ thống

Sau khi khởi tạo xong, chạy kịch bản xác minh:

```bash
bash scripts/verify.sh
```

**Kịch bản sẽ tự động kiểm tra 5 tiêu chí:**
- Trạng thái các máy ảo (phải ở trạng thái đang hoạt động).
- Khả năng phản hồi gói tin mạng (Ping) từ máy tính cá nhân tới các máy ảo.
- Kết nối SSH không cần mật khẩu thông qua tên định danh máy ảo.
- Thông số hệ thống thực tế bên trong máy ảo: Tên máy, phiên bản nhân Linux, thời gian hoạt động, dung lượng RAM và dung lượng đĩa trống.
- Kết nối mạng nội bộ hai chiều giữa `app-server` và `db-monitor-server`.

### Bước 4.3. Thu hồi và dọn dẹp môi trường khi hoàn thành

Khi kết thúc buổi thực hành hoặc muốn làm lại từ đầu để kiểm tra tính tái lập:

```bash
bash scripts/cleanup.sh
```

Kịch bản sẽ tự động dừng máy ảo, xóa bỏ hoàn toàn dữ liệu máy ảo khỏi Multipass, đồng thời dọn dẹp các mục cấu hình tạm thời trong tệp SSH của máy tính.

---

## 5. Hướng dẫn thực hiện từng bước thủ công với Multipass

Nhằm phục vụ việc nắm vững bản chất lệnh quản trị dòng lệnh, dưới đây là các bước thao tác thủ công:

### Bước 5.1. Tạo khóa SSH trên máy tính cá nhân (Host)

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519_multipass -C "cse408-multipass"
chmod 600 ~/.ssh/id_ed25519_multipass
chmod 644 ~/.ssh/id_ed25519_multipass.pub
```

### Bước 5.2. Điền khóa công khai vào mẫu Cloud-init

```bash
sed "s|__SSH_PUBLIC_KEY__|$(cat ~/.ssh/id_ed25519_multipass.pub)|g" cloud-init.yaml.template > cloud-init.yaml
```

### Bước 5.3. Khởi chạy từng máy ảo bằng lệnh Multipass

1. Khởi chạy máy chủ ứng dụng `app-server`:
   ```bash
   multipass launch 22.04 \
       --name app-server \
       --cpus 1 \
       --memory 1.5G \
       --disk 10G \
       --cloud-init cloud-init.yaml
   ```

2. Khởi chạy máy chủ cơ sở dữ liệu `db-monitor-server`:
   ```bash
   multipass launch 22.04 \
       --name db-monitor-server \
       --cpus 1 \
       --memory 1.5G \
       --disk 10G \
       --cloud-init cloud-init.yaml
   ```

### Bước 5.4. Lấy danh sách và địa chỉ IP của các máy ảo

```bash
multipass list
```

Kết quả hiển thị tương tự:
```text
Name                State       IPv4             Image
app-server          Running     192.168.64.12    Ubuntu 22.04 LTS
db-monitor-server   Running     192.168.64.13    Ubuntu 22.04 LTS
```

### Bước 5.5. Cấu hình tệp kết nối nhanh SSH trên máy tính cá nhân

Mở tệp `~/.ssh/config` và bổ sung cấu hình:

```text
Host app-server
    HostName 192.168.64.12
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_multipass
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host db-monitor-server
    HostName 192.168.64.13
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_multipass
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

---

## 6. Kiểm thử kết nối và kiểm tra tài nguyên

### Kiểm tra 6.1. Đăng nhập trực tiếp vào từng máy ảo

Từ cửa sổ dòng lệnh máy tính cá nhân, thực hiện kết nối:

```bash
# Đăng nhập vào máy chủ ứng dụng
ssh app-server

# Kiểm tra quyền quản trị không mật khẩu
sudo whoami
# Kết quả mong đợi: root

# Thoát khỏi máy ảo
exit
```

```bash
# Đăng nhập vào máy chủ cơ sở dữ liệu
ssh db-monitor-server

# Kiểm tra dung lượng bộ nhớ
free -h

# Thoát khỏi máy ảo
exit
```

### Kiểm tra 6.2. Kiểm tra thông suốt mạng nội bộ giữa 2 máy ảo

Đăng nhập vào `app-server` và thực hiện gửi gói tin kiểm tra sang `db-monitor-server`:

```bash
ssh app-server "ping -c 3 db-monitor-server"
```

Hoặc sử dụng trực tiếp địa chỉ IP nội bộ của máy chủ cơ sở dữ liệu:

```bash
ssh app-server "ping -c 3 192.168.64.13"
```

---

## 7. Bảng lệnh tra cứu nhanh và xử lý sự cố thường gặp

### 7.1. Bảng lệnh Multipass thường dùng

| Lệnh | Chức năng giải thích |
| :--- | :--- |
| `multipass list` | Liệt kê tất cả các máy ảo kèm trạng thái và địa chỉ IP |
| `multipass info <tên_máy>` | Xem thông số chi tiết của máy ảo (CPU, RAM, đĩa, mạng) |
| `multipass start <tên_máy>` | Khởi động lại máy ảo đang tắt |
| `multipass stop <tên_máy>` | Dừng hoạt động của máy ảo |
| `multipass restart <tên_máy>` | Khởi động lại hệ điều hành của máy ảo |
| `multipass shell <tên_máy>` | Mở giao diện dòng lệnh trực tiếp vào máy ảo không cần cấu hình SSH |
| `multipass delete <tên_máy>` | Đánh dấu xóa máy ảo |
| `multipass purge` | Giải phóng và dọn sạch hoàn toàn các máy ảo đã đánh dấu xóa |

### 7.2. Xử lý các tình huống sự cố

1. **Lỗi `Permission denied (publickey)` khi kết nối SSH:**
   - **Nguyên nhân:** Khóa công khai chưa được nạp đúng vào tệp `~/.ssh/authorized_keys` của máy ảo hoặc quyền tệp khóa trên máy host quá mở.
   - **Cách khắc phục:**
     - Kiểm tra quyền tệp khóa cá nhân trên máy tính: `chmod 600 ~/.ssh/id_ed25519_multipass`.
     - Sử dụng lệnh `multipass shell app-server` để vào máy ảo kiểm tra tệp `~/.ssh/authorized_keys`.

2. **Máy ảo không nhận được địa chỉ IP sau khi khởi chạy:**
   - **Nguyên nhân:** Trình dịch vụ mạng nền của Multipass bị nghẽn hoặc xung đột mạng ảo hóa trên hệ điều hành máy host.
   - **Cách khắc phục:** Khởi động lại máy ảo bằng lệnh `multipass restart app-server` hoặc khởi động lại dịch vụ Multipass.

3. **Tường lửa UFW chặn nhầm cổng dịch vụ:**
   - **Cách khắc phục:** Đăng nhập vào máy ảo và mở thêm cổng cần thiết:
     ```bash
     sudo ufw allow <số_cổng>/tcp
     sudo ufw status
     ```

---

## 8. Kết quả đầu ra và bước đệm cho các tuần tiếp theo

Hoàn thành bài thực hành Tuần 3 đem lại các kết quả then chốt:

1. **Cụm máy ảo chuẩn mực:** Cụm 2 máy chủ `app-server` và `db-monitor-server` sẵn sàng trên nền tảng Ubuntu 22.04 LTS với cấu hình tài nguyên được cô lập rõ ràng.
2. **Kênh liên lạc tự động hóa thông suốt:** Cơ chế xác thực khóa SSH đã được cấu hình hoàn chỉnh, cho phép các công cụ quản lý cấu hình tự động (như Ansible ở Tuần 5) có thể điều khiển trực tiếp mà không gặp rào cản mật khẩu.
3. **Môi trường tiếp nhận triển khai mã nguồn:**
   - Ở **Tuần 4:** Viết mã nguồn kịch bản Terraform để quản lý và cấp phát hạ tầng tự động.
   - Ở **Tuần 5:** Viết các kịch bản Ansible Playbook để tự động cài đặt Docker, Docker Compose, cấu hình cơ sở dữ liệu và vận hành hệ thống container hoàn chỉnh trên 2 máy ảo này.
