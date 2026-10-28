# MyPOS — ระบบขายหน้าร้าน ที่เข้าใจสายผลิตตัวจริง 🐙🎨

[![Flutter](https://img.shields.io/badge/Flutter-3.38.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.8-0175C2?logo=dart)](https://dart.dev)
[![Offline-First](https://img.shields.io/badge/Offline--First-Hive%20Local%20DB-16A34A)](#-offline-first-architecture)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> ระบบ POS สำหรับขายสินค้าหน้าบูธงานอาร์ตแฟร์ (Art Fair / Creator Booth) ออกแบบมาสำหรับการใช้งานบน **iPad, Android Tablet, Web PWA และ Desktop** ทำงานแบบ **Offline-First 100%** ไม่มีเน็ตหน้างานก็ขายของและสร้าง QR Code ได้อย่างราบรื่น

---

## 🌟 จุดเด่นของระบบ (Key Features)

### 1. 📴 ทำงานออฟไลน์ 100% (Offline-First Architecture)
- บันทึกข้อมูลลงฐานข้อมูลเครื่องทันที (**Hive Local Database**) ไม่ต้องพึ่งพาเครือข่ายอินเทอร์เน็ตหน้างาน
- จัดการประวัติสต็อกผ่าน `StockMovement` ป้องกันการชนกันของสต็อกเวลาซิงก์
- แสดงแถบสถานะการซิงก์ (`ออฟไลน์พร้อม` หรือ `X รอซิงก์`) และมีระบบบล็อกการ Logout หากยังมีข้อมูลค้างซิงก์

### 2. 📁 หมวดหมู่สินค้าแบบโฟลเดอร์ (Category Folders - v1.5)
- ระบบโฟลเดอร์จัดระเบียบสินค้า 2 ระดับ (Root Folder → Subfolder) เข้าถึงสินค้าง่ายสำหรับร้านที่มีของหลายสิบชิ้น
- มีแถบ **Breadcrumb Navigation** (`คลังสินค้า > Sticker > ลายแมว`) กดเลือกย้อนกลับไปโฟลเดอร์หลักได้ทันที
- ปุ่มสลับดูแบบรวมทั้งหมด (**All Items**) และระบบ **Global Search** ค้นหาชื่อสินค้าข้ามทุกโฟลเดอร์ได้ทันที

### 3. 👥 ตะกร้าสินค้าแบบหลายศิลปิน (Multi-Artist Cart & Proportional Discounts)
- 1 บูธแชร์ขายร่วมกับศิลปินหลายคนได้ในบิลเดียวกัน โดยระบบ Snapshot `artist_id` ตอนขายจริง
- การ์ดสินค้าและรายการในตะกร้าแสดงป้ายชื่อศิลปินเจ้าของสินค้าชัดเจน
- **ส่วนลดเฉลี่ยสัดส่วนทั้งบิล (Proportional Discount)**: ระบบจะกระจายส่วนลดให้แต่ละศิลปินตามสัดส่วนมูลค่าสินค้าในบิลโดยอัตโนมัติ
- **ส่วนลดเฉพาะศิลปิน**: สามารถเลือกใส่ส่วนลดเฉพาะสินค้าของศิลปินท่านนั้นได้ โดยไม่กระทบศิลปินท่านอื่น

### 4. 💰 คิดค่าคอมมิชชัน & ปิดยอด (Commission & Settlement)
- กำหนดอัตราส่วนแบ่งคอมมิชชัน (`commission_rate %`) แยกเป็นรายศิลปิน
- หน้าสรุปยอด **Settlement**: สรุปยอดขายรวม (Gross), หักค่าคอมมิชชัน, และยอดสุทธิที่ต้องจ่ายคืนศิลปิน (Net Payout)
- บันทึกสถานะ "จ่ายแล้ว (Mark as Paid)" พร้อมโน้ตช่วยจำ
- ส่งออกรายงาน Settlement เป็นไฟล์ CSV

### 5. 💳 ชำระเงินรวดเร็ว เหมาะกับจอสัมผัส iPad
- **แป้นตัวเลขทัชสกรีน (Touch Numpad)**: กดรับเงินสดได้รวดเร็ว พร้อมปุ่มลัด `พอดี`, `+20`, `+50`, `+100`, `500`, `1000` และคำนวณเงินทอนอัตโนมัติ
- **พร้อมเพย์ QR แบบ Dynamic**: สร้าง QR Code พร้อมระบุยอดเงินตามมาตรฐาน **EMVCo / BOT PromptPay** สร้างได้โดย **ไม่ต้องต่ออินเทอร์เน็ต**

### 6. 🔐 ระบบสมาชิกทีมงาน & สิทธิ์การมองเห็น (Team & Visibility)
- บทบาท **Owner** (เจ้าของร้าน): จัดการร้าน, เชิญสมาชิก, ดูยอดและรายงานทั้งหมด
- บทบาท **Member** (ทีมงานช่วยขาย): ดูสินค้าและขายของได้ **แต่ซ่อนราคาทุน (`cost`) ของศิลปินท่านอื่น** (แสดงเป็น `-`)
- ระบบสร้างลิงก์เชิญเข้าร่วมร้าน (Invite Token) อายุ 7 วัน

---

## 📂 โครงสร้างโปรเจกต์ (Project Structure)

```text
Mypos/
├── lib/                       # โค้ดหลักของ Flutter App
│   ├── models/                # Data Models (Shop, Member, Artist, Category, Product, Order, Settlement)
│   ├── services/              # Local Hive Database & PromptPay Generator
│   ├── providers/             # PosProvider (State Management & Multi-Artist Calculations)
│   └── views/                 # หน้าจอ (POS, Inventory, Settlement, Team, History, Reports, Settings)
├── test/                      # Automated Acceptance & Unit Tests (18 tests passing)
├── pubspec.yaml               # Flutter Dependencies & Configuration
├── index.html                 # เว็บไซต์ Landing Page แนะนำระบบ MyPOS
├── components/                # ส่วนประกอบ UI ของเว็บ Landing Page
├── css/                       # สไตล์ชีต
├── js/                        # Script ควบคุม i18n
├── plan_v1.5.md               # ข้อกำหนดสถาปัตยกรรม Data Model & Acceptance Criteria
└── 9arm-skills/               # Agent skills
```

---

## 🚀 การติดตั้งและใช้งาน (Getting Started)

### ความต้องการของระบบ (Prerequisites)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.24+ หรือ 3.38+)
- [Google Chrome](https://www.google.com/chrome/) สำหรับรันบน Web Browser

### 1. รันแอปพลิเคชัน Flutter (Booth POS App)
```bash
# 1. ติดตั้ง Dependencies
flutter pub get

# 2. รันบน Web Browser (โหมดทดสอบ)
flutter run -d chrome

# หรือรันบน Windows Desktop
flutter run -d windows
```

### 2. Build Web สำหรับใช้งาน PWA บน iPad / Safari
```bash
flutter build web --release
```
ไฟล์สำหรับ Deploy จะอยู่ที่โฟลเดอร์ `build/web/` สามารถนำไปติดตั้งบน Web Server หรือ Firebase Hosting ได้ทันที

---

## 🧪 การรันชุดทดสอบ (Automated Testing)

โปรเจกต์มีชุดทดสอบครอบคลุมเงื่อนไข Acceptance Criteria ครบ 100%:

```bash
flutter test
```

### หัวข้อที่ได้รับการทดสอบ:
- ✅ **4.5 Proportional Discount:** ทดสอบการแบ่งส่วนลดทั้งบิลตามอัตราส่วนยอดขายของศิลปิน
- ✅ **4.5 Artist-Specific Discount:** ทดสอบส่วนลดเฉพาะศิลปิน
- ✅ **4.6 Settlement & Commission:** ทดสอบการหักค่าคอมมิชชันและคำนวณยอดสุทธิ
- ✅ **4.6 Voided Orders Excluded:** ออเดอร์ที่ถูก Void จะไม่ถูกรวมใน Settlement
- ✅ **4.8 Cost Visibility Rules:** ทดสอบการซ่อนราคาทุนตามบทบาท Owner vs Member
- ✅ **4.4 Stock Limit Prevention:** ป้องกันการสั่งซื้อเกินจำนวนสต็อกจริง
- ✅ **PromptPay EMVCo Payload:** ตรวจสอบความถูกต้องของ QR Code ออฟไลน์

---

## 🤖 เกี่ยวกับการพัฒนาโค้ด (AI-Assisted Development Note)

> 🙏 **หมายเหตุชี้แจงอย่างสุภาพ (Polite Disclosure):**
> 
> ซอร์สโค้ดและระบบการทำงานของโปรเจกต์นี้ได้รับการพัฒนาขึ้นผ่านความร่วมมือและการเขียนโค้ดร่วมกัน (Pair Programming) ระหว่างผู้พัฒนา (**Pitchaya Waree**) และ **ระบบปัญญาประดิษฐ์ (AI Coding Assistant)** เพื่อช่วยอำนวยความสะดวกในการออกแบบสถาปัตยกรรมระบบ Offline-First, การคำนวณสัดส่วนส่วนลดหลายศิลปิน (Proportional Discounts), ระบบสรุปยอดปิดงาน (Settlement & Commission), ตลอดจนการสร้างชุดแบบทดสอบอัตโนมัติ (Automated Tests) ทั้งหมด
> 
> ทางผู้พัฒนาได้ทำการตรวจสอบโค้ด (Code Review), รันการทดสอบระบบ (Test Suite), และปรับปรุงคุณภาพโค้ดอย่างรอบคอบ เพื่อให้ระบบทำงานได้อย่างราบรื่นและมีเสถียรภาพสูงสุด หากท่านพบข้อผิดพลาดหรือมีข้อเสนอแนะประการใด สามารถแจ้งหรือร่วมส่งคำแนะนำเข้ามาพัฒนาต่อยอดร่วมกันได้เสมอครับ
> 
> *This codebase was developed collaboratively through AI pair programming, thoroughly reviewed and tested to ensure reliability, safety, and performance.*

---

## 👨‍💻 ผู้พัฒนา & ลิขสิทธิ์ (Authors & License)
- พัฒนาโดย **Pitchaya Waree**
- ลิขสิทธิ์ภายใต้ [MIT License](LICENSE)
