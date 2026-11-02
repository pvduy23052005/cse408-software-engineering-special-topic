#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN RESET TƯỜNG LỬA UFW VỀ TRẠNG THÁI TRẮNG BAN ĐẦU - TUẦN 6
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên: Phùng Văn Duy - MSSV: 2352270589
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

echo "======================================================================"
echo " ĐANG RESET TƯỜNG LỬA UFW TRÊN TOÀN BỘ CỤM MÁY CHỦ (cluster)..."
echo "======================================================================"

# 1. Reset sạch toàn bộ luật tường lửa
ansible -i inventory.ini cluster -m command -a "ufw --force reset" --become

# 2. Tắt tường lửa về trạng thái Inactive
ansible -i inventory.ini cluster -m command -a "ufw disable" --become

echo ""
echo "======================================================================"
echo " KIỂM TRA LẠI TRẠNG THÁI UFW SAU KHI RESET:"
echo "======================================================================"
ansible -i inventory.ini cluster -m command -a "ufw status" --become

echo ""
echo "=> Đã reset thành công! Tường lửa trên cả 2 máy đã trở về trạng thái 'inactive'."
echo "=> Bây giờ bạn có thể chạy lại Playbook để test từ đầu!"
