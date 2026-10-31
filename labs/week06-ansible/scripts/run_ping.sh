#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN KIỂM TRA KẾT NỐI CỤM MÁY CHỦ BẰNG ANSIBLE PING - TUẦN 6
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên: Phùng Văn Duy - MSSV: 2352270589
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}"

echo "======================================================================"
echo " KIỂM TRA KẾT NỐI SSH CỤM MÁY CHỦ VỚI ANSIBLE AD-HOC PING - TUẦN 6"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Thư mục thực thi: ${LAB_DIR}"
echo "======================================================================"

if ! command -v ansible &> /dev/null; then
    echo "[LỖI] Không tìm thấy công cụ Ansible trên máy Mac."
    echo "Vui lòng cài đặt qua lệnh: brew install ansible"
    exit 1
fi

echo "[1/2] Phiên bản Ansible: $(ansible --version | head -n 1)"
echo "[2/2] Đang gửi tín hiệu kiểm tra kết nối tới nhóm 'cluster'..."
echo "----------------------------------------------------------------------"
ansible -i inventory.ini cluster -m ping
echo "----------------------------------------------------------------------"
echo "=> Nếu cả 2 máy đều phản hồi SUCCESS kèm 'ping: pong', kết nối đã thông suốt!"
