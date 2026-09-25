# CHƯƠNG 1: MỞ ĐẦU
> **Đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible  
> **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589  
> **Giảng viên hướng dẫn:** Nguyễn Thọ Thông

---

## 1.1. Tính cấp thiết của đề tài

* **Thực trạng quản trị hạ tầng truyền thống:**
  * **Chậm và tốn công sức:** Cài đặt máy chủ thủ công mất nhiều giờ, không đáp ứng được chu kỳ phát hành phần mềm nhanh hiện nay.
  * **Dễ sai sót do con người:** Gõ nhầm lệnh hoặc cấu hình thiếu sót gây lỗ hổng bảo mật.
  * **Trôi dạt cấu hình:** Môi trường phát triển, thử nghiệm và vận hành thực tế bị lệch nhau theo thời gian do các bản vá lỗi thủ công, dẫn đến lỗi "chạy được ở máy cục bộ nhưng lỗi trên máy chủ".
  * **Khôi phục sự cố kém:** Khi máy chủ hỏng, việc tái thiết lập phụ thuộc vào trí nhớ cá nhân hoặc tài liệu hướng dẫn lỗi thời.

* **Giải pháp DevOps và hạ tầng dưới dạng mã nguồn:**
  * Biến toàn bộ hạ tầng (máy chủ, mạng, dịch vụ) thành mã nguồn lưu trữ trên Git.
  * Đảm bảo tính nhất quán, khả năng tái lập 100% từ con số 0 và kiểm soát lịch sử thay đổi.

* **Lý do lựa chọn cặp đôi Terraform và Ansible:**
  * **Terraform:** Xuất sắc nhất trong việc tạo và quản lý vòng đời tài nguyên phần cứng, máy ảo theo mô hình khai báo và tệp trạng thái (`.tfstate`).
  * **Ansible:** Xuất sắc nhất trong việc cấu hình hệ điều hành, cài đặt môi trường thực thi và bảo mật theo cơ chế không cần cài phần mềm điều khiển trên máy đích qua SSH.
  * **Kết hợp Docker và GitHub Actions:** Tạo nên chuỗi tự động hóa khép kín: Tự động tạo hạ tầng $\rightarrow$ Cấu hình máy chủ $\rightarrow$ Đóng gói ứng dụng $\rightarrow$ Triển khai liên tục qua CI/CD.

---

## 1.2. Mục tiêu nghiên cứu
### 1.2.1. Mục tiêu tổng quát
Nghiên cứu và hiện thực hóa quy trình tự động hóa hạ tầng khép kín kết hợp đường ống CI/CD hiện đại; ứng dụng thành công bộ công cụ **Terraform**, **Ansible**, **Docker** và **GitHub Actions** trên cụm máy ảo thực nghiệm, có số liệu đo lường định lượng so sánh với phương pháp thủ công.

### 1.2.2. Mục tiêu cụ thể
1. **Lý thuyết:** Nắm vững bản chất DevOps, sự khác biệt giữa khởi tạo hạ tầng (Terraform) và quản lý cấu hình (Ansible), nguyên lý tính nhất quán và hạ tầng bất biến.
2. **Kỹ thuật và triển khai:**
   * Viết kịch bản Terraform tự động cấp phát 02 máy ảo Ubuntu trên Canonical Multipass và tự động sinh tệp danh mục máy chủ `inventory.ini` cho Ansible.
   * Xây dựng kịch bản Ansible tự động cấu hình bảo mật hệ điều hành (tường lửa UFW, tài khoản người dùng an toàn), cài đặt Docker Engine và thiết lập máy chủ chuyển tiếp Nginx.
   * Đóng gói ứng dụng mẫu với Docker và thiết lập đường ống GitHub Actions tự động kiểm thử, đóng gói và triển khai lên máy chủ.
3. **Thực nghiệm và đo lường:**
   * Thu thập số liệu định lượng về: Thời gian khởi tạo hạ tầng, tốc độ triển khai phiên bản mới, và thời gian khôi phục sau sự cố.

---

## 1.3. Đối tượng nghiên cứu

1. **Nguyên lý và mô hình:**
   * Văn hóa và quy trình DevOps; Mô hình tích hợp và triển khai liên tục (CI/CD).
   * Nguyên lý hạ tầng dưới dạng mã nguồn, cơ chế quản lý trạng thái, và tính nhất quán khi thực thi.
2. **Công nghệ và công cụ:**
   * Khởi tạo hạ tầng: **HashiCorp Terraform**.
   * Quản lý cấu hình: **Red Hat Ansible**.
   * Đóng gói và chuyển tiếp mạng: **Docker**, **Docker Compose**, **Nginx**.
   * Tự động hóa CI/CD: **GitHub Actions**.
   * Ảo hóa môi trường thực hành: **Canonical Multipass** (Ubuntu 22.04 LTS).

---

## 1.4. Phạm vi nghiên cứu

### 1.4.1. Trong phạm vi
* **Môi trường thực hành:** Cụm 02 máy ảo Ubuntu 22.04 LTS chạy cục bộ trên Canonical Multipass (tiết kiệm 100% chi phí máy chủ đám mây, mô phỏng mạng máy chủ thực tế).
* **Kiến trúc phân bổ:**
  * Máy ảo 1 (Máy chủ ứng dụng): Chạy Nginx và Docker Container chứa ứng dụng backend.
  * Máy ảo 2 (Máy chủ cơ sở dữ liệu và giám sát): Chạy cơ sở dữ liệu và theo dõi hệ thống.
* **Quy trình tự động hóa:** Khởi tạo máy ảo bằng Terraform $\rightarrow$ Tự sinh danh mục máy chủ $\rightarrow$ Cấu hình máy chủ bằng Ansible $\rightarrow$ Triển khai tự động qua GitHub Actions.

### 1.4.2. Ngoài phạm vi
* Không nghiên cứu các hệ thống điều phối cụm máy chủ lớn như Kubernetes hay Docker Swarm.
* Không tập trung đi sâu vào logic nghiệp vụ nội bộ của ứng dụng mẫu.

---

## 1.5. Phương pháp nghiên cứu

1. **Nghiên cứu tài liệu:** Phân tích tài liệu kỹ thuật chính thức từ HashiCorp, Red Hat, Docker và các quy chuẩn kỹ thuật phần mềm.
2. **Thực nghiệm phát triển:** Trực tiếp lập trình mã nguồn Terraform, kịch bản Ansible, tệp đóng gói Dockerfile và kịch bản CI/CD (`deploy.yml`).
3. **Đo lường định lượng:** Thực hiện bấm giờ thực tế với 3 kịch bản kiểm thử (lặp lại tối thiểu 5 lần để lấy giá trị trung bình thống kê).
4. **So sánh đối chiếu:** Đánh giá các chỉ số hiệu năng giữa phương pháp quản trị thủ công và phương pháp tự động hóa.

---

## 1.6. Kết quả dự kiến đạt được

* **Sản phẩm kỹ thuật:**
  1. Kho mã nguồn Git hoàn chỉnh gồm mã nguồn ứng dụng, mã nguồn Terraform, kịch bản Ansible, Dockerfile và kịch bản GitHub Actions.
  2. Hệ thống hạ tầng tự động: Khởi tạo toàn bộ môi trường và đưa ứng dụng lên hoạt động chỉ với **1 câu lệnh**; tự động cập nhật lên máy chủ sau mỗi lần đẩy mã nguồn lên Git.
* **Sản phẩm học thuật:**
  1. Bảng số liệu và đồ thị đo lường thực nghiệm chứng minh hiệu quả: Giảm **~80-85%** thời gian khởi tạo và **~95%** thời gian khôi phục sự cố.
  2. Báo cáo chuyên đề toàn văn (5 chương) chuẩn quy cách học thuật của nhà trường.
  3. Bản trình chiếu (15-18 trang) và kịch bản thực nghiệm trực tiếp bảo vệ trước Hội đồng chấm chuyên đề.
