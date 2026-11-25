# BÁO CÁO TIẾN ĐỘ TUẦN 8

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** ThS. Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 8:** Xây dựng đường ống **CI/CD khép kín với GitHub Actions** (`.github/workflows/deploy.yml`): Tự động kiểm thử mã nguồn, đóng gói Docker Image với **Docker Buildx**, đẩy Image lên Container Registry (Docker Hub / GHCR) và triển khai tự động qua SSH lên máy chủ **AWS EC2 (`aws-ec2-prod`)** bằng `docker compose up -d`

---

## 1. Mục tiêu và phạm vi công việc Tuần 8

Sau khi hoàn thiện máy chủ **Linux Cloud Docker Host (`aws-ec2-prod`)** trên nền tảng AWS EC2 Free Tier bằng Terraform và Ansible ở Tuần 7, trọng tâm của Tuần 8 là kết nối hạ tầng đó với **đường ống tích hợp và triển khai liên tục (CI/CD)** thông qua **GitHub Actions**. Mọi thay đổi mã nguồn khi được đẩy lên nhánh chính (`main`) sẽ tự động đi qua quy trình kiểm thử, đóng gói container và cập nhật lên máy chủ thực tế mà không cần thao tác SSH thủ công.

### 1.1. Mục tiêu cụ thể
1. **Tích hợp kho mã nguồn GitHub & Quản lý cấu hình bảo mật:**
   * Tổ chức kho mã nguồn GitHub chứa mã nguồn ứng dụng, `Dockerfile`, `docker-compose.yml` và quy trình tự động hóa.
   * Cấu hình đầy đủ các biến bí mật (**GitHub Repository Secrets**) gồm `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `SSH_PRIVATE_KEY`, `SERVER_HOST` để đảm bảo không lộ thông tin xác thực trong mã nguồn.
2. **Thiết kế quy trình CI/CD đa giai đoạn (`.github/workflows/deploy.yml`):**
   * **Giai đoạn 1 (CI – Kiểm thử):** Chạy kiểm tra quy chuẩn mã nguồn (linting) và kiểm thử đơn vị (unit test) tự động trước khi đóng gói.
   * **Giai đoạn 2 (Build & Push):** Sử dụng **Docker Buildx** kết hợp cache để đóng gói ứng dụng (hỗ trợ đa kiến trúc `linux/amd64`, `linux/arm64`) và đẩy Image gắn thẻ phiên bản lên **Docker Hub** (hoặc **GitHub Container Registry**).
   * **Giai đoạn 3 (CD – Triển khai):** Kết nối SSH an toàn tới máy chủ **AWS EC2 (`aws-ec2-prod`)** đã cấu hình ở Tuần 7, kéo Image mới nhất về và cập nhật dịch vụ không gián đoạn qua `docker compose up -d --no-deps`.
3. **Tối ưu hóa Docker Image & Vận hành trên Cloud:**
   * Áp dụng kỹ thuật **Multi-stage Build** trong `Dockerfile` để giảm kích thước Image, rút ngắn thời gian đẩy/kéo qua mạng và tiết kiệm dung lượng ổ đĩa EBS `20 GB` trên `t3.micro`.
4. **Kiểm chứng luồng triển khai End-to-End:**
   * Xác minh toàn bộ luồng từ lúc lập trình viên thực hiện `git push` đến khi ứng dụng phiên bản mới phản hồi ổn định qua cổng `80`/`443` trên Public IP của AWS EC2.

---

## 2. Cơ sở lý luận & Kiến trúc đường ống CI/CD

### 2.1. Kiến trúc luồng tự động hóa End-to-End

Đường ống Tuần 8 nối tiếp trực tiếp hạ tầng đã cấp phát ở Tuần 7 (`Terraform` + `Ansible`), tạo thành chuỗi khép kín từ mã nguồn đến môi trường chạy thực tế:

```text
[ Lập trình viên ] ──(git push origin main)──► [ GitHub Repository ]
                                                        │
                                                        ▼ (Kích hoạt Workflow)
                                       [ GitHub Actions Runner (ubuntu-latest) ]
                                        ├─ Job 1 (Test): Lint & Unit Test mã nguồn
                                        ├─ Job 2 (Build & Push): Docker Buildx
                                        │        └──► Đẩy Image ──► [ Docker Hub / GHCR ]
                                        │
                                        └─ Job 3 (Deploy): SSH (Port 22)
                                                 │
                                                 ▼
                                       [ AWS EC2: aws-ec2-prod (Ubuntu 24.04) ]
                                        ├─ Tài khoản: ubuntu (nhóm docker, non-sudo)
                                        ├─ docker compose pull
                                        ├─ docker compose up -d --no-deps
                                        └─ docker image prune -f (dọn Image cũ)
```

### 2.2. Quản lý biến bí mật (GitHub Repository Secrets)

Để GitHub Actions có thể xác thực với Container Registry và máy chủ AWS EC2 một cách an toàn, toàn bộ thông tin nhạy cảm được lưu tại **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions**:

| Tên biến bí mật | Vai trò trong đường ống | Ghi chú bảo mật |
| :--- | :--- | :--- |
| `DOCKER_USERNAME` | Tên tài khoản đăng nhập Docker Hub | Dùng để gắn tag Image (`<user>/<app>:latest` và theo `github.sha`) |
| `DOCKER_PASSWORD` | Personal Access Token (PAT) của Docker Hub | Không dùng mật khẩu đăng nhập trực tiếp; giới hạn quyền Read/Write |
| `SSH_PRIVATE_KEY` | Khóa bí mật SSH (`ed25519`) tương ứng với `aws_key_pair` | Khớp với khóa công khai đã nạp cho user `ubuntu` trên EC2 ở Tuần 7 |
| `SERVER_HOST` | Public IP của máy chủ `aws-ec2-prod` | Lấy từ output `ec2_public_ip` của Terraform |

### 2.3. Tối ưu hóa đóng gói với Multi-stage Build và Docker Buildx

| Kỹ thuật áp dụng | Mục đích | Lợi ích cho môi trường AWS Free Tier (`t3.micro`) |
| :--- | :--- | :--- |
| **Multi-stage Build** | Tách biệt giai đoạn biên dịch (builder) và giai đoạn chạy (runtime) | Loại bỏ công cụ build dư thừa, giảm mạnh kích thước Image cuối cùng |
| **Docker Buildx & GHA Cache** | Hỗ trợ build đa kiến trúc (`linux/amd64`, `linux/arm64`) và lưu cache tầng (`type=gha`) | Rút ngắn thời gian build trên CI, sẵn sàng chạy trên cả `t3.micro` (`x86_64`) lẫn `t4g.micro` (`arm64`) |
| **Gắn thẻ kép (`latest` + `sha`)** | Gắn đồng thời tag `latest` và mã commit (`${{ github.sha }}`) | Dễ dàng truy vết phiên bản đang chạy và rollback nhanh khi cần |

---

## 3. Thiết kế chi tiết đường ống CI/CD (`.github/workflows/deploy.yml`)

Quy trình tự động hóa được thiết kế thành 3 job phụ thuộc tuần tự thông qua từ khóa `needs`, đảm bảo **chỉ đóng gói khi kiểm thử đạt** và **chỉ triển khai khi đẩy Image thành công**.

### 3.1. Phân rã các giai đoạn trong Workflow

1. **Giai đoạn 1 – `test` (Kiểm thử mã nguồn):**
   * Kích hoạt khi có sự kiện `push` hoặc `pull_request` vào nhánh `main`.
   * Thực hiện `actions/checkout@v4`, cài đặt môi trường ngôn ngữ lập trình, chạy bộ kiểm tra quy chuẩn (linter) và kiểm thử đơn vị (unit test).
2. **Giai đoạn 2 – `build-and-push` (`needs: test`, chỉ chạy khi `push` lên `main`):**
   * Thiết lập QEMU và `docker/setup-buildx-action@v3`.
   * Đăng nhập Container Registry qua `docker/login-action@v3` bằng `DOCKER_USERNAME` và `DOCKER_PASSWORD`.
   * Dùng `docker/build-push-action@v6` để build đa kiến trúc và đẩy Image kèm cache GitHub Actions (`cache-from: type=gha`, `cache-to: type=gha,mode=max`).
3. **Giai đoạn 3 – `deploy` (`needs: build-and-push`):**
   * Sử dụng `appleboy/ssh-action@v1` kết nối tới `SERVER_HOST` với user `ubuntu` (đã thuộc nhóm `docker` từ playbook `install-docker.yml` ở Tuần 7).
   * Thực thi chuỗi lệnh trên máy chủ EC2:
     * `docker compose pull` để tải Image phiên bản mới nhất.
     * `docker compose up -d --no-deps` để thay thế container ứng dụng mà không làm gián đoạn các dịch vụ phụ thuộc khác.
     * `docker image prune -f` để dọn dẹp các Image cũ (dangling), tránh đầy ổ đĩa EBS `20 GB`.

### 3.2. Cấu hình tham chiếu `.github/workflows/deploy.yml`

```yaml
name: CI/CD Pipeline - Build and Deploy to AWS EC2

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  test:
    name: 1. Lint & Unit Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source code
        uses: actions/checkout@v4

      - name: Run linter and unit tests
        run: |
          echo "Running code style checks and unit tests..."
          # Lệnh kiểm thử tùy thuộc vào stack ứng dụng (npm test / pytest / go test)

  build-and-push:
    name: 2. Build & Push Docker Image
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source code
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push multi-arch image
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/cse408-app:latest
            ${{ secrets.DOCKER_USERNAME }}/cse408-app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: 3. Deploy to AWS EC2 via SSH
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Deploy container via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ubuntu
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd ~/app
            docker compose pull
            docker compose up -d --no-deps
            docker image prune -f
```

---

## 4. Kịch bản kiểm thử và tiêu chí đánh giá đường ống

| Tiêu chí kiểm tra | Hành động / Lệnh thực hiện | Kết quả kỳ vọng |
| :--- | :--- | :--- |
| **Kích hoạt tự động khi đẩy mã nguồn** | `git commit -m "..." && git push origin main` | GitHub Actions tự động khởi chạy workflow `CI/CD Pipeline` |
| **Cổng kiểm soát chất lượng (CI Gate)** | Đẩy mã nguồn chứa lỗi cú pháp hoặc test sai | Job `test` báo `Failed`, dừng toàn bộ pipeline, không build và không deploy lên Production |
| **Đóng gói & Đẩy Image (Buildx)** | Quan sát log Job `build-and-push` và trang Docker Hub | Build thành công đa kiến trúc, đẩy đủ 2 tag (`latest` và `<sha>`), tận dụng cache GHA từ lần chạy thứ 2 |
| **Triển khai tự động lên AWS EC2 (CD)** | Quan sát log Job `deploy` và kiểm tra trên EC2 (`docker compose ps`) | Container mới chuyển trạng thái `Up / healthy`, không cần SSH thủ công |
| **Kiểm tra truy cập dịch vụ thực tế** | Truy cập `http://<EC2_PUBLIC_IP>` qua trình duyệt / `curl` | Trả về mã HTTP `200 OK` với đúng phiên bản ứng dụng vừa cập nhật |

---

## 5. Đánh giá và định hướng kế hoạch Tuần 9

1. **Giá trị đạt được trong Tuần 8:**
   * Hoàn thiện thiết kế đường ống **CI/CD khép kín với GitHub Actions**, kết nối xuyên suốt từ kho mã nguồn GitHub $\rightarrow$ Docker Hub $\rightarrow$ máy chủ **AWS EC2 (`aws-ec2-prod`)** đã chuẩn bị bằng Terraform và Ansible ở Tuần 7.
   * Loại bỏ hoàn toàn thao tác build và triển khai thủ công trên máy chủ Production, đảm bảo tính nhất quán giữa môi trường phát triển và môi trường vận hành nhờ đóng gói container.
2. **Định hướng Tuần 9 (Thực nghiệm đo lường & Thu thập số liệu):**
   * Triển khai thực nghiệm định lượng và thu thập số liệu cho **Chương 4: Thực nghiệm & Đánh giá kết quả** theo 3 kịch bản:
     * **Kịch bản 1 (Thời gian thiết lập hạ tầng):** So sánh cài đặt máy chủ, tường lửa, Docker thủ công qua SSH với quy trình tự động hóa **Terraform + Ansible** (lặp lại nhiều lần lấy giá trị trung bình).
     * **Kịch bản 2 (Tốc độ phân phối phần mềm):** Đo tổng thời gian từ khi thực hiện `git push` đến khi phiên bản ứng dụng mới hoạt động ổn định trên AWS EC2 qua GitHub Actions.
     * **Kịch bản 3 (Khả năng phục hồi sau sự cố – Disaster Recovery):** Giả lập xóa sạch hạ tầng (`terraform destroy`) và đo thời gian khôi phục hoàn chỉnh hệ thống từ con số 0 bằng mã nguồn IaC + CI/CD.
   * Đo đạc và so sánh dung lượng Docker Image trước và sau khi tối ưu **Multi-stage Build**.
