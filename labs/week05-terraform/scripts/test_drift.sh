#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN KIỂM NGHIỆM PHÁT HIỆN TRÔI DẠT & TỰ CHỮA LÀNH (SELF-HEALING) - TUẦN 5
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên: Phùng Văn Duy - MSSV: 2352270589
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

TF_BIN=""
if command -v terraform &> /dev/null; then
    TF_BIN="terraform"
elif command -v tofu &> /dev/null; then
    TF_BIN="tofu"
else
    echo "[LỖI] Không tìm thấy terraform hoặc tofu trên PATH."
    exit 1
fi

echo "======================================================================"
echo " THỰC NGHIỆM PHÁT HIỆN TRÔI DẠT CẤU HÌNH & TỰ PHỤC HỒI - TUẦN 5"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo "======================================================================"

# 1. Đảm bảo hạ tầng đang ở trạng thái chuẩn mực
echo "[1/4] Đồng bộ hóa hạ tầng về trạng thái chuẩn..."
"${TF_BIN}" apply -auto-approve > /dev/null
echo "=> Trạng thái ban đầu đã được thiết lập đầy đủ."

# 2. Giả lập sự cố: Xóa ngoài luồng tệp inventory.ini
echo ""
echo "[2/4] Mô phỏng sự cố ngoài luồng (Out-of-band drift)..."
echo "      (Giả lập trường hợp kỹ sư vô tình xóa mất tệp inventory.ini)"
rm -f "${LAB_DIR}/inventory.ini"
echo "=> Tệp inventory.ini đã bị xóa mất khỏi hệ thống tệp tin."

# 3. Chạy terraform plan để phát hiện sai lệch
echo ""
echo "[3/4] Chạy lệnh 'terraform plan' để kiểm tra khả năng phát hiện trôi dạt..."
echo "----------------------------------------------------------------------"
"${TF_BIN}" plan
echo "----------------------------------------------------------------------"
echo "=> Nhận xét: Terraform tự động so sánh trạng thái thực tế và phát hiện"
echo "   tệp inventory.ini bị thiếu (hiển thị ký hiệu '+' create to add)."

# 4. Tự động khắc phục
echo ""
echo "[4/4] Áp dụng lại 'terraform apply -auto-approve' để tự động chữa lành..."
"${TF_BIN}" apply -auto-approve > /dev/null
echo "=> Tệp inventory.ini đã được tự động tái tạo hoàn chỉnh trong chưa đầy 1 giây!"
echo ""
echo "Nội dung tệp sau khi tự phục hồi:"
cat "${LAB_DIR}/inventory.ini"
echo ""

echo "======================================================================"
echo " KẾT LUẬN THỰC NGHIỆM:"
echo " Cơ chế State và Plan của Terraform giúp phát hiện ngay lập tức các mất mát,"
echo " và tự động chữa lành (Self-healing) đưa hệ thống về đúng thiết kế gốc."
echo "======================================================================"
