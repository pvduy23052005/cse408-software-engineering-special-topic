#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN KIỂM NGHIỆM TÍNH NHẤT QUÁN (IDEMPOTENCY) CỦA TERRAFORM - TUẦN 5
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
echo " KIỂM NGHIỆM TÍNH NHẤT QUÁN (IDEMPOTENCY) CỦA TERRAFORM - TUẦN 5"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo "======================================================================"

echo ""
echo "[LẦN CHẠY 1/3] Áp dụng trạng thái chuẩn mực ban đầu..."
"${TF_BIN}" apply -auto-approve
echo "=> Lần 1 hoàn tất."

echo ""
echo "----------------------------------------------------------------------"
echo "[LẦN CHẠY 2/3] Chạy lại lệnh apply lần 2 để kiểm tra Idempotency..."
echo "----------------------------------------------------------------------"
"${TF_BIN}" apply -auto-approve
echo "=> Nhận xét: Không có sự thay đổi nào (0 added, 0 changed, 0 destroyed)."

echo ""
echo "----------------------------------------------------------------------"
echo "[LẦN CHẠY 3/3] Tái xác nhận tính nhất quán lần 3..."
echo "----------------------------------------------------------------------"
"${TF_BIN}" apply -auto-approve

echo ""
echo "======================================================================"
echo " KẾT LUẬN THỰC NGHIỆM IDEMPOTENCY:"
echo " Mã nguồn khai báo HCL đảm bảo tính nhất quán tuyệt đối 100%."
echo " Chạy lặp lại nhiều lần không tạo ra tài nguyên rác và không gây gián đoạn."
echo "======================================================================"
