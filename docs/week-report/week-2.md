# BÁO CÁO TIẾN ĐỘ TUẦN 2

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 2:** Ứng dụng mẫu và Đóng gói Container với Docker

---

## 1. Thiết kế ứng dụng mẫu và giao diện lập trình REST API
* **Mục đích của ứng dụng mẫu:** Đóng vai trò là đối tượng ứng dụng mục tiêu trong chuỗi cung ứng phần mềm tự động hóa, cần có kết nối cơ sở dữ liệu và đầy đủ các thao tác xử lý dữ liệu để mô phỏng chính xác môi trường thực tế.
* **Lựa chọn công nghệ:** Xây dựng dịch vụ backend bằng Node.js kết hợp Express, kết nối hệ quản trị cơ sở dữ liệu MongoDB hoặc PostgreSQL.
* **Cấu trúc phân lớp:** Mã nguồn được tổ chức tách biệt giữa tầng định tuyến nhận yêu cầu mạng, tầng điều khiển xử lý logic nghiệp vụ và tầng mô hình tương tác cơ sở dữ liệu, quản lý cấu hình thông qua các biến môi trường an toàn.

---

## 2. Cơ chế kiểm tra trạng thái hoạt động và thu thập chỉ số giám sát
* **Điểm kiểm tra sức khỏe `/healthz`:**
  * Cung cấp cơ chế xác định tức thời xem ứng dụng còn sống và có sẵn sàng tiếp nhận yêu cầu hay không.
  * Tự động kiểm tra đồng thời tình trạng kết nối tới cơ sở dữ liệu; nếu kết nối cơ sở dữ liệu gặp sự cố, điểm kiểm tra sẽ phản hồi mã lỗi để các hệ thống điều phối phía trên nhận biết và xử lý kịp thời.
* **Điểm thu thập chỉ số giám sát `/metrics`:**
  * Xuất các thông số hoạt động của hệ thống theo thời gian thực bao gồm lượng tiêu thụ bộ nhớ, thời gian hoạt động của tiến trình và tổng số lượng yêu cầu mạng đã tiếp nhận.
  * Phục vụ tích hợp tự động với các công cụ theo dõi hiệu năng hệ thống trong các giai đoạn tiếp theo.

---

## 3. Kỹ thuật đóng gói nhiều giai đoạn với Docker
* **Hạn chế của phương pháp đóng gói một giai đoạn truyền thống:**
  * Gộp chung toàn bộ mã nguồn thô, công cụ biên dịch, môi trường phát triển và tệp tạm vào gói ảnh cuối cùng.
  * Kích thước gói ảnh bị phình to (thường từ 800 MB đến hơn 1 GB), gây tốn không gian đĩa cứng, kéo dài thời gian tải về trên mạng và làm tăng diện tích bề mặt tấn công do tồn tại nhiều thư viện thừa.
* **Bản chất của kỹ thuật đóng gói nhiều giai đoạn:**
  * **Giai đoạn biên dịch:** Sử dụng gói ảnh đầy đủ công cụ để cài đặt các gói phụ thuộc và biên dịch mã nguồn ứng dụng.
  * **Giai đoạn thực thi:** Khởi tạo một gói ảnh hoàn toàn mới chỉ chứa môi trường chạy tối giản, sau đó chỉ sao chép các tệp thành phẩm đã biên dịch từ giai đoạn trước sang.
  * Toàn bộ mã nguồn tạm, công cụ biên dịch và tệp không cần thiết đều bị loại bỏ hoàn toàn khỏi gói ảnh chạy ngoài thực tế.

---

## 4. Lựa chọn gói ảnh nền tối ưu và an toàn
* **Đặc tính của nền tảng Alpine Linux:** Sử dụng hệ điều hành tối giản với kích thước ban đầu chỉ khoảng 5 MB, thay thế thư viện tiêu chuẩn bằng thư viện rút gọn `musl libc` và bộ công cụ rút gọn `BusyBox`.
* **Hiệu quả tối ưu đạt được:**
  * Kích thước gói ảnh ứng dụng giảm sâu từ ~900 MB xuống chỉ còn ~95 MB (tiết kiệm gần 90% dung lượng).
  * Giảm thiểu đáng kể số lượng lỗ hổng bảo mật tiềm ẩn do không chứa các trình tiện ích thừa thãi.
  * Tăng tốc độ đẩy gói ảnh lên kho lưu trữ và kéo về máy chủ triển khai trong đường ống CI/CD.

---

## 5. Điều phối hệ thống và lưu trữ dữ liệu bền vững với Docker Compose
* **Điều phối đa dịch vụ:** Sử dụng tệp cấu hình `docker-compose.yml` để định nghĩa và khởi chạy đồng thời cả dịch vụ backend và dịch vụ cơ sở dữ liệu chỉ với một câu lệnh duy nhất.
* **Mạng nội bộ cô lập:** Docker Compose tự động thiết lập một mạng ảo riêng biệt, cho phép ứng dụng backend kết nối trực tiếp với cơ sở dữ liệu thông qua tên dịch vụ nội bộ mà không cần mở cổng cơ sở dữ liệu ra ngoài Internet, đảm bảo an toàn thông tin.
* **Cơ chế lưu trữ dữ liệu lâu dài:** Sử dụng cơ chế gắn ổ đĩa dữ liệu của Docker gắn vào thư mục chứa dữ liệu của cơ sở dữ liệu, đảm bảo toàn bộ dữ liệu người dùng không bị xóa mất khi container ứng dụng bị tắt hoặc khởi động lại.

---

## 6. Đo lường so sánh kích thước gói ảnh thực nghiệm

| Tiêu chí so sánh | Đóng gói một giai đoạn thông thường | Đóng gói nhiều giai đoạn trên Alpine Linux | Mức độ cải thiện |
| :--- | :--- | :--- | :--- |
| **Gói ảnh nền sử dụng** | `node:20` (nền Debian đầy đủ) | `node:20-alpine` (nền Alpine tối giản) | Rút gọn hệ điều hành nền |
| **Dung lượng gói ảnh khi giải nén** | **1.58 GB** | **201 MB** | Giảm **87.3%** |
| **Dung lượng gói ảnh khi nén** | **391 MB** | **49.9 MB** | Giảm **87.2%** |
| **Số lượng gói phần mềm hệ thống** | Đầy đủ công cụ biên dịch và tiện ích | Chỉ giữ lại thành phần chạy tối thiểu | Giảm diện tích tấn công |
| **Thời gian truyền tải qua mạng** | ~ 40 – 60 giây | ~ 3 – 5 giây | Tối ưu hóa chu trình CI/CD |

---

## 7. Tìm hiểu và thực hành các lệnh Docker cơ bản trong quản trị container

Bên cạnh việc xây dựng tệp `Dockerfile` và tệp cấu hình `docker-compose.yml`, quá trình quản trị, vận hành và giám sát ứng dụng container hóa đòi hỏi phải làm chủ các lệnh Docker cơ bản nhằm phục vụ việc kiểm tra trạng thái, khắc phục sự cố và điều phối dịch vụ. Dưới đây là phân tích chi tiết và thực nghiệm 5 câu lệnh trọng tâm:

### 7.1. Lệnh `docker start` – Khởi động lại container đã tồn tại
* **Mục đích:** Kích hoạt và chạy một hoặc nhiều container đã ở trạng thái dừng (`Exited`) mà không cần tạo mới hay cấu hình lại từ đầu, giữ nguyên toàn bộ trạng thái dữ liệu, biến môi trường và liên kết mạng đã gán trước đó.
* **Cú pháp cơ bản:**
  ```bash
  docker start [OPTIONS] CONTAINER [CONTAINER...]
  ```
* **Cờ thường dùng:**
  * `-a` (`--attach`): Đính kèm luồng xuất chuẩn (`stdout`/`stderr`) của container vào terminal hiện tại.
  * `-i` (`--interactive`): Mở chế độ tương tác chuẩn (`stdin`).
* **Áp dụng thực tế cho dự án:**
  ```bash
  # Khởi động lại container dịch vụ cơ sở dữ liệu sau khi tạm dừng
  docker start cse408-postgres-db

  # Khởi động lại container ứng dụng backend
  docker start cse408-app-backend
  ```
* **Ý nghĩa thực tiễn:** Giúp phục hồi nhanh chóng dịch vụ sau khi bảo trì hoặc tạm ngắt mà không làm thay đổi ID container hay làm phát sinh các tài nguyên rác.

---

### 7.2. Lệnh `docker top` – Giám sát tiến trình bên trong container
* **Mục đích:** Hiển thị danh sách các tiến trình (processes) đang chạy thời gian thực bên trong container, bao gồm thông tin định danh tiến trình trên máy chủ (Host PID), định danh tiến trình trong container (PID), tài khoản thực thi (User), và câu lệnh đang chạy (Command).
* **Cú pháp cơ bản:**
  ```bash
  docker top CONTAINER [ps OPTIONS]
  ```
* **Áp dụng thực tế cho dự án:**
  ```bash
  # Kiểm tra các tiến trình Node.js đang hoạt động trong container ứng dụng backend
  docker top cse408-app-backend

  # Kiểm tra các tiến trình nền của PostgreSQL
  docker top cse408-postgres-db
  ```
* **Ý nghĩa thực tiễn:** Cho phép kỹ sư quản trị kiểm tra tức thời ứng dụng có bị treo, xuất hiện tiến trình lạ hay chiếm dụng tài nguyên bất thường mà không cần truy cập vào bên trong container.

---

### 7.3. Lệnh `docker compose` – Quản lý và điều phối ứng dụng đa container
* **Mục đích:** Công cụ điều phối mạnh mẽ giúp định nghĩa, khởi chạy và quản lý vòng đời của nhiều container liên kết với nhau (Backend + Database) thông qua tệp cấu hình khai báo duy nhất `docker-compose.yml`.
* **Cú pháp và các lệnh con cốt lõi:**
  ```bash
  docker compose [COMMAND] [OPTIONS]
  ```
  * `docker compose up -d`: Tạo mạng ảo, ổ đĩa lưu trữ và khởi chạy toàn bộ dịch vụ ở chế độ chạy ngầm.
  * `docker compose down`: Dừng và gỡ bỏ toàn bộ container, mạng nội bộ; bổ sung cờ `-v` để xóa kèm ổ đĩa dữ liệu.
  * `docker compose ps`: Liệt kê trạng thái hiện thời của các dịch vụ trong cụm (Running, Exited, Port mapping).
  * `docker compose build`: Biên dịch lại các gói ảnh dịch vụ khi có thay đổi mã nguồn hoặc Dockerfile.
  * `docker compose restart`: Khởi động lại toàn bộ dịch vụ trong cụm mà không cần tạo lại cấu hình mạng.
* **Áp dụng thực tế cho dự án:**
  ```bash
  # Khởi dựng toàn bộ cụm gồm Node.js App và PostgreSQL
  docker compose up -d --build

  # Kiểm tra trạng thái toàn bộ dịch vụ trong cụm
  docker compose ps
  ```
* **Ý nghĩa thực tiễn:** Chuẩn hóa quy trình triển khai hạ tầng nhất quán giữa môi trường máy trạm phát triển và máy chủ kiểm thử/vận hành, hỗ trợ khởi tạo hoặc dọn dẹp cụm hạ tầng chỉ bằng một câu lệnh duy nhất.

---

### 7.4. Lệnh `docker logs` – Kiểm tra và truy vết nhật ký hoạt động
* **Mục đích:** Truy xuất và hiển thị toàn bộ luồng đầu ra tiêu chuẩn (`stdout`) và luồng cảnh báo/lỗi tiêu chuẩn (`stderr`) được phát ra bởi tiến trình đang chạy bên trong container.
* **Cú pháp cơ bản:**
  ```bash
  docker logs [OPTIONS] CONTAINER
  ```
* **Cờ thường dùng:**
  * `-f` (`--follow`): Theo dõi và cập nhật nhật ký liên tục theo thời gian thực (tương tự lệnh `tail -f` trong Linux).
  * `--tail [N]`: Chỉ lấy ra $N$ dòng nhật ký gần đây nhất (ví dụ: `--tail 50`).
  * `-t` (`--timestamps`): Bổ sung mốc thời gian chi tiết cho từng dòng thông báo.
  * `--since [TIME]`: Lọc thông báo từ một khoảng thời gian cụ thể (ví dụ: `--since 10m`).
* **Áp dụng thực tế cho dự án:**
  ```bash
  # Theo dõi nhật ký thời gian thực của ứng dụng Express khi nhận request
  docker logs -f --tail 100 cse408-app-backend

  # Kiểm tra nhật ký khởi tạo cơ sở dữ liệu PostgreSQL
  docker logs cse408-postgres-db
  ```
* **Ý nghĩa thực tiễn:** Là công cụ quan trọng nhất để điều tra lỗi ứng dụng, kiểm tra vết lỗi kết nối cơ sở dữ liệu và giám sát tình trạng hoạt động của container khi gặp sự cố crash.

---

### 7.5. Lệnh `docker exec` – Thực thi câu lệnh trực tiếp bên trong container
* **Mục đích:** Chạy một câu lệnh bổ sung hoặc mở một phiên làm việc dòng lệnh tương tác (interactive shell) trực tiếp bên trong một container đang hoạt động mà không làm gián đoạn tiến trình chính (PID 1).
* **Cú pháp cơ bản:**
  ```bash
  docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
  ```
* **Cờ thường dùng:**
  * `-i` (`--interactive`): Giữ kết nối luồng nhập chuẩn (stdin) ngay cả khi không gắn terminal.
  * `-t` (`--tty`): Cấp phát một thiết bị đầu cuối ảo (pseudo-TTY).
  * `-u` (`--user`): Chỉ định tài khoản người dùng thực thi câu lệnh (ví dụ: `root` hoặc `node`).
  * `-w` (`--workdir`): Chỉ định thư mục làm việc khi thực thi lệnh.
* **Áp dụng thực tế cho dự án:**
  ```bash
  # Mở phiên dòng lệnh tương tác (sh) vào bên trong container Node.js (Alpine)
  docker exec -it cse408-app-backend sh

  # Kiểm tra biến môi trường bên trong container
  docker exec -it cse408-app-backend env

  # Truy cập trực tiếp vào giao diện dòng lệnh psql của PostgreSQL
  docker exec -it cse408-postgres-db psql -U postgres -d cse408_db
  ```
* **Ý nghĩa thực tiễn:** Hỗ trợ xử lý sự cố trực tiếp (debugging), kiểm tra cấu trúc tệp nội bộ, kiểm tra biến môi trường và chạy các tập lệnh quản trị cơ sở dữ liệu (migration, seeding) mà không cần cài đặt thêm công cụ client lên máy chủ vật lý.
