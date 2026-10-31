#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN THỰC THI PLAYBOOK CHUẨN HÓA HỆ ĐIỀU HÀNH - TUẦN 6
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên: Phùng Văn Duy - MSSV: 2352270589
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

echo "======================================================================"
echo " THỰC THI PLAYBOOK ANSIBLE CHUẨN HÓA HỆ ĐIỀU HÀNH - TUẦN 6"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Playbook: playbooks/setup-os.yml"
echo "======================================================================"

if ! command -v ansible-playbook &> /dev/null; then
    echo "[LỖI] Không tìm thấy công cụ ansible-playbook trên máy Mac."
    echo "Vui lòng cài đặt qua lệnh: brew install ansible"
    exit 1
fi

echo "[1/2] Kiểm tra cú pháp kịch bản Playbook (Syntax Check)..."
ansible-playbook -i inventory.ini playbooks/setup-os.yml --syntax-check
echo "=> Cú pháp hợp lệ."
echo ""

echo "[2/2] Bắt đầu thực thi Playbook trên cụm máy chủ..."
echo "----------------------------------------------------------------------"
ansible-playbook -i inventory.ini playbooks/setup-os.yml
echo "----------------------------------------------------------------------"
echo "=> Hoàn tất chuẩn hóa hệ điều hành và thiết lập chính sách tường lửa UFW!"
