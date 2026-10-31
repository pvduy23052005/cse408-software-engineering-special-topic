# BÀI THỰC HÀNH TUẦN 6: QUẢN LÝ CẤU HÌNH VỚI ANSIBLE, KIỂM TRA LIÊN LẠC CỤM VÀ CHUẨN HÓA BẢO MẬT HỆ ĐIỀU HÀNH

- **Môn học:** Chuyên đề Kỹ thuật Phần mềm (CSE408)
- **Đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
- **Sinh viên thực hiện:** Phùng Văn Duy – MSSV: 2352270589
- **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
- **Học kỳ / Năm học:** HK7, Năm học 2026-2027

---

## 📑 Mục Lục
1. [Mục tiêu bài thực hành Tuần 6](#1-mục-tiêu-bài-thực-hành-tuần-6)
2. [Cơ sở lý thuyết & Khung lệnh cốt lõi của Ansible](#2-cơ-sở-lý-thuyết--khung-lệnh-cốt-lõi-của-ansible)
   - 2.1. Bản chất kiến trúc không phần mềm đại lý (Agentless Architecture)
   - 2.2. Phân biệt `ping` mạng thông thường vs `ansible -m ping`
   - 2.3. Tư duy khai báo (Declarative) & Tính nhất quán (Idempotency)
   - 2.4. Khung xương 5 từ khóa cốt lõi của một Playbook YAML
   - 2.5. Bảng 7 khối lệnh (Modules) thông dụng nhất trong thực tế
   - 2.6. Tối ưu mã nguồn với vòng lặp `loop` và biến nội suy `{{ item }}`
   - 2.7. Hai câu lệnh dòng lệnh (CLI) bắt buộc phải nhớ
3. [Kiến trúc cụm máy chủ mục tiêu](#3-kiến-trúc-cụm-máy-chủ-mục-tiêu)
4. [Cấu trúc thư mục bài thực hành](#4-cấu-trúc-thư-mục-bài-thực-hành)
5. [Hướng dẫn thực hành từng bước chi tiết](#5-hướng-dẫn-thực-hành-từng-bước-chi-tiết)
   - Bước 0: Chuẩn bị máy ảo và giải mã khóa SSH vào Keychain
   - Bước 1: Kiểm tra kết nối cụm máy chủ với Ansible Ping
   - Bước 2: Kiểm tra tính đúng đắn của cú pháp Playbook
   - Bước 3: Thực thi kịch bản lần 1 (Áp dụng cấu hình chuẩn)
   - Bước 4: Kiểm nghiệm tính nhất quán (Idempotency - Lần 2)
   - Bước 5: Xác minh trạng thái tường lửa trực tiếp trên máy chủ
6. [Sử dụng các kịch bản tự động hóa có sẵn](#6-sử-dụng-các-kịch-bản-tự-động-hóa-có-sẵn)

---

## 1. Mục tiêu bài thực hành Tuần 6

Sau khi hoàn thành việc cấp phát tài nguyên và tự động xuất bản tệp danh mục máy chủ `inventory.ini` từ Terraform ở Tuần 4 và Tuần 5, bài thực hành Tuần 6 chính thức mở đầu cho giai đoạn **Quản lý cấu hình tự động (Configuration Management)** bằng công cụ **Ansible**:

1. **Hiểu rõ kiến trúc không phần mềm đại lý (Agentless Architecture):** Khám phá cách Ansible điều khiển các máy chủ từ xa thông qua giao thức SSH có sẵn và trình thông dịch Python 3 mà không cần cài đặt daemon chạy nền.
2. **Kiểm tra thông suốt kết nối cụm máy chủ:** Sử dụng lệnh Ad-hoc với mô-đun `ping` để xác thực kết nối đồng thời tới cả 2 máy chủ (`prod-vm` và `db-server`) với 2 tài khoản quản trị và 2 khóa bảo mật độc lập (`ubuntu` và `user-db`).
3. **Thiết kế kịch bản Playbook chuẩn hóa hệ điều hành (`setup-os.yml`):**
   * **Chung cho toàn cụm (`cluster`):** Cập nhật kho gói `apt`, thiết lập múi giờ `Asia/Ho_Chi_Minh`, cài đặt các gói công cụ quản trị (`curl`, `wget`, `htop`, `net-tools`, `ca-certificates`, `gnupg`, `ufw`), thiết lập chính sách mặc định chặn toàn bộ cổng vào (Deny Incoming) và luôn mở cổng SSH 22.
   * **Riêng cho máy chủ ứng dụng (`app_servers`):** Mở thêm cổng HTTP (80) và HTTPS (443) để sẵn sàng phục vụ Web/Nginx.
   * **Riêng cho máy chủ cơ sở dữ liệu (`db_servers`):** Thiết lập luật tường lửa nghiêm ngặt: cổng MongoDB 27017 **chỉ cho phép kết nối từ địa chỉ IP của máy chủ ứng dụng `192.168.252.4`**, ngăn chặn hoàn toàn truy cập trái phép từ bên ngoài.
4. **Kiểm nghiệm tính nhất quán (Idempotency) của Ansible:** Đo lường trạng thái thay đổi khi chạy lần 1 (`changed > 0`) và lần 2 (`changed = 0`), chứng minh thời gian thực thi được tối ưu vượt bậc khi hạ tầng đã đạt chuẩn.

---

## 2. Cơ sở lý thuyết & Khung lệnh cốt lõi của Ansible

### 2.1. Bản chất kiến trúc không phần mềm đại lý (Agentless Architecture)

Khác với các công cụ quản lý cấu hình thế hệ cũ (như Puppet hay Chef bắt buộc phải cài agent thường trực trên từng máy con làm tốn RAM/CPU), **Ansible hoạt động hoàn toàn không cần agent (Agentless)**:
* **Máy điều khiển (Control Node - macOS):** Cài đặt Ansible CLI (Python 3).
* **Máy đích (Managed Nodes - Ubuntu):** Chỉ cần có sẵn dịch vụ **OpenSSH Server** và trình thông dịch **Python 3**.
* **Nguyên lý thực thi:** Khi chạy, Ansible biên dịch các khối tác vụ (task) thành các đoạn mã Python ngắn, đẩy qua kênh SSH, thực thi trực tiếp trên máy chủ đích với quyền `sudo`, nhận kết quả JSON trả về và **tự động xóa sạch các file tạm ngay sau khi chạy xong**.

---

### 2.2. Phân biệt `ping` mạng thông thường vs `ansible -m ping`

| Tiêu chí | `ping` mạng (`ping 192.168.x.x`) | `ansible -m ping` (Mô-đun Ansible) |
| :--- | :--- | :--- |
| **Giao thức** | Giao thức mạng ICMP | **Giao thức SSH (Cổng 22)** |
| **Phạm vi kiểm tra** | Chỉ kiểm tra thông mạch đường truyền mạng IP. | Kiểm tra **toàn bộ chuỗi xác thực, quyền SSH, khóa bảo mật và môi trường Python 3** trên máy chủ đích. |
| **Kết quả trả về** | `64 bytes from ...` | Trả về chuỗi JSON: **`"ping": "pong"`** |

> **Ý nghĩa thực tế:** Đây là bước kiểm tra điều kiện tiên quyết (**Pre-flight Check**) bắt buộc. Nếu `ansible -m ping` thành công, bạn chắc chắn 100% kịch bản Playbook sau đó sẽ kết nối và thực thi mượt mà.

---

### 2.3. Tư duy khai báo (Declarative) & Tính nhất quán (Idempotency)

* **Tư duy mệnh lệnh (Imperative - Shell script truyền thống):** *"Hãy chạy lệnh `apt install nginx`"*. Nếu chạy lại lần 2, script vẫn cố chạy lại lệnh đó hoặc báo lỗi nếu không kiểm tra kĩ `if/else`.
* **Tư duy khai báo (Declarative - Cách tiếp cận của Ansible):** Bạn chỉ **mô tả trạng thái đích mong muốn**:
  * `state: present` = Tôi muốn gói này **phải có mặt** (nếu chưa có thì cài, có rồi thì bỏ qua).
  * `state: absent` = Tôi muốn đối tượng này **bị gỡ bỏ / xóa sổ**.
  * `state: started` = Tôi muốn dịch vụ này **đang chạy**.
* **Tính nhất quán (Idempotency):** Một kịch bản Ansible dù chạy 1 lần hay 100 lần trên cùng một máy chủ thì kết quả cuối cùng vẫn như nhau: không sinh thêm tài nguyên thừa, không làm thay đổi cấu hình nếu hệ thống đã đạt chuẩn (`changed=0`).

---

### 2.4. Khung xương 5 từ khóa cốt lõi của một Playbook YAML

Một tệp kịch bản Ansible (Playbook) được ví như một **vở kịch**, gồm nhiều **cảnh diễn (Play)** và các **hành động cụ thể (Tasks)**. Mọi Playbook đều tuân theo khung xương 5 từ khóa sau:

```yaml
---
- name: "1. Vở kịch này làm cái gì?"              # [name] Mục đích tổng quát của Play
  hosts: app_servers                             # [hosts] Đối tượng máy chủ đích nhận tác vụ
  become: true                                   # [become] Có nâng quyền quản trị (sudo root) không?
  
  tasks:                                         # [tasks] Danh sách các hành động tuần tự:
    - name: "Tác vụ 1: Cài đặt phần mềm Nginx"   #   - Mô tả tác vụ cụ thể
      ansible.builtin.apt:                       #   - Mô-đun (công cụ) chuyên dụng thực thi
        name: nginx                              #   - Tham số tên gói
        state: present                           #   - Trạng thái mong muốn: ĐÃ ĐƯỢC CÀI
```

---

### 2.5. Bảng 7 khối lệnh (Modules) thông dụng nhất trong thực tế

Nắm vững 7 khối lệnh chuẩn này giúp bạn làm chủ được **90% các tác vụ quản trị hệ thống Linux**:

| Khối lệnh (Module) | Tương đương lệnh Linux nào? | Ý nghĩa & Tham số chính |
| :--- | :--- | :--- |
| **`ansible.builtin.apt`** | `apt update`, `apt install` | Cài đặt / gỡ gói: `name`, `state: present/absent`, `update_cache` |
| **`community.general.timezone`** | `timedatectl set-timezone` | Thiết lập múi giờ hệ thống: `name: Asia/Ho_Chi_Minh` |
| **`community.general.ufw`** | `ufw allow/deny/enable` | Quản lý tường lửa: `port`, `proto`, `rule`, `direction`, `policy` |
| **`ansible.builtin.systemd`** | `systemctl start/enable` | Điều khiển dịch vụ: `name`, `state: started`, `enabled: true` |
| **`ansible.builtin.copy`** | `scp`, `cp` | Sao chép tệp từ máy Mac lên máy chủ: `src`, `dest`, `mode` |
| **`ansible.builtin.file`** | `mkdir`, `chmod`, `chown` | Quản lý tệp/thư mục: `path`, `state: directory`, `mode: '0755'` |
| **`ansible.builtin.command`** | Gõ lệnh trực tiếp trên bash | Chạy lệnh thô khi không có module chuyên dụng có sẵn |

---

### 2.6. Tối ưu mã nguồn với vòng lặp `loop` và biến nội suy `{{ item }}`

Thay vì viết lặp đi lặp lại nhiều task giống nhau để cài từng phần mềm, Ansible hỗ trợ từ khóa **`loop`**:

```yaml
    - name: Cài đặt nhiều công cụ quản trị cùng lúc
      ansible.builtin.apt:
        name: "{{ item }}"
        state: present
      loop:
        - curl
        - wget
        - git
        - htop
        - net-tools
```
*(Ansible sẽ tự động duyệt từng phần tử trong danh sách `loop` và gán vào biến giữ chỗ `{{ item }}`).*

---

### 2.7. Hai câu lệnh dòng lệnh (CLI) bắt buộc phải nhớ

1. **Lệnh Ad-hoc (`ansible`):** Dùng để chạy nhanh **một tác vụ duy nhất** trên nhiều máy cùng lúc mà không cần viết file YAML:
   ```bash
   ansible -i inventory.ini <tên_nhóm> -m <tên_module>
   # Ví dụ:
   ansible -i inventory.ini cluster -m ping
   ```
2. **Lệnh Playbook (`ansible-playbook`):** Dùng để thực thi toàn bộ kịch bản cấu hình hoàn chỉnh từ tệp YAML:
   ```bash
   ansible-playbook -i inventory.ini <đường_dẫn_playbook.yml>
   # Ví dụ:
   ansible-playbook -i inventory.ini playbooks/setup-os.yml
   ```
   *(Thêm cờ `--syntax-check` để kiểm tra lỗi cú pháp/khoảng trắng YAML trước khi chạy).*

---

## 3. Kiến trúc cụm máy chủ mục tiêu

```text
+-----------------------------------------------------------------------------------+
|                      MÁY ĐIỀU KHIỂN TRUNG TÂM TRÊN MACOS                          |
|                  Công cụ: ansible, ansible-playbook (Python 3)                    |
|             Tệp danh mục máy chủ: inventory.ini | Tệp cấu hình: ansible.cfg       |
+-----------------------------------------+-----------------------------------------+
                                          |
        +---------------------------------+---------------------------------+
        | (Kênh SSH - Khóa github_deploy_key)                               | (Kênh SSH - Khóa db-server-key)
        v                                                                   v
+-----------------------------------------+       +-----------------------------------------+
|     MÁY CHỦ 1: prod-vm (192.168.252.4)  |       |    MÁY CHỦ 2: db-server (192.168.252.5)|
|       Tài khoản quản trị: ubuntu        |       |      Tài khoản quản trị: user-db        |
+-----------------------------------------+       +-----------------------------------------+
| - Nhận mô-đun Python qua SSH            |       | - Nhận mô-đun Python qua SSH            |
| - Quyền sudo: NOPASSWD                  |       | - Quyền sudo: NOPASSWD                  |
| - Cổng mở UFW: 22 (SSH), 80, 443        |       | - Cổng mở UFW: 22 (SSH), 27017 (Nội bộ) |
| - Múi giờ: Asia/Ho_Chi_Minh             |       | - Múi giờ: Asia/Ho_Chi_Minh             |
+-----------------------------------------+       +-----------------------------------------+
                    |                                                   ^
                    +--- [Chỉ cho phép truy vấn MongoDB cổng 27017] ---+
```

---

## 4. Cấu trúc thư mục bài thực hành

```text
labs/week06-ansible/
├── ansible.cfg                 # Cấu hình hành vi Ansible (tự động sudo, tắt host key check)
├── inventory.ini               # Danh mục cụm máy chủ và chỉ định khóa SSH riêng từng máy
├── README.md                   # Tài liệu hướng dẫn lý thuyết và thực hành chi tiết Tuần 6
├── playbooks/
│   └── setup-os.yml            # Kịch bản Playbook chuẩn hóa và bảo mật hệ điều hành
└── scripts/
    ├── run_ping.sh             # Kịch bản kiểm tra kết nối Ad-hoc ping tới toàn cụm
    ├── run_playbook.sh         # Kịch bản kiểm tra cú pháp và thực thi setup-os.yml
    └── test_idempotency.sh     # Kịch bản đo lường tính nhất quán (so sánh thời gian lần 1 vs 2)
```

---

## 5. Hướng dẫn thực hành từng bước chi tiết

### Yêu cầu tiên quyết
Đảm bảo máy tính đã cài đặt Ansible trên macOS:
```bash
brew install ansible
ansible --version
```

Di chuyển vào thư mục bài thực hành:
```bash
cd labs/week06-ansible
```

---

### Bước 0: Chuẩn bị máy ảo và giải mã khóa SSH vào Keychain

1. **Khởi động 2 máy chủ ảo Multipass:**
   ```bash
   multipass start prod-vm db-server
   multipass list
   ```
   *(Đảm bảo cả 2 máy đều ở trạng thái `Running` và có địa chỉ IP `192.168.252.4`, `192.168.252.5`).*

2. **Giải mã khóa `github_deploy_key` vào macOS Keychain:**
   Vì khóa `~/.ssh/github_deploy_key` có đặt mật khẩu bảo vệ (Passphrase), trong khi Ansible là công cụ chạy tự động không thể dừng lại chờ bạn gõ mật khẩu, hãy nạp khóa vào Keychain của macOS **1 lần duy nhất**:
   ```bash
   ssh-add --apple-use-keychain ~/.ssh/github_deploy_key
   ```
   *(Nhập mật khẩu khóa của bạn. Sau bước này, macOS sẽ tự động giải mã khóa cho Ansible mà không bao giờ bị lỗi `Permission denied` nữa).*

---

### Bước 1: Kiểm tra kết nối cụm máy chủ với Ansible Ping

Sử dụng lệnh Ad-hoc để xác nhận thông suốt đường truyền SSH và khả năng thực thi Python 3 trên cả 2 máy:

```bash
ansible -i inventory.ini cluster -m ping
```

*Kết quả mong đợi:*
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

---

### Bước 2: Kiểm tra tính đúng đắn của cú pháp Playbook

Kiểm tra tính hợp lệ của tệp YAML trước khi chạy:

```bash
ansible-playbook -i inventory.ini playbooks/setup-os.yml --syntax-check
```

*Kết quả:* Không có lỗi cú pháp (`playbook: playbooks/setup-os.yml`).

---

### Bước 3: Thực thi kịch bản lần 1 (Áp dụng cấu hình chuẩn)

Tiến hành cài đặt gói công cụ, chỉnh múi giờ và cấu hình tường lửa UFW:

```bash
ansible-playbook -i inventory.ini playbooks/setup-os.yml
```

*Quan sát kết quả (PLAY RECAP):*
```text
PLAY RECAP *********************************************************************
prod-vm   : ok=8    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
db-server : ok=8    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Chỉ số `changed=5` phản ánh các thay đổi vừa được áp dụng thành công lên từng máy chủ.

---

### Bước 4: Kiểm nghiệm tính nhất quán (Idempotency - Lần 2)

Chạy lại chính xác câu lệnh Playbook lần thứ hai:

```bash
ansible-playbook -i inventory.ini playbooks/setup-os.yml
```

*Quan sát kết quả (PLAY RECAP):*
```text
PLAY RECAP *********************************************************************
prod-vm   : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
db-server : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
* **Nhận xét quan trọng:** `changed=0` chứng minh Ansible tự động kiểm tra và nhận thấy hệ thống đã đạt đúng trạng thái mong muốn, không ghi đè thừa, thời gian chạy giảm từ ~40 giây xuống chỉ còn ~4 giây!

---

### Bước 5: Xác minh trạng thái tường lửa trực tiếp trên máy chủ

Kiểm tra trực tiếp kết quả các luật UFW trên từng máy qua SSH:

```bash
# 1. Kiểm tra máy chủ ứng dụng prod-vm (Mở cổng 22, 80, 443):
ssh prod-vm "sudo ufw status verbose"

# 2. Kiểm tra máy chủ cơ sở dữ liệu db-server (Cổng 27017 chỉ mở cho 192.168.252.4):
ssh db-server "sudo ufw status verbose"
```

---

## 6. Sử dụng các kịch bản tự động hóa có sẵn

Bạn có thể chạy nhanh các kịch bản kiểm nghiệm chuẩn bị sẵn trong thư mục `scripts/`:

```bash
# 1. Kiểm tra kết nối nhanh tới toàn cụm:
./scripts/run_ping.sh

# 2. Chạy Playbook chuẩn hóa hệ điều hành:
./scripts/run_playbook.sh

# 3. Chạy đo lường tính nhất quán (so sánh thời gian lần 1 và lần 2):
./scripts/test_idempotency.sh
```
