# BÁO CÁO TIẾN ĐỘ TUẦN 2

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 2:** Nghiên cứu chuyên sâu về công nghệ Container và làm chủ công cụ Docker

---

## 1. Tổng quan về công nghệ Container và kiến trúc Docker Engine

### 1.1. Bản chất công nghệ đóng gói Container (Containerization)
* **So sánh Containerization và Virtualization truyền thống:**
  * **Máy ảo (Virtual Machines - VM):** Hoạt động dựa trên tầng ảo hóa phần cứng (*Hypervisor Type 1 hoặc Type 2*). Mỗi máy ảo bắt buộc phải cài đặt một hệ điều hành khách riêng biệt (*Guest OS*), dẫn đến việc tiêu tốn hàng GB dung lượng đĩa cứng, chiếm dụng bộ nhớ RAM cố định và thời gian khởi động kéo dài từ vài chục giây đến vài phút.
  * **Container:** Ảo hóa ở cấp độ hệ điều hành (*OS-level virtualization*), dùng chung nhân (*Shared OS Kernel*) của máy chủ chủ quản (*Host OS*). Các container được cô lập hoàn toàn với nhau thông qua hai tính năng cốt lõi của nhân Linux:
    * **Namespaces:** Cô lập tài nguyên không gian tên (PID - tiến trình, NET - mạng, MNT - điểm gắn hệ thống tệp, IPC - liên lạc tiến trình, UTS - tên máy chủ).
    * **Control Groups (cgroups):** Giới hạn và đo lường mức độ tiêu thụ tài nguyên phần cứng (CPU, RAM, I/O băng thông) của từng container.
  * **Ưu thế vượt trội:** Dung lượng siêu nhỏ (vài chục MB), khởi động tức thì trong phần trăm giây và mật độ triển khai cao gấp nhiều lần so với máy ảo.

### 1.2. Kiến trúc Docker Engine (Mô hình Client - Server)
* **Docker Client (`docker` CLI):** Công cụ dòng lệnh tiếp nhận thao tác của người dùng và gửi các lệnh điều khiển thông qua REST API tới máy chủ Docker.
* **Docker Daemon (`dockerd`):** Tiến trình dịch vụ chạy nền trên máy chủ, chịu trách nhiệm lắng nghe yêu cầu API và trực tiếp quản lý toàn bộ các đối tượng Docker: Gói ảnh (*Images*), Hộp chứa (*Containers*), Mạng (*Networks*) và Ổ đĩa (*Volumes*).
* **Docker Registry:** Hệ thống kho lưu trữ và phân phối Docker Image (như Docker Hub, GitHub Packages hoặc Private Registry của doanh nghiệp).
* **Vòng đời của một Container (Container Lifecycle):**
  * `Created`: Container vừa được khởi tạo từ image nhưng chưa kích hoạt tiến trình.
  * `Running`: Tiến trình chính (PID 1) đang hoạt động bình thường.
  * `Paused`: Đóng băng tạm thời trạng thái các tiến trình trong container.
  * `Stopped / Exited`: Tiến trình chính đã kết thúc hoặc nhận tín hiệu dừng.
  * `Destroyed`: Container bị xóa bỏ hoàn toàn khỏi bộ lưu trữ của Docker.

---

## 2. Cơ chế đóng gói gói ảnh và các chỉ thị Dockerfile cốt lõi

### 2.1. Cấu trúc tầng (Layered File System) của Docker Image
* Docker Image là một mẫu chỉ đọc (*Read-only Template*), được xây dựng từ nhiều tầng dữ liệu xếp chồng lên nhau thông qua hệ thống tệp hợp nhất (*Union File System - Overlay2*).
* Mỗi câu lệnh trong tệp `Dockerfile` tạo ra một tầng chỉ đọc mới. Khi khởi chạy một container, Docker chỉ gắn thêm một tầng ghi mỏng (*Thin R/W Container Layer*) lên trên cùng. Mọi thao tác thêm, sửa, xóa tệp của ứng dụng chỉ diễn ra trên tầng ghi tạm thời này (*Copy-on-Write*).

### 2.2. Các chỉ thị Dockerfile cốt lõi
* `FROM`: Định nghĩa gói ảnh nền (*Base Image*) làm gốc cho tiến trình đóng gói.
* `WORKDIR`: Khởi tạo và thiết lập thư mục làm việc mặc định cho tất cả các chỉ thị tiếp theo.
* `COPY` / `ADD`: Sao chép tệp từ máy chủ phát triển vào hệ thống tệp của container. Ưu tiên sử dụng `COPY` vì tính minh bạch và an toàn.
* `RUN`: Thực thi các câu lệnh cài đặt thư viện hoặc biên dịch mã nguồn trong quá trình xây dựng image (tạo ra layer mới).
* `ENV`: Thiết lập các biến môi trường hoạt động trong cả quá trình build và runtime.
* `EXPOSE`: Khai báo cổng mạng mà ứng dụng lắng nghe bên trong container (mang tính tài liệu hóa cấu hình mạng).
* `ENTRYPOINT` & `CMD`:
  * `ENTRYPOINT`: Định nghĩa lệnh thực thi cố định không thể bị ghi đè mặc định khi container chạy.
  * `CMD`: Cung cấp tham số mặc định cho `ENTRYPOINT` hoặc lệnh chạy mặc định có thể bị ghi đè dễ dàng từ dòng lệnh `docker run`.

### 2.3. Cơ chế bộ nhớ đệm (Build Cache) và tối ưu hóa thứ tự chỉ thị
* Docker kiểm tra xem câu lệnh và các tệp liên quan có thay đổi so với lần build trước hay không. Nếu không, Docker sẽ tái sử dụng lại layer cũ từ cache.
* **Nguyên tắc tối ưu:** Luôn đặt các chỉ thị ít thay đổi (cài đặt gói hệ điều hành, cài đặt dependencies `package.json`) lên trước và chỉ thị chứa mã nguồn nghiệp vụ thường xuyên thay đổi xuống cuối. Điều này giúp rút ngắn thời gian build từ vài phút xuống chỉ còn vài giây.

---

## 3. Kỹ thuật tối ưu hóa gói ảnh: Đóng gói nhiều giai đoạn và nền tảng Alpine Linux

### 3.1. Hạn chế của phương pháp đóng gói một giai đoạn (Single-stage Build)
* Gộp chung toàn bộ mã nguồn thô, trình biên dịch (Node.js full, C/C++ build tools, Python), trình quản lý gói và tệp tạm vào gói ảnh cuối cùng.
* Hậu quả: Gói ảnh phình to (từ 800 MB đến hơn 1.5 GB), tốn băng thông lưu trữ và gia tăng nguy cơ bảo mật do chứa nhiều phần mềm hệ thống có lỗ hổng (CVE).

### 3.2. Bản chất kỹ thuật đóng gói nhiều giai đoạn (Multi-stage Build)
* Cho phép định nghĩa nhiều mệnh đề `FROM` trong cùng một tệp `Dockerfile`:
  * **Giai đoạn Build (Builder Stage):** Sử dụng image đầy đủ công cụ để cài đặt dependencies và biên dịch mã nguồn.
  * **Giai đoạn Production (Final Stage):** Bắt đầu từ một base image tối giản, sau đó chỉ dùng lệnh `COPY --from=builder` để chuyển đúng thư mục thành phẩm chạy thực tế sang.
  * Toàn bộ mã nguồn tạm, công cụ build và dev-dependencies đều bị loại bỏ hoàn toàn khỏi gói ảnh thành phẩm.

### 3.3. Tối ưu hóa kích thước với nền tảng Alpine Linux
* Thay thế các bản phân phối Debian/Ubuntu cồng kềnh bằng **Alpine Linux** – hệ điều hành siêu nhẹ (~5 MB) sử dụng thư viện `musl libc` và bộ công cụ `BusyBox`.
* **Kết quả đo lường thực nghiệm đối chứng:**

| Tiêu chí đo lường | Đóng gói một giai đoạn (`node:20`) | Đóng gói nhiều giai đoạn (`node:20-alpine`) | Hiệu quả tối ưu |
| :--- | :--- | :--- | :--- |
| **Hệ điều hành nền tảng** | Debian GNU/Linux 12 (bookworm) | Alpine Linux v3.19 | Giảm tải tối đa thành phần thừa |
| **Dung lượng ảnh khi giải nén** | **1.58 GB** | **201 MB** | **Giảm 87.3%** không gian đĩa |
| **Dung lượng nén tải qua mạng** | **391 MB** | **49.9 MB** | **Giảm 87.2%** băng thông tải |
| **Số lượng gói phần mềm cài đặt** | > 450 packages hệ thống | < 50 packages tối thiểu | Thu hẹp đáng kể bề mặt tấn công |
| **Thời gian kéo ảnh khi deploy** | ~ 45 – 60 giây | ~ 3 – 5 giây | Tối ưu hóa chu trình CI/CD |

---

## 4. Quản trị vòng đời Container và các câu lệnh Docker cốt lõi

Trong quá trình quản trị và vận hành hạ tầng container, việc nắm vững các lệnh điều khiển, giám sát và can thiệp nội bộ là yếu tố bắt buộc. Dưới đây là phân tích chi tiết các câu lệnh trọng tâm:

### 4.1. Lệnh `docker start` – Khởi động lại container đã tồn tại
* **Mục đích:** Kích hoạt lại container đang ở trạng thái dừng (`Exited`) mà không cần tạo mới (`run`), bảo toàn nguyên vẹn ID, dữ liệu trên tầng ghi, biến môi trường và liên kết mạng đã gán.
* **Cú pháp:** `docker start [OPTIONS] CONTAINER [CONTAINER...]`
* **Cờ quan trọng:**
  * `-a` (`--attach`): Đính kèm trực tiếp luồng xuất chuẩn (`stdout`/`stderr`) của container vào cửa sổ terminal hiện tại.
  * `-i` (`--interactive`): Mở kênh tương tác chuẩn (`stdin`).
* **Ví dụ thực tế:**
  ```bash
  # Khởi động lại container cơ sở dữ liệu sau khi bảo trì máy chủ
  docker start cse408-postgres-db

  # Khởi động lại container ứng dụng backend
  docker start cse408-app-backend
  ```
* **Ý nghĩa:** Tránh phát sinh container rác và giữ cố định địa chỉ IP/cấu hình mạng nội bộ.

### 4.2. Lệnh `docker top` – Giám sát tiến trình bên trong container
* **Mục đích:** Hiển thị danh sách các tiến trình đang thực thi thời gian thực bên trong container từ góc nhìn của hệ điều hành máy chủ chủ quản (*Host OS*).
* **Cú pháp:** `docker top CONTAINER [ps OPTIONS]`
* **Ví dụ thực tế:**
  ```bash
  # Giám sát tiến trình Node.js đang chạy trong container backend
  docker top cse408-app-backend

  # Giám sát các tiến trình nền worker của PostgreSQL
  docker top cse408-postgres-db
  ```
* **Ý nghĩa:** Giúp kỹ sư DevOps phát hiện tức thời tiến trình bị treo, tiến trình tiêu thụ tài nguyên bất thường hoặc dấu hiệu xâm nhập lạ mà không cần phải truy cập shell vào bên trong container.

### 4.3. Lệnh `docker logs` – Kiểm tra và truy vết nhật ký hoạt động
* **Mục đích:** Đọc và trích xuất toàn bộ luồng đầu ra tiêu chuẩn (`stdout`) và luồng thông báo lỗi (`stderr`) của tiến trình chính bên trong container.
* **Cú pháp:** `docker logs [OPTIONS] CONTAINER`
* **Cờ quan trọng:**
  * `-f` (`--follow`): Giữ kết nối và hiển thị log liên tục theo thời gian thực (tương đương `tail -f`).
  * `--tail [N]`: Chỉ lấy $N$ dòng thông báo gần nhất (ví dụ: `--tail 50`).
  * `-t` (`--timestamps`): Đính kèm mốc thời gian chi tiết cho từng sự kiện.
  * `--since [TIME]`: Lọc log phát sinh trong khoảng thời gian cụ thể (ví dụ: `--since 15m`).
* **Ví dụ thực tế:**
  ```bash
  # Theo dõi log thời gian thực của backend khi tiếp nhận request
  docker logs -f --tail 100 cse408-app-backend

  # Kiểm tra lịch sử khởi tạo cơ sở dữ liệu
  docker logs --timestamps cse408-postgres-db
  ```
* **Ý nghĩa:** Là công cụ chẩn đoán sự cố quan trọng nhất khi container bị crash hoặc phản hồi mã lỗi HTTP 500.

### 4.4. Lệnh `docker exec` – Thực thi câu lệnh trực tiếp bên trong container
* **Mục đích:** Tạo và thực thi một tiến trình phụ trợ hoặc mở một phiên dòng lệnh (*Interactive Shell*) trực tiếp bên trong container đang chạy mà không làm gián đoạn tiến trình chính (PID 1).
* **Cú pháp:** `docker exec [OPTIONS] CONTAINER COMMAND [ARG...]`
* **Cờ quan trọng:**
  * `-i` (`--interactive`): Duy trì mở luồng nhập chuẩn (`stdin`).
  * `-t` (`--tty`): Cấp phát thiết bị đầu cuối ảo (*Pseudo-TTY*).
  * `-u` (`--user`): Xác định tài khoản người dùng thực thi lệnh (ví dụ: `root` hoặc `node`).
  * `-w` (`--workdir`): Chỉ định thư mục làm việc khi chạy lệnh.
* **Ví dụ thực tế:**
  ```bash
  # Mở phiên dòng lệnh sh tương tác trong container Node.js nền Alpine
  docker exec -it cse408-app-backend sh

  # Kiểm tra bảng biến môi trường thực tế bên trong container
  docker exec -it cse408-app-backend env

  # Truy cập trực tiếp vào trình dòng lệnh psql của PostgreSQL
  docker exec -it cse408-postgres-db psql -U postgres -d cse408_db
  ```
* **Ý nghĩa:** Phục vụ trực tiếp việc kiểm tra mạng nội bộ (ping, curl), xác minh tệp cấu hình và chạy các tập lệnh bảo trì dữ liệu (migration, seeding) mà không cần cài đặt thêm công cụ lên máy chủ vật lý.

### 4.5. Các câu lệnh quản lý phụ trợ thiết yếu
* `docker ps -a`: Liệt kê tất cả các container kèm trạng thái, cổng ánh xạ và tên định danh.
* `docker stop [CONTAINER]`: Gửi tín hiệu `SIGTERM` cho phép ứng dụng dọn dẹp kết nối và dừng an toàn; sau thời gian chờ (mặc định 10s) sẽ gửi `SIGKILL` nếu container chưa tắt.
* `docker system prune -f`: Dọn dẹp toàn bộ container đã tắt, mạng không dùng và các image rác (dangling images) để giải phóng dung lượng đĩa cứng.

---

## 5. Cơ chế lưu trữ dữ liệu bền vững và Quản lý mạng nội bộ trong Docker

### 5.1. Quản lý lưu trữ dữ liệu (Data Persistence)
* **Tầng ghi tạm thời (Writable Layer):** Dữ liệu gắn liền với vòng đời container; khi container bị xóa, toàn bộ dữ liệu trên tầng này sẽ mất vĩnh viễn.
* **Docker Named Volumes:**
  * Vùng lưu trữ dữ liệu do Docker Engine quản lý độc lập tại thư mục máy chủ (`/var/lib/docker/volumes/`).
  * Hoàn toàn tách biệt khỏi vòng đời của container: Khi container bị xóa hoặc cập nhật phiên bản mới, dữ liệu trong Volume vẫn được bảo toàn nguyên vẹn.
  * Phù hợp cho việc lưu trữ cơ sở dữ liệu (PostgreSQL, MongoDB).
* **Bind Mounts:**
  * Ánh xạ trực tiếp một đường dẫn tệp hoặc thư mục cụ thể từ máy chủ vật lý vào bên trong container.
  * Thường dùng để đưa tệp cấu hình bên ngoài vào container hoặc chia sẻ mã nguồn trực tiếp trong quá trình phát triển (Hot-reloading).

### 5.2. Quản lý mạng nội bộ (Docker Networking)
* **Bridge Network (Mặc định & Tự tạo):**
  * Docker thiết lập một switch ảo nội bộ (`docker0`) để cấp phát dải địa chỉ IP riêng cho từng container.
  * **User-defined Bridge Network:** Cho phép các container trong cùng mạng tự động nhận diện và phân giải địa chỉ của nhau thông qua tên dịch vụ (*Automatic DNS Resolution*), ngăn ngừa rủi ro xung đột IP khi khởi động lại.
* **Host Network:** Container dùng chung toàn bộ stack mạng với máy chủ chủ quản, loại bỏ cơ chế dịch địa chỉ mạng (NAT) để tối đa hóa hiệu năng I/O mạng.
* **None Network:** Container bị ngắt hoàn toàn mọi giao tiếp mạng, phục vụ các tác vụ xử lý tính toán yêu cầu bảo mật tuyệt đối.

---

## 6. Điều phối hệ thống đa Container với Docker Compose

### 6.1. Mục đích và cấu trúc tệp khai báo `docker-compose.yml`
* **Mục đích:** Là công cụ điều phối cấp độ máy chủ, cho phép người vận hành định nghĩa toàn bộ kiến trúc gồm nhiều container liên kết (Backend API, Database, Cache, Proxy) và các phụ thuộc về mạng, ổ đĩa lưu trữ trong một tệp cấu hình khai báo YAML duy nhất.
* **Các thành phần cốt lõi:**
  * `version`: Phiên bản định dạng tệp Compose.
  * `services`: Danh sách các container cấu thành hệ thống.
    * `build`: Thiết lập đường dẫn đóng gói Dockerfile.
    * `ports`: Ánh xạ cổng giữa máy chủ và container (`HOST:CONTAINER`).
    * `environment`: Biến môi trường truyền vào khi khởi chạy.
    * `volumes`: Gắn kết Named Volume hoặc Bind Mount.
    * `depends_on`: Định nghĩa thứ tự khởi động (ví dụ: cơ sở dữ liệu phải chạy trước ứng dụng backend).
    * `networks`: Gán container vào mạng nội bộ cụ thể.
  * `volumes`: Khai báo các Named Volume dùng chung hoặc lưu trữ bền vững.
  * `networks`: Khai báo mạng ảo nội bộ cô lập.

### 6.2. Bộ lệnh điều phối Docker Compose cốt lõi
* `docker compose up -d`: Tự động biên dịch image (nếu chưa có), khởi tạo mạng, volume và bật tất cả dịch vụ ở chế độ chạy ngầm (*Detached Mode*).
* `docker compose down`: Dừng toàn bộ các dịch vụ và dọn dẹp mạng nội bộ. Bổ sung cờ `-v` nếu muốn xóa sạch cả các volume dữ liệu.
* `docker compose ps`: Liệt kê trạng thái hiện thời, mã thoát và cổng ánh xạ của toàn bộ các dịch vụ thuộc dự án.
* `docker compose logs -f [SERVICE]`: Theo dõi log của toàn bộ cụm hoặc một dịch vụ cụ thể.
* `docker compose restart [SERVICE]`: Khởi động lại dịch vụ mà không làm thay đổi cấu hình mạng đã thiết lập.
* `docker compose exec [SERVICE] [COMMAND]`: Mở terminal hoặc thực thi lệnh vào đúng service được chỉ định.

---

## 7. Vai trò của Docker trong kiến trúc tự động hóa hạ tầng và CI/CD

* **Xóa bỏ hiện tượng "Chạy được trên máy tôi nhưng lỗi trên server":** Đảm bảo tính nhất quán tuyệt đối về môi trường (phiên bản runtime, thư viện hệ thống, cấu hình) từ máy trạm phát triển, môi trường kiểm thử (Staging) đến môi trường sản xuất (Production).
* **Đơn vị phân phối bất biến (Immutable Artifact):** Ứng dụng sau khi đóng gói thành Docker Image sẽ không thể bị thay đổi ngầm, mọi nâng cấp đều thông qua việc tạo ra image phiên bản mới có gắn thẻ (*Tagging* / *Semantic Versioning*).
* **Tích hợp trong chuỗi cung ứng tự động của đề tài:**
  * **Terraform:** Khởi tạo hạ tầng máy ảo Ubuntu trên nền tảng ảo hóa.
  * **Ansible:** Tự động cài đặt Docker Engine, cấu hình tường lửa và bảo mật máy chủ.
  * **Docker & Docker Compose:** Đóng vai trò là nền tảng thực thi ứng dụng nhẹ, độc lập và dễ dàng khôi phục khi gặp sự cố.
  * **GitHub Actions:** Tự động hóa quá trình kích hoạt Docker build, chạy kiểm thử trong container tạm thời, đẩy image lên kho lưu trữ và kích hoạt lệnh deploy từ xa.
