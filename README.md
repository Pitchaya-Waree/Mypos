# MyPOS — ระบบขายหน้าร้าน ที่เข้าใจสายผลิตตัวจริง 🐙🎨

[![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart)](https://dart.dev)
[![Offline-First](https://img.shields.io/badge/Offline--First-Hive%20Local%20DB-16A34A)](#-offline-first-architecture)
[![Tests](https://img.shields.io/badge/Tests-18%2F18%20Passing-success)](test/v1_5_acceptance_test.dart)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> ระบบ POS สำหรับขายสินค้าหน้าบูธงานอาร์ตแฟร์ (Art Fair / Creator Booth) ออกแบบมาสำหรับการใช้งานบน **iPad, Android Tablet, Web PWA และ Desktop** ทำงานแบบ **Offline-First 100%** ไม่มีเน็ตหน้างานก็ขายของและสร้าง QR Code ได้อย่างราบรื่น รองรับการแยกหลายร้านค้า (**Multi-Shop Isolation**) ตามข้อกำหนดแผนงาน [plan_v1.6.md](plan_v1.6.md)

---

## 🌟 จุดเด่นของระบบ (Key Features)

### 1. 📴 ทำงานออฟไลน์ 100% (Offline-First Architecture)
- บันทึกข้อมูลลงฐานข้อมูลเครื่องทันที (**Hive Local Database**) ไม่ต้องพึ่งพาเครือข่ายอินเทอร์เน็ตหน้างาน
- จัดการประวัติสต็อกผ่าน `StockMovement` ป้องกันการชนกันของสต็อกเวลาซิงก์
- แสดงแถบสถานะการซิงก์ (`ออฟไลน์พร้อม` หรือ `X รอซิงก์`) และมีระบบบล็อกการ Logout หากยังมีข้อมูลค้างซิงก์

### 2. 🏪 แยกข้อมูลหลายร้านค้าอิสระ (Multi-Shop Isolation - v1.6)
- **แยกข้อมูลด้วย `shop_id` 100%:** สินค้า, ออร์เดอร์, สต็อก และ Settlement แยกขาดจากกันโดยสมบูรณ์
- **ป้องกัน Name Collision:** ร้าน A และ ร้าน B สามารถมีสินค้าชื่อเดียวกันได้ (เช่น "Sticker Cat Day") โดยไม่เกิดการ Merge หรือทับซ้อนข้อมูล
- **ระบบสลับร้านค้า (Shop Switcher):** สลับหน้าร้านทดสอบหรือใช้งานระหว่างร้านค้าได้อย่างง่ายดาย

### 3. 📁 หมวดหมู่สินค้าแบบโฟลเดอร์ (Category Folders - v1.5)
- ระบบโฟลเดอร์จัดระเบียบสินค้า 2 ระดับ (Root Folder → Subfolder) เข้าถึงสินค้าง่ายสำหรับร้านที่มีของหลายสิบชิ้น
- มีแถบ **Breadcrumb Navigation** (`คลังสินค้า > Sticker > ลายแมว`) กดเลือกย้อนกลับไปโฟลเดอร์หลักได้ทันที
- ปุ่มสลับดูแบบรวมทั้งหมด (**All Items**) และระบบ **Global Search** ค้นหาชื่อสินค้าข้ามทุกโฟลเดอร์ได้ทันที

### 4. 👥 ตะกร้าสินค้าแบบหลายศิลปิน (Multi-Artist Cart & Proportional Discounts)
- 1 บูธแชร์ขายร่วมกับศิลปินหลายคนได้ในบิลเดียวกัน โดยระบบ Snapshot `artist_id` ตอนขายจริง
- การ์ดสินค้าและรายการในตะกร้าแสดงป้ายชื่อศิลปินเจ้าของสินค้าชัดเจน
- **ส่วนลดเฉลี่ยสัดส่วนทั้งบิล (Proportional Discount)**: ระบบจะกระจายส่วนลดให้แต่ละศิลปินตามสัดส่วนมูลค่าสินค้าในบิลโดยอัตโนมัติ
- **ส่วนลดเฉพาะศิลปิน (Artist-Specific Discount)**: สามารถเลือกใส่ส่วนลดเฉพาะสินค้าของศิลปินท่านนั้นได้ โดยไม่กระทบศิลปินท่านอื่น

### 5. 💰 คิดค่าคอมมิชชัน & ปิดยอด (Commission & Settlement)
- กำหนดอัตราส่วนแบ่งคอมมิชชัน (`commission_rate %`) แยกเป็นรายศิลปิน
- หน้าสรุปยอด **Settlement**: สรุปยอดขายรวม (Gross), หักค่าคอมมิชชัน, และยอดสุทธิที่ต้องจ่ายคืนศิลปิน (Net Payout)
- ตัดออเดอร์ยกเลิก (**Voided Orders**) ออกจากยอด Settlement และคืนสต็อกอัตโนมัติ
- บันทึกสถานะ "จ่ายแล้ว (Mark as Paid)" พร้อมโน้ตช่วยจำ และส่งออกเป็น CSV

### 6. 💳 ชำระเงินรวดเร็ว เหมาะกับจอสัมผัส iPad
- **แป้นตัวเลขทัชสกรีน (Touch Numpad)**: กดรับเงินสดได้รวดเร็ว พร้อมปุ่มลัด `พอดี`, `+20`, `+50`, `+100`, `500`, `1000` และคำนวณเงินทอนอัตโนมัติ
- **พร้อมเพย์ QR แบบ Dynamic**: สร้าง QR Code พร้อมระบุยอดเงินตามมาตรฐาน **EMVCo / BOT PromptPay** สร้างได้โดย **ไม่ต้องต่ออินเทอร์เน็ต**

### 7. 🔐 ระบบสมาชิกทีมงาน & สิทธิ์การมองเห็น (Team & Visibility)
- บทบาท **Owner** (เจ้าของร้าน): จัดการร้าน, เชิญสมาชิก, ดูยอดและรายงานทั้งหมด
- บทบาท **Member** (ทีมงานช่วยขาย): ดูสินค้าและขายของได้ **แต่ซ่อนราคาทุน (`cost`) ของศิลปินท่านอื่น** (แสดงเป็น `-`)
- ระบบสร้างลิงก์เชิญเข้าร่วมร้าน (Invite Token) อายุ 7 วัน

### 8. 🧹 ข้อมูลจำลองแยกส่วน & เริ่มต้นแบบว่างเปล่า (Blank Slate & Mock Seed Data)
- **Production Blank Slate:** เมื่อติดตั้งหรือเปิดใช้งานครั้งแรก ฐานข้อมูลจะว่างเปล่า 100% พร้อมให้เจ้าของร้านตั้งค่าจริง
- **MockSeedService:** มีชุดข้อมูลตัวอย่างแยกอิสระ (ร้าน A: Mako Shop #A14 และ ร้าน B: Crafty Fox Studio #B08) พร้อมปุ่มกดโหลด Demo หรือล้างข้อมูลทั้งหมด (Wipe All Data) ได้ทันทีในหน้าตั้งค่า

---

## 📂 โครงสร้างโปรเจกต์ (Project Structure)

```text
Mypos/
├── lib/                       # โค้ดหลักของ Flutter App
│   ├── models/                # Data Models (Shop, Member, Invite, Artist, Category, Product, Order, Settlement)
│   ├── services/              # DatabaseService (Hive), PromptPayService, MockSeedService
│   ├── providers/             # PosProvider (State Management & Multi-Artist Calculations)
│   └── views/                 # หน้าจอ (POS, Inventory, Settlement, Team, History, Reports, Settings)
├── test/                      # Automated Acceptance & Unit Tests (18 tests passing 100%)
├── pubspec.yaml               # Flutter Dependencies & Configuration
├── plan_v1.5.md               # ข้อกำหนดสถาปัตยกรรม Data Model & Acceptance Criteria v1.5
├── plan_v1.6.md               # ข้อกำหนด Multi-Shop Isolation, Seed Data ร้าน A/B v1.6
├── README.md                  # เอกสารแนะนำและคู่มือโปรเจกต์
└── README_APP.md              # คู่มือทางเทคนิคสำหรับแอปพลิเคชัน Flutter
```

---

## 🚀 การติดตั้งและใช้งาน (Getting Started)

### ความต้องการของระบบ (Prerequisites)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.24+ หรือ 3.38+)
- [Google Chrome](https://www.google.com/chrome/) สำหรับรันบน Web Browser หรือ Desktop Environment

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

โปรเจกต์มีชุดทดสอบครอบคลุมเงื่อนไข Acceptance Criteria ตามแผน v1.5 และ v1.6 ครบ 100% (18/18 Tests):

```bash
flutter test
```

### รายการทดสอบที่ผ่านทั้งหมด (18/18 Tests):
#### ชุดทดสอบตามแผน v1.5:
- ✅ `4.5 Proportional Discount`: การเฉลี่ยส่วนลดทั้งบิลตามสัดส่วนยอดขายศิลปิน (30:70)
- ✅ `4.5 Artist-Specific Discount`: ส่วนลดเฉพาะศิลปิน ไม่กระทบศิลปินคนอื่น
- ✅ `4.5 Clearing Discount`: การล้างส่วนลดคืนค่ายอดรวมบิลถูกต้อง
- ✅ `4.5 Itemized Discount Details`: ตรวจสอบความถูกต้องของส่วนลดรายชิ้น
- ✅ `4.6 Settlement & Commission`: คำนวณยอด Gross, หักค่าคอมมิชชัน 10% และ Net Payout
- ✅ `4.6 Voided Orders Excluded`: ไม่นำบิลที่ถูก Void มารวมในรายงาน Settlement
- ✅ `4.8 Cost Visibility Rules`: Owner เห็นต้นทุนทั้งหมด, Member เห็นเฉพาะของศิลปินที่ผูก
- ✅ `4.4 Stock Limit Prevention`: ป้องกันการสั่งซื้อหรือใส่ตะกร้าเกินสต็อก
- ✅ `PromptPay EMVCo Payload`: ตรวจสอบโครงสร้าง Tag และ CRC16 ของ QR Code ออฟไลน์
- ✅ `3 & 4.5 Snapshot in OrderItem`: สแนปช็อต artist_id และราคาตอนขาย ไม่เปลี่ยนตามการแก้สินค้าภายหลัง
- ✅ `4.7 Multi-User Invite`: ลิงก์เชิญมีอายุ 7 วัน และหมดอายุในวันที่ 8
- ✅ `4.6 End-to-End Multi-Artist Settlement`: คำนวณยอดขายหลายศิลปินพร้อมอัตราคอมมิชชันต่างกัน

#### ชุดทดสอบตามแผน v1.6 (Multi-Shop Isolation & Seed Data):
- ✅ `5.1 Multi-Shop Order Isolation`: ยอดขายและบิลของร้าน A และร้าน B แยกขาดจากกันโดยสิ้นเชิง
- ✅ `5.2 Product Name Collision Isolation`: สินค้าชื่อเดียวกันในร้านต่างกันแยกตาม `shop_id` ไม่ปนกัน
- ✅ `5.3 Settlement per Shop`: ยอด Settlement และค่าคอมมิชชันของร้าน A (Mako Shop) และ ร้าน B (Crafty Fox) คำนวณถูกต้องตาม Seed Data
- ✅ `5.4 Cross-Shop Cost Visibility`: ทีมงานร้าน A มองไม่เห็นราคาทุนสินค้าของร้าน B
- ✅ `5.5 Production Blank Slate`: เริ่มต้นใช้งานแบบฐานข้อมูลว่างเปล่า 100% พร้อมใช้งานจริง
- ✅ `App Smoke Test`: การโหลด Main Application Widget ได้อย่างสมบูรณ์

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
