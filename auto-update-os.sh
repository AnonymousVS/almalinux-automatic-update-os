#!/bin/bash
# =================================================================
# Auto Update Setup
# - dnf-automatic (OS Full Updates รวม Security)
# - KernelCare (Rebootless Kernel Patching)
# Compatible: AlmaLinux 9 + WHM/cPanel + Imunify360
# =================================================================

# -----------------------------------------------------------------
# ฟังก์ชันช่วยเหลือ
# -----------------------------------------------------------------
log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]  $*"; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [✅ OK]  $*"; }
warn()    { echo "$(date '+%Y-%m-%d %H:%M:%S') [⚠️  WARN] $*"; }
error()   { echo "$(date '+%Y-%m-%d %H:%M:%S') [❌ ERR]  $*" >&2; }

# ฟังก์ชัน: ตั้งค่า key=value ใน config file อย่างปลอดภัย
# ถ้า key มีอยู่แล้ว → แก้ไข | ถ้าไม่มี → เพิ่มใหม่
set_config() {
    local key="$1"
    local value="$2"
    local file="$3"

    if grep -qE "^${key}[[:space:]]*=" "$file"; then
        sed -i -E "s|^${key}[[:space:]]*=.*|${key} = ${value}|" "$file"
    else
        echo "${key} = ${value}" >> "$file"
        warn "${key} ไม่มีใน config เดิม → เพิ่มใหม่แล้ว"
    fi
}

# -----------------------------------------------------------------
# 0. ตรวจสอบสิทธิ์ Root
# -----------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    error "กรุณารันสคริปต์นี้ด้วย root เท่านั้น"
    exit 1
fi
log "Root permission: OK"

# =================================================================
# 1. ติดตั้งและตั้งค่า dnf-automatic
# =================================================================
log ">>> Setting up dnf-automatic..."

# 1.1 ติดตั้ง dnf-automatic ถ้ายังไม่มี
if ! rpm -q dnf-automatic &>/dev/null; then
    log "ติดตั้ง dnf-automatic..."
    dnf install dnf-automatic -y || {
        error "ติดตั้ง dnf-automatic ล้มเหลว — หยุดการทำงาน"
        exit 1
    }
else
    log "dnf-automatic มีอยู่แล้ว — ข้ามการติดตั้ง"
fi

# 1.2 ตั้งค่า Config
CONF_FILE="/etc/dnf/automatic.conf"

if [[ ! -f "$CONF_FILE" ]]; then
    error "ไม่พบไฟล์ config: $CONF_FILE"
    exit 1
fi

# สำรองไฟล์ config เดิมก่อนแก้ไข
cp "$CONF_FILE" "${CONF_FILE}.bak.$(date +%Y%m%d%H%M%S)"
log "สำรอง config เดิมแล้ว"

# อัปเดตทุก Package (รวม Security ด้วย)
set_config "upgrade_type"    "default"   "$CONF_FILE"

# ดาวน์โหลดและติดตั้งอัตโนมัติ
set_config "download_updates" "yes"      "$CONF_FILE"
set_config "apply_updates"    "yes"      "$CONF_FILE"

# ห้าม Reboot เด็ดขาด (ใช้ KernelCare แทน)
set_config "reboot"           "never"    "$CONF_FILE"

# 1.3 ตั้งเวลาให้ห่างจาก upcp (upcp รันตี 2 → ตั้งเป็นตี 4)
TIMER_OVERRIDE_DIR="/etc/systemd/system/dnf-automatic.timer.d"
mkdir -p "$TIMER_OVERRIDE_DIR"
cat > "${TIMER_OVERRIDE_DIR}/schedule.conf" <<EOF
[Timer]
OnCalendar=
OnCalendar=*-*-* 04:00:00
RandomizedDelaySec=30m
EOF
systemctl daemon-reload

# 1.4 เปิดใช้งาน Timer
systemctl enable --now dnf-automatic.timer || {
    error "เปิด dnf-automatic.timer ล้มเหลว"
    exit 1
}

# 1.5 ตรวจสอบว่า Timer ทำงานแล้วจริง
if systemctl is-active --quiet dnf-automatic.timer; then
    success "dnf-automatic.timer ทำงานแล้ว — ALL updates (รวม Security), No Reboot, เวลาตี 4"
else
    error "dnf-automatic.timer ไม่ได้ทำงาน"
    exit 1
fi

# =================================================================
# 2. จัดการ KernelCare
# =================================================================
log ">>> Setting up KernelCare..."

if ! command -v kcarectl &>/dev/null; then
    log "ไม่พบ KernelCare — เริ่มติดตั้ง..."

    # วิธีที่ 1: ติดตั้งผ่าน Imunify360 (ใช้ License Bundle ฟรี)
    if command -v imunify360-agent &>/dev/null; then
        log "พบ Imunify360 — ติดตั้ง KernelCare ผ่าน Imunify..."
        imunify360-agent features install kernelcare
    else
        warn "ไม่พบ Imunify360"
    fi

    # วิธีที่ 2: ถ้ายังไม่มี kcarectl → ติดตั้งแบบ Standalone
    if ! command -v kcarectl &>/dev/null; then
        log "ติดตั้ง KernelCare แบบ Standalone..."

        # ดาวน์โหลดก่อน ตรวจสอบแล้วค่อยรัน (ปลอดภัยกว่า pipe to bash)
        KC_INSTALLER="/tmp/kc_installer_$$.sh"
        curl -s -L https://kernelcare.com/installer -o "$KC_INSTALLER" || {
            error "ดาวน์โหลด KernelCare installer ล้มเหลว"
            exit 1
        }
        bash "$KC_INSTALLER" || {
            error "รัน KernelCare installer ล้มเหลว"
            rm -f "$KC_INSTALLER"
            exit 1
        }
        rm -f "$KC_INSTALLER"
    fi
else
    log "KernelCare มีอยู่แล้ว — ข้ามการติดตั้ง"
fi

# 2.1 ตรวจสอบและเปิด Auto-Update
if command -v kcarectl &>/dev/null; then
    kcarectl --update     && log "KernelCare: อัปเดต Patch แล้ว"
    kcarectl --auto-update && log "KernelCare: เปิด Auto-Update แล้ว"
    success "KernelCare ทำงานปกติ — Rebootless Kernel Patching พร้อมใช้งาน"
else
    error "KernelCare ติดตั้งไม่สำเร็จ — กรุณาตรวจสอบ License"
    exit 1
fi

# =================================================================
# 3. สรุปผลลัพธ์
# =================================================================
echo ""
echo "=================================================="
echo "🎉 Setup เสร็จสมบูรณ์!"
echo "=================================================="
echo ""
echo "  [dnf-automatic]"
echo "  • อัปเดตทุก Package อัตโนมัติ (รวม Security patch)"
echo "  • รันทุกวันเวลา 04:00 (ห่างจาก upcp ตี 2)"
echo "  • ไม่ Reboot เครื่องเอง"
echo ""
echo "  [KernelCare]"
kcarectl --info 2>/dev/null || echo "  • ไม่สามารถดึงข้อมูลได้"
echo ""
echo "  ดู Log ได้ที่:"
echo "  journalctl -u dnf-automatic -n 50"
echo "=================================================="
