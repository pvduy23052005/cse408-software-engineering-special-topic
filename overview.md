# TỔNG QUAN ĐỀ TÀI CHUYÊN ĐỀ KỸ THUẬT PHẦN MỀM (CSE408)

---

## 📌 THÔNG TIN CHUNG
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Tên tiếng Anh:** Automated Infrastructure Provisioning and CI/CD Pipeline with Docker based on Terraform and Ansible
* **Mã học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Học kỳ:** Học kỳ 7 – Năm học 2026-2027
* **Sinh viên thực hiện:** Phùng Văn Duy – MSSV: 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Khoa / Viện:** Khoa Công nghệ Thông tin / Kỹ thuật Phần mềm

---

## 📑 MỤC LỤC TỔNG QUAN

* [**1. Tổng quan đề tài & Tóm tắt nội dung**](#1-tổng-quan-đề-tài--tóm-tắt-nội-dung)
  * [1.1. Tóm tắt đề tài](#11-tóm-tắt-đề-tài)
  * [1.2. Từ khóa cốt lõi](#12-từ-khóa-cốt-lõi)
  * [1.3. Bảng tóm tắt thông số dự án](#13-bảng-tóm-tắt-thông-số-dự-án)
* [**2. Bối cảnh, Tính cấp thiết & Bài toán thực tiễn**](#2-bối-cảnh-tính-cấp-thiết--bài-toán-thực-tiễn)
  * [2.1. Bối cảnh chuyển dịch sang văn hóa DevOps](#21-bối-cảnh-chuyển-dịch-sang-văn-hóa-devops)
  * [2.2. Hạn chế của quản trị hạ tầng truyền thống](#22-hạn-chế-của-quản-trị-hạ-tầng-truyền-thống)
  * [2.3. Bài toán thực tiễn đặt ra trong đề tài](#23-bài-toán-thực-tiễn-đặt-ra-trong-đề-tài)
* [**3. Mục tiêu, Đối tượng & Phạm vi nghiên cứu**](#3-mục-tiêu-đối-tượng--phạm-vi-nghiên-cứu)
  * [3.1. Mục tiêu nghiên cứu](#31-mục-tiêu-nghiên-cứu)
  * [3.2. Đối tượng nghiên cứu](#32-đối-tượng-nghiên-cứu)
  * [3.3. Phạm vi nghiên cứu](#33-phạm-vi-nghiên-cứu)
  * [3.4. Phương pháp nghiên cứu](#34-phương-pháp-nghiên-cứu)
* [**4. Kiến trúc hệ thống & Phân công công nghệ**](#4-kiến-trúc-hệ-thống--phân-công-công-nghệ)
  * [4.1. Sơ đồ luồng tích hợp toàn diện](#41-sơ-đồ-luồng-tích-hợp-toàn-diện)
  * [4.2. Bảng phân chia trách nhiệm công nghệ](#42-bảng-phân-chia-trách-nhiệm-công-nghệ)
* [**5. Lộ trình thực hiện chi tiết 11 tuần**](#5-lộ-trình-thực-hiện-chi-tiết-11-tuần)
  * [5.1. Phân kỳ 4 giai đoạn tiến độ](#51-phân-kỳ-4-giai-đoạn-tiến-độ)
  * [5.2. Khung phân bổ công việc từng tuần](#52-khung-phân-bổ-công-việc-từng-tuần)
* [**6. Kế hoạch thực nghiệm đo lường & Đánh giá**](#6-kế-hoạch-thực-nghiệm-đo-lường--đánh-giá)
  * [6.1. Mục tiêu đo lường định lượng](#61-mục-tiêu-đo-lường-định-lượng)
  * [6.2. Ba kịch bản thực nghiệm cốt lõi](#62-ba-kịch-bản-thực-nghiệm-cốt-lõi)
  * [6.3. Bảng chỉ số hiệu năng mục tiêu](#63-bảng-chỉ-số-hiệu-năng-mục-tiêu)
* [**7. Cấu trúc báo cáo toàn văn chuyên đề**](#7-cấu-trúc-báo-cáo-toàn-văn-chuyên-đề)
  * [Chương 1: Mở đầu](#chương-1-mở-đầu)
  * [Chương 2: Cơ sở lý thuyết & Công nghệ liên quan](#chương-2-cơ-sở-lý-thuyết--công-nghệ-liên-quan)
  * [Chương 3: Phân tích và thiết kế hệ thống](#chương-3-phân-tích-và-thiết-kế-hệ-thống)
  * [Chương 4: Thực nghiệm và đánh giá kết quả](#chương-4-thực-nghiệm-và-đánh-giá-kết-quả)
  * [Chương 5: Kết luận và hướng phát triển](#chương-5-kết-luận-và-hướng-phát-triển)
* [**8. Phân tích rủi ro kỹ thuật & Biện pháp phòng ngừa**](#8-phân-tích-rủi-ro-kỹ-thuật--biện-pháp-phòng-ngừa)
* [**9. Sản phẩm bàn giao cuối cùng**](#9-sản-phẩm-bàn-giao-cuối-cùng)

---

# NỘI DUNG CHI TIẾT CÁC MỤC

---

## 1. TỔNG QUAN ĐỀ TÀI & TÓM TẮT NỘI DUNG

### 1.1. Tóm tắt đề tài
Đề tài tập trung nghiên cứu quy trình tự động hóa hạ tầng và chuỗi cung ứng phần mềm liên tục (CI/CD) theo chuẩn DevOps hiện đại. Giải pháp kết hợp 4 thành phần cốt lõi:
* **Terraform:** Đóng vai trò là công cụ khởi tạo hạ tầng, tự động tạo cụm máy ảo Ubuntu từ con số 0.
* **Ansible:** Đóng vai trò là công cụ quản lý cấu hình, tự động thiết lập bảo mật hệ điều hành, cấu hình mạng, cài đặt môi trường thực thi và dịch vụ máy chủ chuyển tiếp Nginx.
* **Docker:** Đóng gói ứng dụng backend và cơ sở dữ liệu thành các container độc lập nhằm tối ưu kích thước.
* **GitHub Actions:** Tự động hóa kiểm thử mã nguồn, đóng gói và kích hoạt triển khai liên tục lên máy chủ.

Hệ thống được thử nghiệm trên môi trường ảo hóa cục bộ bằng **Canonical Multipass** (tiết kiệm 100% chi phí máy chủ đám mây), có số liệu đo lường thực nghiệm chứng minh hiệu quả vượt trội so với phương pháp thủ công.

### 1.2. Từ khóa cốt lõi
`DevOps`, `Hạ tầng dưới dạng mã nguồn`, `Tích hợp và Triển khai liên tục`, `Terraform`, `Ansible`, `Docker`, `Multipass`, `Tính nhất quán`, `Hạ tầng bất biến`.

### 1.3. Bảng tóm tắt thông số dự án
| Tiêu chí | Thông số mô tả |
| :--- | :--- |
| **Môi trường thực hành** | 02 máy ảo Ubuntu 22.04 LTS chạy trên Canonical Multipass (máy chủ macOS) |
| **Ứng dụng mẫu** | Dịch vụ backend REST API kết nối cơ sở dữ liệu (PostgreSQL/MongoDB) |
| **Thời lượng thực hiện** | 11 tuần (theo phân bổ tiến độ học phần) |
| **Số lượng chương báo cáo** | 5 chương toàn văn theo chuẩn học thuật của nhà trường |
| **Chi phí vận hành** | 0 VNĐ (sử dụng 100% mã nguồn mở và ảo hóa cục bộ) |

---

## 2. BỐI CẢNH, TÍNH CẤP THIẾT & BÀI TOÁN THỰC TIỄN

### 2.1. Bối cảnh chuyển dịch sang văn hóa DevOps
Sự bùng nổ của kiến trúc vi dịch vụ và điện toán đám mây đòi hỏi chu kỳ phát hành phần mềm phải chuyển dịch từ hàng tháng xuống còn hàng ngày hoặc hàng giờ. DevOps ra đời nhằm xóa bỏ "bức tường ngăn cách" giữa đội ngũ Phát triển và Vận hành.

### 2.2. Hạn chế của quản trị hạ tầng truyền thống
* **Thao tác thủ công:** Cài đặt máy chủ thủ công phụ thuộc vào trí nhớ con người, dễ gõ sai lệnh, thiếu bảo mật.
* **Trôi dạt cấu hình:** Môi trường phát triển, thử nghiệm và vận hành thực tế bị lệch nhau theo thời gian, gây ra lỗi "chạy được ở máy cục bộ nhưng lỗi trên máy chủ".
* **Khôi phục sự cố kém:** Mất nhiều thời gian để dựng lại hệ thống khi máy chủ gặp sự cố.

### 2.3. Bài toán thực tiễn đặt ra trong đề tài
Xây dựng một giải pháp cho phép:
1. Tạo hạ tầng mới hoàn chỉnh từ con số 0 chỉ với **1 câu lệnh duy nhất**.
2. Đảm bảo tính nhất quán, chạy lại kịch bản không sinh lỗi.
3. Tự động hóa phân phối ứng dụng: Lập trình viên chỉ cần đẩy mã nguồn lên Git, toàn bộ khâu kiểm thử, đóng gói và triển khai lên máy chủ tự động diễn ra không cần thao tác tay.

---

## 3. MỤC TIÊU, ĐỐI TƯỢNG & PHẠM VI NGHIÊN CỨU

### 3.1. Mục tiêu nghiên cứu
* **Mục tiêu tổng quát:** Làm chủ quy trình tự động hóa hạ tầng và CI/CD khép kín, hiện thực hóa bằng mô hình thực nghiệm và báo cáo chuyên đề khoa học.
* **Mục tiêu cụ thể:**
  1. Hiểu sâu bản chất lý thuyết DevOps, sự khác biệt giữa khởi tạo hạ tầng và quản lý cấu hình, nguyên lý tính nhất quán và hạ tầng bất biến.
  2. Xây dựng bộ mã nguồn Terraform tự động tạo 2 máy ảo Ubuntu và tự sinh tệp danh mục máy chủ cho Ansible.
  3. Xây dựng kịch bản Ansible chuẩn hóa bảo mật hệ điều hành, cài đặt Docker và Nginx.
  4. Xây dựng kịch bản GitHub Actions đóng gói và triển khai tự động.
  5. Thu thập bộ số liệu đo lường thực nghiệm 3 kịch bản: Thời gian khởi tạo, tốc độ triển khai, và khả năng khôi phục sự cố.

### 3.2. Đối tượng nghiên cứu
* Lý thuyết và nguyên lý: Hạ tầng dưới dạng mã nguồn, quản lý trạng thái, tính nhất quán, đường ống CI/CD.
* Công nghệ và công cụ: Terraform, Ansible, Docker, Nginx, GitHub Actions, Multipass.

### 3.3. Phạm vi nghiên cứu
* **Trong phạm vi:** Môi trường ảo hóa cục bộ Multipass Ubuntu 22.04 LTS; Cụm 2 máy ảo (máy chủ ứng dụng và máy chủ cơ sở dữ liệu); Ứng dụng backend REST API; Đường ống CI/CD tự động; Đo lường định lượng.
* **Ngoài phạm vi:** Không triển khai cụm Kubernetes (K8s) quy mô lớn; Không sử dụng Cloud công cộng trả phí (AWS/GCP); Không tối ưu sâu thuật toán nghiệp vụ nội bộ của app mẫu.

### 3.4. Phương pháp nghiên cứu
* Nghiên cứu lý thuyết qua tài liệu chính thống của HashiCorp, Red Hat, Docker.
* Thực nghiệm phát triển: Xây dựng mã nguồn tự động hóa hạ tầng và CI/CD.
* Đo lường định lượng: Lặp lại nhiều lần thử nghiệm để lấy giá trị trung bình.
* Phân tích và so sánh đối chiếu giữa phương pháp thủ công và phương pháp tự động hóa.

---

## 4. KIẾN TRÚC HỆ THỐNG & PHÂN CÔNG CÔNG NGHỆ

### 4.1. Sơ đồ luồng tích hợp toàn diện
```text
[ Developer ] ── (git push main) ──> [ GitHub Repository ]
                                              │
                                     (Trigger Workflow)
                                              ▼
                                   [ GitHub Actions Runner ]
                                     ├── 1. Unit Test & Lint
                                     ├── 2. Multi-stage Docker Buildx
                                     └── 3. Push Image to Docker Hub
                                              │
[ Terraform Core ]                            │ (Deploy Notification)
      │                                       ▼
 (terraform apply)                 [ Cụm Máy Ảo Multipass ]
      ▼                                ├── Nginx Reverse Proxy (Port 80/443)
[ Provision 2 VMs ]                    ├── App Container (Docker Pull & Run)
      │                                └── Database Container
      ▼                                       ▲
[ Dynamic Inventory (hosts.ini) ]             │ (SSH Config & Hardening)
      │                                       │
      └──────────────> [ Ansible Engine ] ────┘
```

### 4.2. Bảng phân chia trách nhiệm công nghệ
| Phân tầng | Công cụ | Trách nhiệm chính | Đặc tính nổi bật |
| :--- | :--- | :--- | :--- |
| **Ảo hóa hạ tầng** | Multipass | Ảo hóa cụm 2 máy ảo Ubuntu trên máy chủ vật lý | Gọn nhẹ, chuẩn bị sẵn tài nguyên, chi phí 0đ |
| **Khởi tạo hạ tầng** | Terraform | Tạo máy ảo, cấp phát RAM/CPU/ổ cứng, xuất địa chỉ IP | Mô hình khai báo, quản lý tệp trạng thái (`.tfstate`) |
| **Quản lý cấu hình** | Ansible | Cài đặt hệ điều hành, tường lửa UFW, Docker, Nginx | Không cần cài phần mềm đại lý, tính nhất quán |
| **Đóng gói container** | Docker | Đóng gói ứng dụng cô lập, tối ưu dung lượng | Đóng gói nhiều giai đoạn, gói ảnh nền nhẹ (Alpine) |
| **Phân phối liên tục** | GitHub Actions | Kiểm thử, đóng gói ứng dụng, kích hoạt triển khai | Tự động hóa hoàn toàn từ mã nguồn |

---

## 5. LỘ TRÌNH THỰC HIỆN CHI TIẾT 11 TUẦN

### 5.1. Phân kỳ 4 giai đoạn tiến độ
* **Giai đoạn 1 (Tuần 1 - 3): Nền tảng & Chuẩn bị môi trường** (Nghiên cứu lý thuyết, đóng gói Docker cho ứng dụng mẫu, dựng môi trường máy ảo Multipass).
* **Giai đoạn 2 (Tuần 4 - 7): Tự động hóa Hạ tầng & Cấu hình** (Terraform cấp phát máy ảo, tự sinh danh mục máy chủ, Ansible bảo mật hệ điều hành, Docker và Nginx).
* **Giai đoạn 3 (Tuần 8 - 9): Tự động hóa CI/CD & Thực nghiệm đo lường** (Đường ống GitHub Actions, đo lường định lượng 3 kịch bản).
* **Giai đoạn 4 (Tuần 10 - 11): Hoàn thiện Báo cáo & Bảo vệ** (Báo cáo toàn văn 5 chương, bản trình chiếu thuyết trình, kịch bản biểu diễn trực tiếp).

### 5.2. Khung phân bổ công việc từng tuần
* **Tuần 1:** Nghiên cứu tổng quan lý thuyết DevOps, hạ tầng dưới dạng mã nguồn, hoàn thiện đề cương và viết Chương 1.
* **Tuần 2:** Xây dựng ứng dụng backend mẫu (REST API và cơ sở dữ liệu) và đóng gói Docker nhiều giai đoạn.
* **Tuần 3:** Cài đặt Multipass, khởi tạo cụm 2 máy ảo Ubuntu, cấu hình khóa SSH không cần mật khẩu.
* **Tuần 4:** Nghiên cứu vòng đời lệnh của Terraform (khởi tạo, lập kế hoạch, áp dụng, hủy bỏ, quản lý trạng thái) và viết mã nguồn tạo cụm máy ảo.
* **Tuần 5:** Hoàn thiện đầu ra của Terraform, tự động sinh tệp danh mục máy chủ cho Ansible, kiểm tra tính nhất quán.
* **Tuần 6:** Nghiên cứu cơ chế Ansible không cần phần mềm đại lý và viết kịch bản cấu hình hệ điều hành (tường lửa UFW, tài khoản người dùng, múi giờ).
* **Tuần 7:** Viết kịch bản Ansible tự động cài đặt Docker Engine, Docker Compose và máy chủ chuyển tiếp Nginx.
* **Tuần 8:** Xây dựng đường ống GitHub Actions CI/CD (Kiểm thử $\rightarrow$ Đóng gói đa kiến trúc $\rightarrow$ Đẩy lên Docker Hub $\rightarrow$ Triển khai tự động).
* **Tuần 9:** Thực nghiệm đo lường thu thập số liệu (Đo lường 3 kịch bản: thời gian khởi tạo hạ tầng, chu kỳ triển khai, khôi phục sau sự cố).
* **Tuần 10:** Hoàn thiện Báo cáo Chuyên đề toàn văn (5 chương) theo quy chuẩn học thuật của nhà trường.
* **Tuần 11:** Chỉnh sửa theo góp ý của giảng viên hướng dẫn, thiết kế bản trình chiếu báo cáo (15-18 trang) và chuẩn bị kịch bản biểu diễn trực tiếp để bảo vệ.

---

## 6. KẾ HOẠCH THỰC NGHIỆM ĐO LƯỜNG & ĐÁNH GIÁ

### 6.1. Mục tiêu đo lường định lượng
Đưa ra số liệu khoa học chứng minh giải pháp tự động hóa giúp giảm thiểu thời gian, loại bỏ hoàn toàn hiện tượng trôi dạt cấu hình và tăng tốc độ phân phối phần mềm so với phương pháp thủ công truyền thống.

### 6.2. Ba kịch bản thực nghiệm cốt lõi
1. **Kịch bản 1 (Cấp phát và cấu hình hạ tầng ban đầu):** So sánh thời gian cài đặt 2 máy chủ, Docker và Nginx bằng tay (kết nối SSH gõ lệnh thủ công) so với tự động hóa (qua Terraform và Ansible).
2. **Kịch bản 2 (Tốc độ phân phối phần mềm):** Đo thời gian từ khi lập trình viên đẩy mã nguồn thay đổi lên Git đến khi phiên bản mới hoạt động ổn định trên máy chủ.
3. **Kịch bản 3 (Khả năng phục hồi sau sự cố):** Giả lập sự cố xóa toàn bộ máy ảo (`multipass delete --purge`), đo thời gian khôi phục toàn bộ hệ thống từ con số 0.

### 6.3. Bảng chỉ số hiệu năng mục tiêu
* Thời gian thiết lập hệ thống: Giảm **~ 80 - 85%**.
* Tốc độ triển khai phiên bản mới: Giảm **~ 75 - 80%** (từ 15 phút xuống ~ 2 phút).
* Thời gian khôi phục sau sự cố: Giảm **~ 95%** (từ hàng giờ xuống ~ 5 phút).
* Kích thước gói ảnh Docker: Giảm **~ 85%** nhờ kỹ thuật đóng gói nhiều giai đoạn trên nền Alpine Linux.

---

## 7. CẤU TRÚC BÁO CÁO TOÀN VĂN CHUYÊN ĐỀ

* **CHƯƠNG 1: MỞ ĐẦU**
  * 1.1. Tính cấp thiết của đề tài
  * 1.2. Mục tiêu nghiên cứu (Tổng quát và cụ thể)
  * 1.3. Đối tượng nghiên cứu
  * 1.4. Phạm vi nghiên cứu
  * 1.5. Phương pháp nghiên cứu
  * 1.6. Kết quả dự kiến đạt được
* **CHƯƠNG 2: CƠ SỞ LÝ THUYẾT & CÔNG NGHỆ LIÊN QUAN**
  * 2.1. Tổng quan văn hóa DevOps và nguyên lý CI/CD
  * 2.2. Khái niệm Hạ tầng dưới dạng mã nguồn và Quản lý cấu hình
  * 2.3. Nghiên cứu công nghệ cốt lõi: Terraform, Ansible, Docker, Nginx, GitHub Actions
  * 2.4. Các nguyên lý hạ tầng hiện đại: Tính nhất quán, Hạ tầng bất biến, Kiểm thử sớm
* **CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG**
  * 3.1. Bài toán và yêu cầu hệ thống (Chức năng và phi chức năng)
  * 3.2. Thiết kế kiến trúc tổng thể
  * 3.3. Thiết kế kịch bản cấp phát hạ tầng với Terraform
  * 3.4. Thiết kế các vai trò và kịch bản thực thi với Ansible
  * 3.5. Thiết kế đường ống CI/CD với GitHub Actions
* **CHƯƠNG 4: THỰC NGHIỆM VÀ ĐÁNH GIÁ KẾT QUẢ**
  * 4.1. Môi trường thực nghiệm và kịch bản thử nghiệm
  * 4.2. Kết quả triển khai các phân hệ (Terraform, Ansible, CI/CD)
  * 4.3. Đánh giá và đo lường định lượng hiệu năng qua 3 kịch bản thực nghiệm
  * 4.4. Bàn luận kết quả và ưu nhược điểm của hệ thống
* **CHƯƠNG 5: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN**
  * 5.1. Các kết quả chính đã đạt được
  * 5.2. Các mặt còn hạn chế
  * 5.3. Hướng mở rộng tiếp theo (Kubernetes, GitOps với ArgoCD, Giám sát hệ thống với Prometheus và Grafana)
* **TÀI LIỆU THAM KHẢO** (Định dạng chuẩn IEEE)

---

## 8. PHÂN TÍCH RỦI RO KỸ THUẬT & BIỆN PHÁP PHÒNG NGỪA

1. **Rủi ro kiến trúc vi xử lý Apple Silicon (ARM64 vs AMD64):**
   * *Nguyên nhân:* Máy chủ vật lý Mac chạy kiến trúc ARM64, máy ảo Multipass chạy ARM64, trong khi trình thực thi GitHub Actions mặc định là AMD64.
   * *Giải pháp:* Sử dụng `docker/setup-buildx-action` trong quy trình CI/CD để đóng gói đa kiến trúc (`--platform linux/amd64,linux/arm64`).
2. **Rủi ro kết nối mạng CI/CD vào máy ảo cục bộ (Tuần 8):**
   * *Nguyên nhân:* Trình thực thi GitHub Actions trên nền tảng đám mây không thể kết nối SSH trực tiếp vào địa chỉ IP riêng của máy ảo Multipass (`192.168.64.x`).
   * *Giải pháp:* Sử dụng **GitHub Actions Self-Hosted Runner** cài đặt bên trong máy ảo Multipass (kết nối chiều ra qua HTTPS, không cần mở cổng mạng) hoặc dùng mạng ảo riêng qua **Tailscale**.
3. **Rủi ro đồng bộ trạng thái và danh mục máy chủ tự động (Tuần 5):**
   * *Nguyên nhân:* Địa chỉ IP máy ảo thay đổi sau mỗi lần tạo lại.
   * *Giải pháp:* Dùng tài nguyên `local_file` kết hợp `templatefile()` trong Terraform để tự động sinh tệp `hosts.ini` ngay sau khi áp dụng cấu hình (`apply`).

---

## 9. SẢN PHẨM BÀN GIAO CUỐI CÙNG

1. **Kho lưu trữ mã nguồn Git:**
   * Mã nguồn ứng dụng backend và Dockerfile đóng gói nhiều giai đoạn.
   * Kịch bản Terraform (`main.tf`, `variables.tf`, `outputs.tf`).
   * Kịch bản và cấu trúc vai trò Ansible hoàn chỉnh.
   * Đường ống tự động hóa `.github/workflows/deploy.yml`.
2. **Hồ sơ tài liệu học thuật:**
   * Báo cáo toàn văn chuyên đề hoàn chỉnh (5 chương).
   * Bản trình chiếu báo cáo bảo vệ trước hội đồng (15 - 18 trang).
   * Video ghi lại quá trình biểu diễn hoạt động của hệ thống (dự phòng sự cố).
3. **Đánh giá mức độ hoàn thành:**
   * Đáp ứng 100% yêu cầu học phần Chuyên đề Kỹ thuật Phần mềm (CSE408).
   * Đủ tiêu chuẩn bảo vệ đạt điểm Giỏi / Xuất sắc trước Hội đồng chấm chuyên đề.
