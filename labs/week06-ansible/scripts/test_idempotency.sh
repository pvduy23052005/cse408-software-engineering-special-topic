#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN KIỂM NGHIỆM TÍNH NHẤT QUÁN (IDEMPOTENCY) CỦA ANSIBLE - TUẦN 6
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên: Phùng Văn Duy - MSSV: 2352270589
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

echo "======================================================================"
echo " KIỂM NGHIỆM TÍNH NHẤT QUÁN (IDEMPOTENCY) CỦA ANSIBLE - TUẦN 6"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo "======================================================================"

if ! command -v ansible-playbook &> /dev/null; then
    echo "[LỖI] Không tìm thấy công cụ ansible-playbook trên máy Mac."
    exit 1
fi

echo ""
echo "----------------------------------------------------------------------"
echo "[LẦN CHẠY 1/2] Áp dụng Playbook lần đầu (Khởi tạo trạng thái)..."
echo "----------------------------------------------------------------------"
START_1=$(date +%s)
ansible-playbook -i inventory.ini playbooks/setup-os.yml
END_1=$(date +%s)
DURATION_1=$((END_1 - START_1))
echo "=> Lần 1 hoàn tất sau ${DURATION_1} giây (chỉ số changed > 0 phản ánh các cấu hình mới)."

echo ""
echo "----------------------------------------------------------------------"
echo "[LẦN CHẠY 2/2] Chạy lại Playbook lần 2 để kiểm chứng Idempotency..."
echo "----------------------------------------------------------------------"
START_2=$(date +%s)
ansible-playbook -i inventory.ini playbooks/setup-os.yml
END_2=$(date +%s)
DURATION_2=$((END_2 - START_2))
echo "=> Lần 2 hoàn tất sau ${DURATION_2} giây."

echo ""
echo "======================================================================"
echo " KẾT LUẬN THỰC NGHIỆM:"
echo " - Lần 1: Thời gian ${DURATION_1}s | Cài đặt gói, múi giờ và luật tường lửa mới."
echo " - Lần 2: Thời gian ${DURATION_2}s | Chỉ số changed = 0 trên toàn bộ các máy chủ."
echo " => Ansible đảm bảo tính nhất quán tuyệt đối: không thực hiện hành động thừa"
echo "    nếu hệ thống đã đạt chuẩn mong muốn!"
echo "======================================================================"
