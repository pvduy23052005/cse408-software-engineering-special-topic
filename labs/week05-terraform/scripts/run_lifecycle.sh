#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN THỰC THI TỰ ĐỘNG VÒNG ĐỜI TERRAFORM & SINH INVENTORY - TUẦN 5
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

echo "======================================================================"
echo " VÒNG ĐỜI LỆNH TERRAFORM & TỰ ĐỘNG XUẤT BẢN INVENTORY - TUẦN 5"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Thư mục thực thi: ${LAB_DIR}"
echo "======================================================================"

# 0. Kiểm tra công cụ Terraform
TF_BIN=""
if command -v terraform &> /dev/null; then
    TF_BIN="terraform"
elif command -v tofu &> /dev/null; then
    TF_BIN="tofu"
else
    echo "[LỖI] Không tìm thấy terraform hoặc tofu trên PATH."
    exit 1
fi

echo "[0/6] Công cụ sử dụng: $("${TF_BIN}" -version | head -n 1)"
echo ""

# 1. Định dạng mã nguồn HCL
echo "----------------------------------------------------------------------"
echo "[1/6] BƯỚC 1: ĐỊNH DẠNG MÃ NGUỒN (terraform fmt)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" fmt -recursive
echo "=> Đã chuẩn hóa định dạng các tệp HCL theo quy chuẩn HashiCorp."
echo ""

# 2. Khởi tạo môi trường
echo "----------------------------------------------------------------------"
echo "[2/6] BƯỚC 2: KHỞI TẠO MÔI TRƯỜNG & TẢI PROVIDER (terraform init)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" init
echo "=> Khởi tạo thành công môi trường Terraform."
echo ""

# 3. Kiểm tra tính đúng đắn của cú pháp
echo "----------------------------------------------------------------------"
echo "[3/6] BƯỚC 3: KIỂM TRA TÍNH ĐÚNG ĐẮN CÚ PHÁP (terraform validate)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" validate
echo "=> Toàn bộ khối tài nguyên, biến và template hợp lệ."
echo ""

# 4. Lập kế hoạch thực thi
echo "----------------------------------------------------------------------"
echo "[4/6] BƯỚC 4: LẬP KẾ HOẠCH THỰC THI (terraform plan)"
echo "----------------------------------------------------------------------"
PLAN_FILE="${LAB_DIR}/tfplan.binary"
"${TF_BIN}" plan -out="${PLAN_FILE}"
echo "=> Đã lập kế hoạch an toàn tại: ${PLAN_FILE}"
echo ""

# 5. Áp dụng kế hoạch
echo "----------------------------------------------------------------------"
echo "[5/6] BƯỚC 5: ÁP DỤNG THAY ĐỔI (terraform apply)"
echo "----------------------------------------------------------------------"
"${TF_BIN}" apply "${PLAN_FILE}"
rm -f "${PLAN_FILE}"
echo "=> Cấp phát thành công và cập nhật tệp trạng thái terraform.tfstate."
echo ""

# 6. Kiểm tra tệp danh mục Ansible và dữ liệu đầu ra
echo "----------------------------------------------------------------------"
echo "[6/6] BƯỚC 6: KIỂM TRA KẾT QUẢ ĐẦU RA & TỆP INVENTORY SINH TỰ ĐỘNG"
echo "----------------------------------------------------------------------"
"${TF_BIN}" output
echo ""

if [ -f "${LAB_DIR}/inventory.ini" ]; then
    echo "======================================================================"
    echo " NỘI DUNG TỆP DANH MỤC MÁY CHỦ ANSIBLE (inventory.ini):"
    echo "======================================================================"
    cat "${LAB_DIR}/inventory.ini"
    echo ""
fi

if [ -f "${LAB_DIR}/cluster_spec.json" ]; then
    echo "======================================================================"
    echo " NỘI DUNG TỆP ĐẶC TẢ CỤM MÁY CHỦ JSON (cluster_spec.json):"
    echo "======================================================================"
    cat "${LAB_DIR}/cluster_spec.json"
    echo ""
fi

echo "======================================================================"
echo " HOÀN TẤT THÀNH CÔNG BÀI THỰC HÀNH TUẦN 5!"
echo " Tệp inventory.ini đã sẵn sàng để chuyển tiếp sang Tuần 6 (Ansible)."
echo "======================================================================"
