#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN THU HỒI VÀ DỌN DẸP TÀI NGUYÊN MÁY ẢO MULTIPASS
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VM_APP="app-server"
VM_DB="db-monitor-server"
SSH_CONFIG_FILE="${HOME}/.ssh/config"

echo "======================================================================"
echo " TIẾN HÀNH THU HỒI TÀI NGUYÊN MÁY ẢO MULTIPASS - TUẦN 3"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Giảng viên hướng dẫn: Nguyễn Thọ Thông"
echo "======================================================================"

# 1. Dừng các máy ảo đang chạy
echo "[1/4] Đang dừng hoạt động các máy ảo thực hành..."
for vm in "${VM_APP}" "${VM_DB}"; do
    if multipass list | grep -q "${vm}"; then
        echo "  -> Đang dừng máy ảo '${vm}'..."
        multipass stop "${vm}" || true
    fi
done

# 2. Xóa và thu hồi tài nguyên đĩa cứng
echo "[2/4] Đang xóa các máy ảo và giải phóng bộ nhớ..."
for vm in "${VM_APP}" "${VM_DB}"; do
    if multipass list --all | grep -q "${vm}"; then
        echo "  -> Đang đánh dấu xóa máy ảo '${vm}'..."
        multipass delete "${vm}" || true
    fi
done

echo "  -> Đang thực thi thu hồi tài nguyên vĩnh viễn (purge)..."
multipass purge

# 3. Dọn dẹp khối cấu hình SSH trên máy host
echo "[3/4] Đang dọn dẹp khối cấu hình tạm thời trong ${SSH_CONFIG_FILE}..."
if [ -f "${SSH_CONFIG_FILE}" ]; then
    if grep -q "Host ${VM_APP}" "${SSH_CONFIG_FILE}"; then
        sed -i '' "/Host ${VM_APP}/,/IdentityFile/d" "${SSH_CONFIG_FILE}" 2>/dev/null || true
    fi
    if grep -q "Host ${VM_DB}" "${SSH_CONFIG_FILE}"; then
        sed -i '' "/Host ${VM_DB}/,/IdentityFile/d" "${SSH_CONFIG_FILE}" 2>/dev/null || true
    fi
    echo "  -> Đã làm sạch các mục cấu hình máy ảo trong tệp SSH của máy tính."
fi

# 4. Xóa các tệp tạo tạm trong thư mục lab
echo "[4/4] Dọn dẹp các tệp tạm trong thư mục bài lab..."
rm -f "${LAB_DIR}/cloud-init.yaml"
rm -f "${LAB_DIR}/cluster-info.txt"

echo ""
echo "======================================================================"
echo " ĐÃ DỌN DẸP VÀ GIẢI PHÓNG TOÀN BỘ TÀI NGUYÊN THÀNH CÔNG!"
echo " Hệ thống đã trở về trạng thái ban đầu sạch sẽ."
echo "======================================================================"
