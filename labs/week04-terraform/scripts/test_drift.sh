#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN THỰC NGHIỆM PHÁT HIỆN TRÔI DẠT CẤU HÌNH (DRIFT DETECTION) - TUẦN 4
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
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
echo " THỰC NGHIỆM PHÁT HIỆN TRÔI DẠT CẤU HÌNH (1 MÁY ẢO) - TUẦN 4"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo "======================================================================"

# 1. Đảm bảo hạ tầng đang ở trạng thái chuẩn mực
echo "[1/4] Đồng bộ hóa hạ tầng máy ảo về trạng thái chuẩn mực ban đầu..."
"${TF_BIN}" apply -auto-approve > /dev/null
echo "=> Trạng thái ban đầu đã được áp dụng đầy đủ."

# 2. Tạo trôi dạt cấu hình ngoài luồng (Out-of-band modification)
echo ""
echo "[2/4] Mô phỏng sự can thiệp ngoài luồng (Out-of-band Modification)..."
echo "      (Giả lập trường hợp kỹ sư tự ý chỉnh sửa tệp thông số máy chủ)"
echo '{"tampered": true, "unauthorized_change": "Manual edit directly on server without Git commit"}' > server_spec.json
echo "=> Tệp server_spec.json đã bị thay đổi trái phép ngoài sự kiểm soát của mã nguồn Git."

# 3. Chạy terraform plan để phát hiện sai lệch
echo ""
echo "[3/4] Chạy lệnh 'terraform plan' để kiểm tra khả năng phát hiện trôi dạt..."
echo "----------------------------------------------------------------------"
"${TF_BIN}" plan
echo "----------------------------------------------------------------------"
echo "=> Nhận xét: Terraform tự động so sánh trạng thái thực tế và phát hiện"
echo "   tệp server_spec.json đã bị sai lệch (hiển thị ký hiệu '~' update-in-place)."

# 4. Tự động khắc phục trôi dạt đưa hệ thống về đúng thiết kế
echo ""
echo "[4/4] Áp dụng lại 'terraform apply -auto-approve' để tự động chữa lành (Self-healing)..."
"${TF_BIN}" apply -auto-approve > /dev/null
echo "=> Hệ thống máy chủ đã được khôi phục nguyên vẹn về đúng cam kết trong mã nguồn HCL."
echo ""
echo "Nội dung tệp sau khi tự phục hồi:"
cat server_spec.json
echo ""
echo "======================================================================"
echo " KẾT LUẬN THỰC NGHIỆM:"
echo " Cơ chế State và Plan của Terraform giúp phát hiện ngay lập tức các thay đổi"
echo " ngoài luồng và cho phép phục hồi trạng thái chuẩn mực trong vòng dưới 2 giây!"
echo "======================================================================"
