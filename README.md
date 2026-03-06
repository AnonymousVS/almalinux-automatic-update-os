# almalinux-automatic-update-os

สคริปต์ติดตั้งระบบอัปเดต OS อัตโนมัติสำหรับ **AlmaLinux 9** รองรับ WHM/cPanel + Imunify360

---

## ฟีเจอร์

- ✅ **dnf-automatic** — อัปเดตทุก Package อัตโนมัติ (รวม Security patch) ทุกวันเวลาตี 4
- ✅ **KernelCare** — อัปเดต Kernel โดยไม่ต้อง Reboot
- ✅ รองรับ **Imunify360** — ใช้ KernelCare License Bundle ฟรี
- ✅ ไม่ชนกับ **upcp** (cPanel updater รันตี 2)
- ✅ ไม่ Reboot เครื่องเอง

---

## ความต้องการของระบบ

| รายการ | รายละเอียด |
|---|---|
| OS | AlmaLinux 9 |
| สิทธิ์ | root เท่านั้น |
| WHM/cPanel | รองรับ (ไม่ชนกัน) |
| Imunify360 | แนะนำ (ใช้ KernelCare ฟรี) |

---

## วิธีติดตั้ง

### วิธีที่ 1 — รันจาก GitHub โดยตรง (แนะนำ)

```bash
curl -s -L https://raw.githubusercontent.com/<your-user>/almalinux-automatic-update-os/main/auto-update-os.sh -o /tmp/auto-update-os.sh && bash /tmp/auto-update-os.sh
```

### วิธีที่ 2 — Clone แล้วรัน

```bash
git clone https://github.com/<your-user>/almalinux-automatic-update-os.git
cd almalinux-automatic-update-os
chmod +x auto-update-os.sh
bash auto-update-os.sh
```

---

## ตรวจสอบหลังติดตั้ง

```bash
# เช็ค dnf-automatic timer ว่าทำงานอยู่ไหม
systemctl status dnf-automatic.timer

# ดู Log การอัปเดต
journalctl -u dnf-automatic -n 50

# เช็ค KernelCare
kcarectl --info
```

---

## ผลลัพธ์ที่ได้หลังรันสคริปต์

```
dnf-automatic   → อัปเดตทุก Package    → ทุกวัน ตี 4 อัตโนมัติ
KernelCare      → อัปเดต Kernel        → ไม่ต้อง Reboot
upcp (cPanel)   → อัปเดต WHM/cPanel    → ทุกวัน ตี 2 (แยกกัน)
```

---

## License

MIT
