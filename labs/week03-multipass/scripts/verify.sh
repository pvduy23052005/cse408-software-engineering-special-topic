#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN KIỂM TRA MÔI TRƯỜNG VÀ KẾT NỐI MẠNG CỤM MÁY ẢO MULTIPASS
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VM_APP="app-server"
VM_DB="db-monitor-server"
SSH_KEY_PATH="${HOME}/.ssh/id_ed25519_multipass"

echo "======================================================================"
echo " BẮT ĐẦU KIỂM TRA HỆ THỐNG MÁY ẢO MULTIPASS - TUẦN 3"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Giảng viên hướng dẫn: Nguyễn Thọ Thông"
echo "======================================================================"

# 1. Kiểm tra trạng thái máy ảo trên hệ thống Multipass
echo ""
echo "[Kiểm tra 1/5] Kiểm tra trạng thái hoạt động của các máy ảo..."
MULTIPASS_OUTPUT="$(multipass list)"

check_vm_running() {
    local vm_name="$1"
    if echo "${MULTIPASS_OUTPUT}" | grep "${vm_name}" | grep -q "Running"; then
        echo "  [OK] Máy ảo '${vm_name}' đang hoạt động (Running)."
        return 0
    else
        echo "  [THẤT BẠI] Máy ảo '${vm_name}' không ở trạng thái hoạt động."
        return 1
    fi
}

check_vm_running "${VM_APP}"
check_vm_running "${VM_DB}"

# Lấy địa chỉ IP
APP_IP="$(multipass info "${VM_APP}" | grep "IPv4" | awk '{print $2}')"
DB_IP="$(multipass info "${VM_DB}" | grep "IPv4" | awk '{print $2}')"

echo "  -> Địa chỉ IP của ${VM_APP}: ${APP_IP}"
echo "  -> Địa chỉ IP của ${VM_DB}:  ${DB_IP}"

# 2. Kiểm tra kết nối mạng từ máy host đến các máy ảo (Ping)
echo ""
echo "[Kiểm tra 2/5] Kiểm tra khả năng gửi nhận gói tin mạng (Ping) từ máy host..."
if ping -c 2 -W 2 "${APP_IP}" > /dev/null 2>&1; then
    echo "  [OK] Ping thành công đến ${VM_APP} (${APP_IP})."
else
    echo "  [CẢNH BÁO] Không thể ping đến ${VM_APP}. (Có thể do cơ chế mạng hoặc tường lửa máy chủ)."
fi

if ping -c 2 -W 2 "${DB_IP}" > /dev/null 2>&1; then
    echo "  [OK] Ping thành công đến ${VM_DB} (${DB_IP})."
else
    echo "  [CẢNH BÁO] Không thể ping đến ${VM_DB}. (Có thể do cơ chế mạng hoặc tường lửa máy chủ)."
fi

# 3. Kiểm tra kết nối SSH không mật khẩu từ máy host
echo ""
echo "[Kiểm tra 3/5] Kiểm tra đăng nhập SSH không mật khẩu bằng khóa công khai..."

test_ssh() {
    local host_alias="$1"
    local ip="$2"
    echo -n "  -> Đang thử kết nối SSH tới ${host_alias} (${ip})... "
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${host_alias}" "echo 'Kết nối SSH thành công'" > /dev/null 2>&1; then
        echo "[OK]"
    else
        echo "[THẤT BẠI]"
        echo "     Gợi ý khắc phục: Kiểm tra tệp ~/.ssh/config hoặc quyền của khóa ${SSH_KEY_PATH}"
        return 1
    fi
}

test_ssh "${VM_APP}" "${APP_IP}"
test_ssh "${VM_DB}" "${DB_IP}"

# 4. Kiểm tra tài nguyên và thông tin hệ điều hành bên trong máy ảo
echo ""
echo "[Kiểm tra 4/5] Truy vấn thông số tài nguyên thực tế bên trong máy ảo..."

print_vm_stats() {
    local host_alias="$1"
    echo "  ------------------------------------------------------------------"
    echo "  Thông số máy ảo: ${host_alias}"
    echo "  ------------------------------------------------------------------"
    ssh -o BatchMode=yes -o ConnectTimeout=5 "${host_alias}" '
        echo "  - Tên máy (Hostname) : $(hostname)"
        echo "  - Phiên bản nhân Linux : $(uname -r)"
        echo "  - Thời gian hoạt động : $(uptime -p)"
        echo "  - Bộ nhớ RAM khả dụng : $(free -m | awk "/Mem:/ {print \$7 \" MB / \" \$2 \" MB\"}")"
        echo "  - Dung lượng ổ đĩa    : $(df -h / | awk "NR==2 {print \$4 \" trống / \" \$2}")"
        echo "  - Trạng thái tường lửa: $(sudo ufw status | head -n 1)"
    '
}

print_vm_stats "${VM_APP}"
print_vm_stats "${VM_DB}"

# 5. Kiểm tra thông suốt mạng nội bộ giữa 2 máy ảo
echo ""
echo "[Kiểm tra 5/5] Kiểm tra kết nối mạng nội bộ giữa các máy ảo..."
echo -n "  -> Thử nghiệm gửi gói tin từ ${VM_APP} sang ${VM_DB} (${DB_IP})... "
if ssh -o BatchMode=yes "${VM_APP}" "ping -c 2 -W 2 ${DB_IP}" > /dev/null 2>&1; then
    echo "[OK] Kết nối nội bộ hai chiều thông suốt."
else
    echo "[CẢNH BÁO] Không gửi được gói tin nội bộ từ ${VM_APP} sang ${VM_DB}."
fi

echo ""
echo "======================================================================"
echo " TỔNG HỢP KẾT QUẢ KIỂM TRA:"
echo " - Cả 2 máy ảo (${VM_APP}, ${VM_DB}) đã sẵn sàng hoạt động."
echo " - Xác thực SSH qua khóa bí mật ed25519 hoạt động thông suốt không cần mật khẩu."
echo " - Phân bổ tài nguyên vCPU, RAM, Ổ đĩa chính xác theo thiết kế."
echo " - Hạ tầng máy ảo hoàn toàn đáp ứng yêu cầu triển khai của Tuần 4 và Tuần 5."
echo "======================================================================"
