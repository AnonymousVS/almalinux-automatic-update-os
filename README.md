# KernelCare Auto Setup for AlmaLinux + cPanel/WHM

ติดตั้งและตั้งค่า KernelCare แบบอัตโนมัติ — Patch Kernel โดยไม่ต้อง Reboot เครื่อง

## Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/AnonymousVS/almalinux-kernelcare-setup/main/setup-kernelcare.sh | bash
```

## ทำไมต้องใช้สคริปต์นี้?

เซิร์ฟเวอร์ cPanel/WHM มีระบบ `upcp` → `sysup` ที่รัน `dnf update` ให้อัตโนมัติทุกคืนอยู่แล้ว **ไม่จำเป็นต้องใช้ `dnf-automatic` เพิ่ม**

แต่เมื่อ Kernel ถูกอัปเดต ปกติต้อง Reboot เครื่องถึงจะใช้งานได้ — **KernelCare แก้ปัญหานี้** โดย Patch Kernel ที่กำลังรันอยู่ในหน่วยความจำโดยตรง ไม่ต้อง Reboot

## สคริปต์ทำอะไรบ้าง?

1. ตรวจสอบว่ามี KernelCare อยู่แล้วหรือไม่
2. ถ้ายังไม่มี:
   - มี Imunify360 → ติดตั้งผ่าน Imunify (ได้ License ฟรีแบบ Bundle)
   - ไม่มี Imunify360 → ติดตั้งแบบ Standalone
3. อัปเดต Patch ล่าสุดและเปิด Auto-Update

## สิ่งที่ต้องมี

| รายการ | รายละเอียด |
|---|---|
| OS | AlmaLinux 9 |
| Control Panel | cPanel/WHM |
| สิทธิ์ | root |
| แนะนำ | Imunify360 (ได้ License KernelCare ฟรี) |

## การแบ่งหน้าที่อัปเดต

| หน้าที่ | ใครจัดการ |
|---|---|
| OS Package Update (`dnf update`) | cPanel `upcp` → `sysup` (ทุกคืน) |
| cPanel/WHM Update | cPanel `upcp` (ทุกคืน) |
| Kernel Live Patching (ไม่ต้อง Reboot) | **KernelCare** (สคริปต์นี้) |

## คำสั่งตรวจสอบหลังติดตั้ง

```bash
# เช็คสถานะ KernelCare
kcarectl --info

# เช็ค Patch ที่ใช้อยู่
kcarectl --patch-info

# อัปเดต Patch ด้วยมือ (ถ้าต้องการ)
kcarectl --update
```

## หมายเหตุ

- ถ้าเคยติดตั้ง `dnf-automatic` ไว้ ให้ปิดก่อนเพื่อไม่ให้ซ้ำซ้อนกับ `upcp`:
  ```bash
  systemctl disable --now dnf-automatic.timer
  ```
- ตรวจสอบว่า WHM → Server Configuration → Update Preferences → **Operating System Package Updates** ตั้งเป็น **Automatic** (ค่า Default)
