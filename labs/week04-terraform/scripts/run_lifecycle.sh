#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN THỰC THI TỰ ĐỘNG VÒNG ĐỜI LỆNH CỐT LÕI CỦA TERRAFORM - TUẦN 4
# Khởi tạo và quản lý 1 máy ảo ứng dụng đầu tiên (test-tf)
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

echo "======================================================================"
echo " CHƯƠNG TRÌNH THỰC NGHIỆM VÒNG ĐỜI TERRAFORM (1 MÁY ẢO) - TUẦN 4"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Thư mục thực thi: ${LAB_DIR}"
echo "======================================================================"

# 0. Kiểm tra công cụ Terraform hoặc OpenTofu
TF_BIN=""
if command -v terraform &> /dev/null; then
    TF_BIN="terraform"
elif command -v tofu &> /dev/null; then
    TF_BIN="tofu"
else
    echo "[CẢNH BÁO] Không tìm thấy 'terraform' hoặc 'tofu' trên biến môi trường PATH."
    echo "Hướng dẫn cài đặt nhanh qua Homebrew trên macOS:"
    echo "  brew tap hashicorp/tap"
    echo "  brew install hashicorp/tap/terraform"
    echo "  (hoặc: brew install opentofu)"
    exit 1
fi

echo "[0/7] Công cụ sử dụng: $("${TF_BIN}" -version | head -n 1)"
echo ""

# 1. Định dạng mã nguồn HCL
echo "----------------------------------------------------------------------"
echo "[1/7] BƯỚC 1: ĐỊNH DẠNG MÃ NGUỒN (terraform fmt)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" fmt -recursive
echo "=> Đã chuẩn hóa định dạng các tệp mã nguồn HCL theo quy chuẩn HashiCorp."
echo ""

# 2. Khởi tạo môi trường Terraform
echo "----------------------------------------------------------------------"
echo "[2/7] BƯỚC 2: KHỞI TẠO MÔI TRƯỜNG & TẢI PROVIDER (terraform init)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" init
echo "=> Khởi tạo thành công thư mục .terraform và tệp khóa phụ thuộc."
echo ""

# 3. Kiểm tra tính đúng đắn của cú pháp
echo "----------------------------------------------------------------------"
echo "[3/7] BƯỚC 3: KIỂM TRA TÍNH ĐÚNG ĐẮN CỦA CÚ PHÁP (terraform validate)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" validate
echo "=> Toàn bộ khối tài nguyên và biến hợp lệ."
echo ""

# 4. Lập kế hoạch thực thi
echo "----------------------------------------------------------------------"
echo "[4/7] BƯỚC 4: LẬP KẾ HOẠCH THỰC THI (terraform plan)"
echo "----------------------------------------------------------------------"
PLAN_FILE="${LAB_DIR}/tfplan.binary"
"${TF_BIN}" plan -out="${PLAN_FILE}"
echo "=> Đã tạo kế hoạch thay đổi nhị phân an toàn tại: ${PLAN_FILE}"
echo ""

# 5. Áp dụng kế hoạch thực thi
echo "----------------------------------------------------------------------"
echo "[5/7] BƯỚC 5: ÁP DỤNG THAY ĐỔI VÀ CẤP PHÁT (terraform apply)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" apply "${PLAN_FILE}"
rm -f "${PLAN_FILE}"
echo "=> Hoàn tất cấp phát tài nguyên và cập nhật tệp trạng thái terraform.tfstate."
echo ""

# 6. Kiểm tra tệp trạng thái và dữ liệu đầu ra
echo "----------------------------------------------------------------------"
echo "[6/7] BƯỚC 6: KIỂM TRA TRẠNG THÁI & TRÍCH XUẤT ĐẦU RA (terraform output)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" output
echo ""
echo "Chi tiết cấu trúc JSON xuất ra:"
"${TF_BIN}" output -json
echo ""

if [ -f "${LAB_DIR}/server_spec.json" ]; then
    echo "Nội dung tệp đặc tả server_spec.json vừa được sinh:"
    cat "${LAB_DIR}/server_spec.json"
    echo ""
fi

# 7. Tùy chọn thu hồi tài nguyên
echo "----------------------------------------------------------------------"
echo "[7/7] HOÀN TẤT VÒNG ĐỜI KHỞI TẠO VÀ CẤP PHÁT HẠ TẦNG CHO 1 MÁY ẢO"
echo "----------------------------------------------------------------------"
echo "Để thu hồi và dọn dẹp sạch sẽ hạ tầng, bạn có thể chạy:"
echo "  cd ${LAB_DIR} && ${TF_BIN} destroy -auto-approve"
echo "======================================================================"
