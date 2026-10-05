#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN TỰ ĐỘNG KHỞI TẠO CỤM MÁY ẢO THỰC HÀNH VỚI MULTIPASS
# Môn học: Chuyên đề Kỹ thuật Phần mềm (CSE408)
# Sinh viên thực hiện: Phùng Văn Duy - MSSV: 2352270589
# Giảng viên hướng dẫn: Nguyễn Thọ Thông
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_FILE="${LAB_DIR}/cloud-init.yaml.template"
RENDERED_FILE="${LAB_DIR}/cloud-init.yaml"

SSH_KEY_NAME="id_ed25519_multipass"
SSH_KEY_PATH="${HOME}/.ssh/${SSH_KEY_NAME}"
SSH_PUB_KEY_PATH="${SSH_KEY_PATH}.pub"

VM_APP="app-server"
VM_DB="db-monitor-server"

echo "======================================================================"
echo " KHỞI TẠO MÔI TRƯỜNG MÁY ẢO MULTIPASS - TUẦN 3"
echo " Sinh viên: Phùng Văn Duy - MSSV: 2352270589"
echo " Giảng viên hướng dẫn: Nguyễn Thọ Thông"
echo "======================================================================"

# 1. Kiểm tra công cụ Multipass
if ! command -v multipass &> /dev/null; then
    echo "[LỖI] Không tìm thấy công cụ Multipass trên máy tính."
    echo "Vui lòng cài đặt qua lệnh: brew install --cask multipass"
    exit 1
fi
echo "[1/6] Đã xác nhận công cụ Multipass có sẵn trên hệ thống."

# 2. Kiểm tra hoặc tạo cặp khóa SSH chuyên dụng
if [ ! -f "${SSH_PUB_KEY_PATH}" ]; then
    echo "[2/6] Đang khởi tạo cặp khóa SSH mới (${SSH_KEY_NAME})..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    ssh-keygen -t ed25519 -N "" -f "${SSH_KEY_PATH}" -C "duy-cse408-multipass"
    chmod 600 "${SSH_KEY_PATH}"
    chmod 644 "${SSH_PUB_KEY_PATH}"
    echo "      Đã tạo khóa SSH thành công tại: ${SSH_KEY_PATH}"
else
    echo "[2/6] Đã tìm thấy khóa SSH có sẵn tại: ${SSH_KEY_PATH}"
fi

SSH_PUBLIC_KEY_CONTENT="$(cat "${SSH_PUB_KEY_PATH}")"

# 3. Tạo tệp cấu hình Cloud-init từ tệp mẫu
echo "[3/6] Đang chuẩn bị tệp cấu hình Cloud-init..."
sed "s|__SSH_PUBLIC_KEY__|${SSH_PUBLIC_KEY_CONTENT}|g" "${TEMPLATE_FILE}" > "${RENDERED_FILE}"
echo "      Đã sinh tệp cấu hình tại: ${RENDERED_FILE}"

# 4. Khởi tạo máy ảo 1: app-server
if multipass list | grep -q "${VM_APP}"; then
    echo "[4/6] Máy ảo ${VM_APP} đã tồn tại trong hệ thống. Bỏ qua bước tạo mới."
else
    echo "[4/6] Đang khởi tạo máy ảo ${VM_APP} (Ubuntu 22.04 LTS, 1 CPU, 1.5GB RAM, 10GB đĩa)..."
    multipass launch 22.04 \
        --name "${VM_APP}" \
        --cpus 1 \
        --memory 1.5G \
        --disk 10G \
        --cloud-init "${RENDERED_FILE}"
    echo "      Khởi tạo ${VM_APP} thành công!"
fi

# 5. Khởi tạo máy ảo 2: db-monitor-server
if multipass list | grep -q "${VM_DB}"; then
    echo "[5/6] Máy ảo ${VM_DB} đã tồn tại trong hệ thống. Bỏ qua bước tạo mới."
else
    echo "[5/6] Đang khởi tạo máy ảo ${VM_DB} (Ubuntu 22.04 LTS, 1 CPU, 1.5GB RAM, 10GB đĩa)..."
    multipass launch 22.04 \
        --name "${VM_DB}" \
        --cpus 1 \
        --memory 1.5G \
        --disk 10G \
        --cloud-init "${RENDERED_FILE}"
    echo "      Khởi tạo ${VM_DB} thành công!"
fi

# 6. Thu thập địa chỉ IP và cập nhật cấu hình SSH
echo "[6/6] Đang thu thập địa chỉ IP và hoàn tất thiết lập..."

# Đợi máy ảo nhận địa chỉ IP
sleep 3
APP_IP="$(multipass info "${VM_APP}" | grep "IPv4" | awk '{print $2}')"
DB_IP="$(multipass info "${VM_DB}" | grep "IPv4" | awk '{print $2}')"

# Cập nhật tệp cấu hình SSH Client của máy host (~/.ssh/config) để thuận tiện kết nối
SSH_CONFIG_FILE="${HOME}/.ssh/config"
touch "${SSH_CONFIG_FILE}"

# Xóa các khối cấu hình cũ của hai máy ảo nếu đã tồn tại trước đó
if grep -q "Host ${VM_APP}" "${SSH_CONFIG_FILE}"; then
    sed -i '' "/Host ${VM_APP}/,/IdentityFile/d" "${SSH_CONFIG_FILE}" 2>/dev/null || true
fi
if grep -q "Host ${VM_DB}" "${SSH_CONFIG_FILE}"; then
    sed -i '' "/Host ${VM_DB}/,/IdentityFile/d" "${SSH_CONFIG_FILE}" 2>/dev/null || true
fi

# Ghi khối cấu hình mới
cat <<EOF >> "${SSH_CONFIG_FILE}"

# Khối cấu hình máy ảo Multipass - CSE408
Host ${VM_APP}
    HostName ${APP_IP}
    User ubuntu
    IdentityFile ${SSH_KEY_PATH}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host ${VM_DB}
    HostName ${DB_IP}
    User ubuntu
    IdentityFile ${SSH_KEY_PATH}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

# Xuất tệp thông tin nhanh cụm máy ảo
cat <<EOF > "${LAB_DIR}/cluster-info.txt"
THÔNG TIN CỤM MÁY ẢO THỰC HÀNH - CSE408
Thời gian tạo: $(date '+%Y-%m-%d %H:%M:%S')

1. Máy chủ ứng dụng (${VM_APP}):
   - Địa chỉ IP: ${APP_IP}
   - Hệ điều hành: Ubuntu 22.04 LTS
   - Cấu hình: 1 vCPU, 1.5 GB RAM, 10 GB Đĩa
   - Lệnh kết nối nhanh: ssh ${VM_APP} (hoặc: ssh -i ${SSH_KEY_PATH} ubuntu@${APP_IP})

2. Máy chủ cơ sở dữ liệu và giám sát (${VM_DB}):
   - Địa chỉ IP: ${DB_IP}
   - Hệ điều hành: Ubuntu 22.04 LTS
   - Cấu hình: 1 vCPU, 1.5 GB RAM, 10 GB Đĩa
   - Lệnh kết nối nhanh: ssh ${VM_DB} (hoặc: ssh -i ${SSH_KEY_PATH} ubuntu@${DB_IP})
EOF

echo ""
echo "======================================================================"
echo " HOÀN TẤT THIẾT LẬP CỤM MÁY ẢO MULTIPASS!"
echo "======================================================================"
echo " 1. ${VM_APP}: ${APP_IP} (Lệnh: ssh ${VM_APP})"
echo " 2. ${VM_DB}:  ${DB_IP}  (Lệnh: ssh ${VM_DB})"
echo " Thông tin chi tiết đã được lưu tại: ${LAB_DIR}/cluster-info.txt"
echo " Chạy kịch bản kiểm thử: bash scripts/verify.sh"
echo "======================================================================"
