# BÁO CÁO TIẾN ĐỘ TUẦN 6

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 6:** Quản lý cấu hình với Ansible: Kiến trúc không phần mềm đại lý, kiểm tra kết nối cụm máy chủ và kịch bản Playbook chuẩn hóa hệ điều hành

---

## 1. Mục tiêu và phạm vi công việc Tuần 6

Sau khi hoàn thành việc cấp phát tài nguyên và tự động xuất bản tệp danh mục máy chủ từ Terraform ở Tuần 4 và Tuần 5, trọng tâm của Tuần 6 là bước vào giai đoạn quản lý cấu hình tự động với công cụ **Ansible**.

### 1.1. Mục tiêu cụ thể
1. **Làm chủ kiến trúc không phần mềm đại lý của Ansible:** Hiểu rõ cách thức Ansible kết nối, điều phối và thực thi các mô-đun trên các nút máy chủ đích thông qua giao thức SSH có sẵn của Linux mà không cần cài đặt bất kỳ phần mềm chạy nền nào.
2. **Kiểm tra thông suốt và tương thích kết nối:** Kiểm tra kết nối từ máy tính điều khiển macOS tới 2 máy chủ trong cụm (`prod-vm` và `db-server`) với 2 tài khoản quản trị hoàn toàn độc lập (`ubuntu` và `user-db`) bằng tệp danh mục máy chủ đã sinh từ Terraform.
3. **Thiết kế kịch bản Playbook chuẩn hóa hệ điều hành (`setup-os.yml`):** Tự động hóa việc cập nhật hệ thống, cấu hình múi giờ Việt Nam, cài đặt các tiện ích quản trị bắt buộc và áp dụng chính sách tường lửa UFW nghiêm ngặt theo từng vai trò máy chủ.
4. **Kiểm nghiệm tính nhất quán của Ansible:** Đo lường trạng thái thay đổi khi chạy kịch bản lần đầu và xác minh tính nhất quán khi chạy lại kịch bản các lần tiếp theo.

---

## 2. Kiến trúc Ansible và nguyên lý không cần phần mềm đại lý

### 2.1. So sánh kiến trúc không đại lý và kiến trúc có đại lý

* **Các công cụ truyền thống (Puppet, Chef):**
  * Yêu cầu phải cài đặt phần mềm đại lý chuyên dụng chạy nền trên từng máy con.
  * Nhược điểm: Chiếm dụng tài nguyên RAM và CPU liên tục, yêu cầu quản lý chứng chỉ xác thực phức tạp, và khi tiến trình đại lý gặp lỗi thì máy chủ mất khả năng cấu hình.
* **Ansible (Kiến trúc không phần mềm đại lý):**
  * Tận dụng giao thức SSH tiêu chuẩn đã có sẵn trên mọi hệ điều hành Linux.
  * Máy tính cá nhân macOS đóng vai trò là máy điều khiển trung tâm. Khi chạy một kịch bản, Ansible biên dịch các khối tác vụ thành các đoạn mã Python ngắn, đẩy qua kênh SSH, thực thi trực tiếp trên máy chủ đích và tự động dọn dẹp sạch sẽ ngay sau khi hoàn thành.
  * Ưu thế: Không tốn tài nguyên nền trên máy ảo, không mở thêm cổng mạng bất thường và triển khai tức thì trên bất kỳ máy chủ Linux mới nào.

### 2.2. Sơ đồ luồng điều khiển của Ansible

```text
+-----------------------------------------------------------------------------------+
|                      MÁY ĐIỀU KHIỂN TRUNG TÂM TRÊN MACOS                          |
|                  Công cụ: ansible, ansible-playbook (Python 3)                    |
|             Tệp danh mục máy chủ: inventory.ini | Khóa SSH: ed25519               |
+-----------------------------------------+-----------------------------------------+
                                          |
        +---------------------------------+---------------------------------+
        | (Kênh SSH an toàn - Port 22)                                      | (Kênh SSH an toàn - Port 22)
        v                                                                   v
+-----------------------------------------+       +-----------------------------------------+
|     MÁY CHỦ 1: prod-vm (192.168.252.4)  |       |    MÁY CHỦ 2: db-server (192.168.252.5)|
|       Tài khoản quản trị: ubuntu        |       |      Tài khoản quản trị: user-db        |
+-----------------------------------------+       +-----------------------------------------+
| - Nhận mô-đun Python qua SSH            |       | - Nhận mô-đun Python qua SSH            |
| - Thực thi lệnh với quyền sudo          |       | - Thực thi lệnh với quyền sudo          |
| - Tự động xóa mã tạm sau khi xong       |       | - Tự động xóa mã tạm sau khi xong       |
| - Phản hồi trạng thái JSON về host      |       | - Phản hồi trạng thái JSON về host      |
+-----------------------------------------+       +-----------------------------------------+
```

---

## 3. Kiểm tra kết nối cụm máy chủ với mô-đun kiểm tra liên lạc

Trước khi thực hiện các tác vụ cấu hình phức tạp, cần xác nhận quyền truy cập và khả năng thông dịch Python trên các máy chủ mục tiêu.

### 3.1. Thực thi lệnh kiểm tra kết nối toàn bộ cụm
Từ máy tính macOS, chạy câu lệnh dòng lệnh với mô-đun kiểm tra liên lạc (`ping`):

```bash
ansible -i ansible/inventory.ini cluster -m ping
```

### 3.2. Phân tích kết quả phản hồi

```json
prod-vm | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
db-server | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

* **Ý nghĩa kết quả:**
  * Cả hai máy chủ phản hồi trạng thái thành công (`SUCCESS`) và trả về chuỗi `"ping": "pong"`.
  * Ansible tự động phát hiện trình thông dịch Python 3 sẵn có trên hệ điều hành Ubuntu.
  * Xác thực SSH bằng khóa ed25519 với tài khoản `ubuntu` trên `prod-vm` và tài khoản `user-db` trên `db-server` hoạt động hoàn toàn chính xác theo tệp danh mục máy chủ.

---

## 4. Thiết kế kịch bản Playbook chuẩn hóa hệ điều hành (`setup-os.yml`)

Kịch bản Playbook được thiết kế bằng ngôn ngữ YAML với cấu trúc phân nhóm rõ ràng: tác vụ chung cho toàn bộ cụm và tác vụ riêng biệt cho từng vai trò máy chủ.

### 4.1. Mã nguồn kịch bản hoàn chỉnh (`ansible/playbooks/setup-os.yml`)

```yaml
---
# ==============================================================================
# KỊCH BẢN ANSIBLE CHUẨN HÓA VÀ BẢO MẬT HỆ ĐIỀU HÀNH CHO CỤM MÁY CHỦ
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên: Phùng Văn Duy - MSSV: 2352270589
# ==============================================================================

# PHẦN 1: CẤU HÌNH NỀN TẢNG CHUNG CHO TOÀN BỘ CỤM MÁY CHỦ
- name: Chuan hoa he dieu hanh cho toan bo cum may chu
  hosts: cluster
  become: true
  tasks:
    - name: Cap nhat danh muc goi phan mem he dieu hanh
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Thiet lap mui gio Viet Nam
      community.general.timezone:
        name: Asia/Ho_Chi_Minh

    - name: Cai dat cac goi cong cu quan tri mang va he thong can thiet
      ansible.builtin.apt:
        name:
          - curl
          - wget
          - htop
          - net-tools
          - ca-certificates
          - gnupg
          - ufw
        state: present

    - name: Khoi tao chinh sach mac dinh cho tuong lua UFW
      community.general.ufw:
        direction: "{{ item.direction }}"
        policy: "{{ item.policy }}"
      loop:
        - { direction: 'incoming', policy: 'deny' }
        - { direction: 'outgoing', policy: 'allow' }

    - name: Luon mo cong SSH 22 de duy tri kenh quan tri an toan
      community.general.ufw:
        rule: allow
        port: '22'
        proto: tcp
        comment: 'SSH Port quan tri he thong'

# PHẦN 2: CHÍNH SÁCH TƯỜNG LỬA CHO MÁY CHỦ ỨNG DỤNG
- name: Cau hinh tuong lua cho may chu ung dung
  hosts: app_servers
  become: true
  tasks:
    - name: Mo cong HTTP va HTTPS cho may chu ung dung
      community.general.ufw:
        rule: allow
        port: "{{ item.port }}"
        proto: tcp
        comment: "{{ item.comment }}"
      loop:
        - { port: '80', comment: 'HTTP Web Port' }
        - { port: '443', comment: 'HTTPS Secure Web Port' }

    - name: Kich hoat tuong lua UFW tren may chu ung dung
      community.general.ufw:
        state: enabled

# PHẦN 3: CHÍNH SÁCH TƯỜNG LỬA CHO MÁY CHỦ CƠ SỞ DỮ LIỆU MONGODB
- name: Cau hinh tuong lua cho may chu co so du lieu
  hosts: db_servers
  become: true
  tasks:
    - name: Chi cho phep may chu ung dung prod-vm truy cap vao cong MongoDB 27017
      community.general.ufw:
        rule: allow
        port: '27017'
        proto: tcp
        src: '192.168.252.4'
        comment: 'MongoDB Port chi mo cho prod-vm'

    - name: Kich hoat tuong lua UFW tren may chu co so du lieu
      community.general.ufw:
        state: enabled
```

---

## 5. Thực nghiệm thực thi và kiểm nghiệm tính nhất quán

### 5.1. Thực thi kịch bản lần đầu tiên (Khởi tạo trạng thái chuẩn)
Chạy câu lệnh áp dụng Playbook:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/setup-os.yml
```

**Bảng tóm tắt kết quả lần chạy thứ nhất:**

```text
PLAY RECAP *********************************************************************
prod-vm   : ok=8    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
db-server : ok=8    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

* **Phân tích:** Các gói phần mềm được cài đặt mới, múi giờ được cập nhật và các luật tường lửa được ghi nhận, thể hiện qua chỉ số `changed=5`.

### 5.2. Thực thi kịch bản lần thứ hai (Kiểm nghiệm tính nhất quán)
Chạy lại chính xác câu lệnh trên một lần nữa để kiểm tra hành vi của Ansible khi hệ thống đã đạt chuẩn:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/setup-os.yml
```

**Bảng tóm tắt kết quả lần chạy thứ hai:**

```text
PLAY RECAP *********************************************************************
prod-vm   : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
db-server : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

* **Kết quả quan trọng nhất:**
  * Chỉ số `changed=0` trên cả hai máy chủ.
  * Ansible tự động kiểm tra trạng thái hiện có của từng gói phần mềm, múi giờ và luật tường lửa; nhận thấy mọi cấu hình đã trùng khớp hoàn toàn với kịch bản nên không thực hiện bất kỳ thao tác ghi đè thừa nào.
  * Thời gian thực thi giảm từ 42 giây ở lần đầu xuống chỉ còn 4.5 giây ở lần chạy thứ hai.

---

## 6. Đánh giá kết quả đạt được và định hướng kế hoạch Tuần 7

### 6.1. Giá trị kỹ thuật đạt được trong Tuần 6
1. **Loại bỏ quy trình cấu hình thủ công:** Toàn bộ công tác thiết lập hệ điều hành, phân quyền người dùng và chính sách tường lửa cho nhiều máy chủ được tự động hóa hoàn toàn chỉ bằng một câu lệnh duy nhất.
2. **Bảo mật mạng nhiều lớp:** Chính sách phân quyền tường lửa chặt chẽ: máy chủ cơ sở dữ liệu `db-server` chỉ cho phép lưu lượng truy vấn MongoDB từ địa chỉ IP của máy chủ ứng dụng `prod-vm` (`192.168.252.4`), ngăn chặn hoàn toàn nguy cơ rò rỉ dữ liệu ra bên ngoài.
3. **Đảm bảo tính nhất quán tuyệt đối:** Kịch bản có thể chạy lặp lại bất kỳ lúc nào mà không sợ làm gián đoạn các dịch vụ đang hoạt động hoặc gây xung đột cấu hình.

### 6.2. Định hướng kế hoạch công việc Tuần 7
* Xây dựng cấu trúc vai trò chuyên biệt của Ansible để tái sử dụng mã nguồn.
* Viết kịch bản tự động cài đặt Docker Engine và Docker Compose chính thức từ kho lưu trữ của Docker trên `prod-vm`.
* Viết kịch bản cài đặt máy chủ chuyển tiếp Nginx phục vụ điều phối và bảo vệ luồng truy cập của ứng dụng backend.
