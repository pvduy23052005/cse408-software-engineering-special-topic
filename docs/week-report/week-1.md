# BÁO CÁO TIẾN ĐỘ TUẦN 1

* **Học phần:** CSE408 – Chuyên đề Kỹ thuật Phần mềm
* **Tên đề tài:** Tìm hiểu quy trình tự động hóa hạ tầng và CI/CD với Docker dựa trên Terraform và Ansible
* **Sinh viên thực hiện:** Phùng Văn Duy – **MSSV:** 2352270589
* **Giảng viên hướng dẫn:** Nguyễn Thọ Thông
* **Nội dung trọng tâm Tuần 1:** Hoàn thiện nội dung Chương 1: Mở đầu

---

## 1. Tính cấp thiết của đề tài
* **Thực trạng quản trị hạ tầng truyền thống:**
  * **Chậm và tốn công sức:** Cài đặt máy chủ bằng tay mất nhiều giờ, không đáp ứng được tốc độ phát hành phần mềm nhanh hiện nay.
  * **Dễ sai sót do con người:** Thao tác gõ nhầm lệnh hoặc cấu hình thiếu sót dễ dẫn đến lỗ hổng bảo mật.
  * **Trôi dạt cấu hình:** Môi trường phát triển, thử nghiệm và vận hành thực tế bị lệch nhau theo thời gian do các can thiệp thủ công, gây ra lỗi ứng dụng chạy được ở máy cục bộ nhưng hỏng trên máy chủ.
  * **Khôi phục sự cố kém:** Khi máy chủ gặp sự cố, việc dựng lại phụ thuộc vào trí nhớ cá nhân hoặc tài liệu hướng dẫn cũ.
* **Giải pháp tự động hóa đề xuất:**
  * Áp dụng mô hình hạ tầng dưới dạng mã nguồn: Biến toàn bộ máy chủ, mạng và dịch vụ thành mã nguồn lưu trữ trên Git, đảm bảo tính nhất quán và khả năng tạo lại toàn bộ hệ thống từ con số 0 chỉ với một câu lệnh.
  * Lựa chọn kết hợp **Terraform** (chuyên trách khởi tạo phần cứng, máy ảo) và **Ansible** (chuyên trách cấu hình hệ điều hành, bảo mật và cài đặt dịch vụ) cùng với Docker và GitHub Actions để tạo chu trình tự động hóa khép kín.

---

## 2. Mục tiêu nghiên cứu
* **Mục tiêu tổng quát:** Làm chủ quy trình tự động hóa hạ tầng và phân phối phần mềm liên tục theo chuẩn DevOps, xây dựng mô hình thực nghiệm hoàn chỉnh và báo cáo chuyên đề khoa học.
* **Mục tiêu cụ thể:**
  * Hiểu rõ bản chất lý thuyết DevOps, sự khác biệt giữa khởi tạo hạ tầng và quản lý cấu hình, nguyên lý tính nhất quán và hạ tầng bất biến.
  * Xây dựng kịch bản Terraform tự động cấp phát cụm 2 máy ảo Ubuntu và tự sinh tệp danh mục máy chủ cho Ansible.
  * Xây dựng kịch bản Ansible tự động bảo mật hệ điều hành, cài đặt Docker Engine và máy chủ chuyển tiếp Nginx.
  * Xây dựng đường ống GitHub Actions tự động kiểm thử mã nguồn, đóng gói và triển khai ứng dụng.
  * Thu thập số liệu đo lường định lượng về thời gian khởi tạo, tốc độ triển khai và khả năng khôi phục sau sự cố.

---

## 3. Đối tượng và phạm vi nghiên cứu
* **Đối tượng nghiên cứu:**
  * Nguyên lý: Văn hóa DevOps, hạ tầng dưới dạng mã nguồn, tính nhất quán, chu trình tích hợp và triển khai liên tục.
  * Công nghệ: Terraform, Ansible, Docker, Docker Compose, Nginx, GitHub Actions, Canonical Multipass.
* **Phạm vi nghiên cứu:**
  * **Trong phạm vi:** Môi trường máy ảo Ubuntu chạy cục bộ trên Multipass (tiết kiệm 100% chi phí máy chủ đám mây), cụm 2 máy chủ gồm máy chủ ứng dụng và máy chủ cơ sở dữ liệu, ứng dụng backend REST API, đo lường định lượng các chỉ số hiệu năng.
  * **Ngoài phạm vi:** Không triển khai cụm Kubernetes quy mô lớn, không sử dụng dịch vụ đám mây trả phí, không đi sâu tối ưu thuật toán nghiệp vụ nội bộ của ứng dụng mẫu.

---

## 4. Phương pháp nghiên cứu
* **Nghiên cứu tài liệu:** Tổng hợp và phân tích tài liệu kỹ thuật chính thống từ HashiCorp, Red Hat và Docker.
* **Thực nghiệm phát triển:** Trực tiếp viết mã nguồn Terraform, kịch bản Ansible, tệp Dockerfile và quy trình GitHub Actions.
* **Đo lường định lượng:** Bấm giờ thực tế qua các lần chạy lặp lại để lấy số liệu trung bình thống kê.
* **So sánh đối chiếu:** Đánh giá định lượng hiệu quả giữa phương pháp quản trị thủ công và phương pháp tự động hóa.

---

## 5. Kết quả dự kiến đạt được
* **Về mặt kỹ thuật:** Kho mã nguồn Git hoàn chỉnh cho phép tạo hạ tầng và đưa ứng dụng vào hoạt động chỉ với một câu lệnh; hệ thống tự động cập nhật phiên bản mới khi có mã nguồn đẩy lên Git.
* **Về mặt học thuật:** Bộ số liệu thực nghiệm chứng minh giải pháp tự động giúp giảm 80-85% thời gian khởi tạo và 95% thời gian khôi phục sự cố; hoàn thiện toàn văn báo cáo chuyên đề 5 chương và bản trình chiếu bảo vệ trước hội đồng.
