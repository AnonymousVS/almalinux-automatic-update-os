#!/bin/bash
# =================================================================
# Auto Setup: KernelCare (Rebootless Kernel Patching)
# Optimized for: AlmaLinux + cPanel/WHM + Imunify360
# =================================================================

# --- ฟังก์ชันข้อความแจ้งเตือน ---
log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]  $*"; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [✅ OK]  $*"; }
warn()    { echo "$(date '+%Y-%m-%d %H:%M:%S') [⚠️  WARN] $*"; }
error()   { echo "$(date '+%Y-%m-%d %H:%M:%S') [❌ ERR]  $*" >&2; }

# --- 1. ตรวจสอบสิทธิ์ Root ---
if [[ $EUID -ne 0 ]]; then
    error "กรุณารันสคริปต์นี้ด้วยสิทธิ์ root เท่านั้น"
    exit 1
fi

log ">>> เริ่มต้นตรวจสอบและตั้งค่า KernelCare..."

# --- 2. ตรวจสอบและติดตั้ง KernelCare ---
if ! command -v kcarectl &>/dev/null; then
    # ถ้ามี Imunify360 ให้ดึง License มาใช้
    if command -v imunify360-agent &>/dev/null; then
        log "พบ Imunify360 — กำลังติดตั้ง KernelCare ผ่านระบบ Imunify..."
        imunify360-agent features install kernelcare
    else
        # ถ้าไม่มี Imunify360 ให้โหลดแบบ Standalone
        log "ไม่พบ Imunify360 — กำลังติดตั้ง KernelCare แบบ Standalone..."
        KC_INSTALLER="/tmp/kc_installer_$$.sh"
        curl -sSL https://kernelcare.com/installer -o "$KC_INSTALLER" || {
            error "ดาวน์โหลด KernelCare installer ล้มเหลว"
            exit 1
        }
        bash "$KC_INSTALLER" || {
            error "รันติดตั้ง KernelCare ล้มเหลว"
            rm -f "$KC_INSTALLER"
            exit 1
        }
        rm -f "$KC_INSTALLER"
    fi
else
    log "ระบบมี KernelCare ติดตั้งไว้อยู่แล้ว — ข้ามขั้นตอนการติดตั้ง"
fi

# --- 3. เปิดระบบ Auto-Update ให้ทำงานอัตโนมัติ ---
if command -v kcarectl &>/dev/null; then
    kcarectl --update     && log "KernelCare: อัปเดต Patch เป็นเวอร์ชันล่าสุดแล้ว"
    kcarectl --auto-update && log "KernelCare: เปิดโหมด Auto-Update สำเร็จ"
    
    echo ""
    echo "=================================================="
    success "🎉 Setup เสร็จสมบูรณ์! ระบบพร้อมทำ Rebootless Patching"
    echo "=================================================="
    kcarectl --info 2>/dev/null
else
    error "การตั้งค่า KernelCare ไม่สำเร็จ กรุณาตรวจสอบ License"
    exit 1
fi
