# MyPOS — ระบบขายหน้าร้าน ที่เข้าใจสายผลิตตัวจริง 🐙🎨

[![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart)](https://dart.dev)
[![Offline-First](https://img.shields.io/badge/Offline--First-Repository%20%2B%20Offline%20Cache-16A34A)](#-offline-first-architecture)
[![Tests](https://img.shields.io/badge/Tests-41%2F41%20Passing-success)](test/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> ระบบ POS สำหรับขายสินค้าหน้าบูธงานอาร์ตแฟร์ (Art Fair / Creator Booth) ออกแบบมาสำหรับการใช้งานบน **iPad, Android Tablet, Web PWA และ Desktop** ทำงานแบบ **Offline-First 100%** ไม่มีเน็ตหน้างานก็ขายของและสร้าง QR Code ได้อย่างราบรื่น รองรับการแยกหลายร้านค้า (**Multi-Shop Isolation**) คลังกลางสินค้า (Central Catalog) และสถาปัตยกรรม 3 บทบาท (Owner, Manager, Member) ตามข้อกำหนดแผนงาน [plan_v1.7.md](docs/plan_v1.7.md)

---

## 🌟 จุดเด่นของระบบ (Key Features)

### 1. 📴 ทำงานออฟไลน์ 100% (Offline-First Architecture)
- บันทึกข้อมูลลงฐานข้อมูลเครื่องทันทีผ่าน **Repository Layer & Offline Cache** ไม่ต้องพึ่งพาเครือข่ายอินเทอร์เน็ตหน้างาน
- จัดการประวัติสต็อกผ่าน `StockMovement` ป้องกันการชนกันของสต็อกเวลาซิงก์
- แสดงแถบสถานะการซิงก์ (`ออฟไลน์พร้อม` หรือ `X รอซิงก์`) และมีระบบบล็อกการ Logout หากยังมีข้อมูลค้างซิงก์

### 2. 🏪 แยกข้อมูลหลายร้านค้าอิสระ (Multi-Shop Isolation - v1.6)
- **แยกข้อมูลด้วย `shop_id` 100%:** สินค้า, ออร์เดอร์, สต็อก และ Settlement แยกขาดจากกันโดยสมบูรณ์
- **ป้องกัน Name Collision:** ร้าน A และ ร้าน B สามารถมีสินค้าชื่อเดียวกันได้ (เช่น "Sticker Cat Day") โดยไม่เกิดการ Merge หรือทับซ้อนข้อมูล
- **ระบบสลับร้านค้า (Shop Switcher):** สลับหน้าร้านทดสอบหรือใช้งานระหว่างร้านค้าได้อย่างง่ายดาย

### 3. 👥 สิทธิ์และบทบาท 3 ระดับ (Three-Tier Roles - v1.7)
- **Owner (เจ้าของร้าน):** มีสิทธิ์สูงสุด 1 คนต่อร้าน จัดการร้าน, แก้เบอร์ PromptPay, ดู Settlement & ค่าคอมมิชชัน, เชิญ Manager และ Member
- **Manager (ผู้จัดการร้าน):** จัดการคลังสินค้า หมวดหมู่ อีเวนต์ และศิลปิน, ดูยอดขายทั้งร้าน, ทำการ Void ออร์เดอร์ได้ (แต่ซ่อน Settlement, ราคาทุนศิลปินอื่น และเบอร์ PromptPay)
- **Member (ทีมงานช่วยขาย):** ขายสินค้า คิดเงิน ยิง QR ดูเฉพาะออร์เดอร์ที่ตัวเองเป็นคนขาย (ไม่สามารถ Void, ไม่สามารถแก้ไขสินค้า และซ่อนราคาทุน)

### 4. 📦 คลังสินค้าส่วนกลาง & เลือกสินค้าเข้างาน (Central Catalog - v1.7)
- สินค้าสร้างในคลังกลาง อัปโหลดรูปครั้งเดียว
- แต่ละงาน (Event) สามารถเลือกเฉพาะสินค้า (`eventProducts`) และศิลปิน (`eventArtists`) ที่มาออกบูธจริง
- ซอฟต์ดีลีท (`active: false`) ปลอดภัย ไม่ลบประวัติการขายเดิม

### 5. 📉 สต็อกติดลบได้พร้อมแจ้งเตือน (Negative Stock Support - v1.7)
- ไม่บล็อกการคิดเงินเมื่อสต็อกหมด สามารถขายต่อได้แม้สินค้าหมดหน้างาน (เช่น สองเครื่องขายสินค้าชิ้นสุดท้ายพร้อมกันตอนออฟไลน์)
- สต็อกจะปรับเป็นติดลบ (เช่น -1) พร้อมแจ้งเตือนให้ทีมงานปรับสต็อกจริงภายหลัง

### 6. 📁 หมวดหมู่สินค้าแบบโฟลเดอร์ (Category Folders - v1.5)
- ระบบโฟลเดอร์จัดระเบียบสินค้า 2 ระดับ (Root Folder → Subfolder) เข้าถึงสินค้าง่ายสำหรับร้านที่มีของหลายสิบชิ้น
- มีแถบ **Breadcrumb Navigation** (`คลังสินค้า > Sticker > ลายแมว`) กดเลือกย้อนกลับไปโฟลเดอร์หลักได้ทันที
- ปุ่มสลับดูแบบรวมทั้งหมด (**All Items**) และระบบ **Global Search** ค้นหาชื่อสินค้าข้ามทุกโฟลเดอร์ได้ทันที

### 7. 👥 ตะกร้าสินค้าแบบหลายศิลปิน (Multi-Artist Cart & Proportional Discounts)
- 1 บูธแชร์ขายร่วมกับศิลปินหลายคนได้ในบิลเดียวกัน โดยระบบ Snapshot `artist_id` ตอนขายจริง
- การ์ดสินค้าและรายการในตะกร้าแสดงป้ายชื่อศิลปินเจ้าของสินค้าชัดเจน
- **ส่วนลดเฉลี่ยสัดส่วนทั้งบิล (Proportional Discount)**: ระบบจะกระจายส่วนลดให้แต่ละศิลปินตามสัดส่วนมูลค่าสินค้าในบิลโดยอัตโนมัติ
- **ส่วนลดเฉพาะศิลปิน (Artist-Specific Discount)**: สามารถเลือกใส่ส่วนลดเฉพาะสินค้าของศิลปินท่านนั้นได้ โดยไม่กระทบศิลปินท่านอื่น

### 8. 💰 คิดค่าคอมมิชชัน & ปิดยอด (Commission & Settlement)
- กำหนดอัตราส่วนแบ่งคอมมิชชัน (`commission_rate %`) แยกเป็นรายศิลปิน
- คำนวณยอดสรุปรายศิลปิน (`artistTotals`) ฝังในบิลออร์เดอร์ทันทีตอนขาย ทำให้สามารถทำ Aggregation สำหรับ Settlement ได้อย่างรวดเร็ว
- ตัดออเดอร์ยกเลิก (**Voided Orders**) ออกจากยอด Settlement และคืนสต็อกอัตโนมัติ
- บันทึกสถานะ "จ่ายแล้ว (Mark as Paid)" พร้อมโน้ตช่วยจำ และส่งออกเป็น CSV

### 9. 💳 ชำระเงินรวดเร็ว เหมาะกับจอสัมผัส iPad
- **แป้นตัวเลขทัชสกรีน (Touch Numpad)**: กดรับเงินสดได้รวดเร็ว พร้อมปุ่มลัด `พอดี`, `+20`, `+50`, `+100`, `500`, `1000` และคำนวณเงินทอนอัตโนมัติ
- **พร้อมเพย์ QR แบบ Dynamic**: สร้าง QR Code พร้อมระบุยอดเงินตามมาตรฐาน **EMVCo / BOT PromptPay** สร้างได้โดย **ไม่ต้องต่ออินเทอร์เน็ต**

---

## 📂 โครงสร้างโปรเจกต์ (Project Structure)

```text
Mypos/
├── lib/                       # โค้ดหลักของ Flutter App
│   ├── models/                # Data Models (Shop, Member, Invite, Artist, Category, Product, Event, Order, Settlement)
│   ├── repositories/          # Repository Layer (Auth, Shop, Member, Catalog, Event, Order, Stock, Settlement)
│   ├── services/              # DatabaseService, PromptPayService, MockSeedService
│   ├── providers/             # PosProvider (State Management & Multi-Artist Calculations)
│   └── views/                 # หน้าจอ (POS, Inventory, Settlement, Team, History, Reports, Settings)
├── test/                      # Automated Acceptance & Unit Tests (41 tests passing 100%)
│   ├── phase_a_test.dart          # 4 tests (Isolation, cost masking, orderId binding, least privilege)
│   ├── phase_b_test.dart          # 6 tests (Delta stock checkout, Hamilton discount, unified settlement)
│   ├── phase_c_test.dart          # 4 tests (Indexes, query constraints, MVP & production rules validators)
│   ├── v1_5_acceptance_test.dart  # 18 tests (v1.5 & v1.6 criteria)
│   ├── v1_7_acceptance_test.dart  # 8 tests (v1.7 roles, central catalog, negative stock, artistTotals)
│   └── widget_test.dart           # Smoke test
├── firestore.rules            # Production Firestore Rules (Validator Function Pattern & RBAC)
├── firestore.rules.mvp        # Spark MVP bootstrap rules for initial shop creation
├── storage.rules              # Firebase Storage Rules (Image size <= 300KB & role protection)
├── firestore.indexes.json     # Firestore Composite Indexes
├── pubspec.yaml               # Flutter Dependencies & Configuration
├── index.html                 # เว็บไซต์ Landing Page แนะนำระบบ MyPOS
├── components/                # UI Components ของเว็บ Landing Page
├── css/                       # Stylesheets ของเว็บ Landing Page
├── js/                        # JavaScript & i18n scripts
├── docs/                      # เอกสารสถาปัตยกรรม แผนงาน และคู่มือ
│   ├── DESIGN.md              # แนวทางการออกแบบ UI/UX
│   ├── fix_instructions_v1.md # แผนงานแก้ไขบั๊กและปรับสถาปัตยกรรม Phase A, B, C
│   ├── plan.md                # แผนงานฉบับเริ่มต้น
│   ├── plan_v1.5.md           # ข้อกำหนด Data Model & Acceptance Criteria v1.5
│   ├── plan_v1.6.md           # ข้อกำหนด Multi-Shop Isolation & Seed Data v1.6
│   ├── plan_v1.7.md           # ข้อกำหนด Flutter + Firebase, 3 Roles, Central Catalog v1.7
│   ├── README_APP.md          # คู่มือทางเทคนิคสำหรับ Flutter App
│   └── assets/                # รูปภาพและ UI mockup assets
└── README.md                  # เอกสารแนะนำและคู่มือโปรเจกต์
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

โปรเจกต์มีชุดทดสอบครอบคลุมเงื่อนไข Acceptance Criteria ตามแผน v1.5, v1.6, v1.7 และ Phase A, B, C ครบ 100% (41/41 Tests):

```bash
flutter test
```

### รายการทดสอบที่ผ่านทั้งหมด (41/41 Tests):
#### ชุดทดสอบ Phase A, B, C (`fix_instructions_v1.md`):
- ✅ `Phase A - Item 2`: `deleteCategory` cross-shop isolation ป้องกันผลกระทบข้ามร้านที่มี categoryId ซ้ำกัน
- ✅ `Phase A - Item 1`: ความเป็นส่วนตัวของราคาทุน ซ่อนทุนจาก Manager และแสดงเฉพาะศิลปินที่ตนผูก
- ✅ `Phase A - Item 10`: `OrderItem.orderId` ผูกกับ `order.id` เสมอหลังเช็คเอาต์
- ✅ `Phase A - Item 7`: `createShop` สร้าง Owner และ Default Artist พร้อมกำหนดสิทธิ์ขั้นต่ำ (least-privilege)
- ✅ `Phase B - Item 3`: เช็คเอาต์คำนวณตัดสต็อกด้วย delta สด (`stock: increment(-qty)`) ป้องกันการทับซ้อนข้อมูล
- ✅ `Phase B - Item 3`: ป้องกันการตัดสต็อกซ้ำซ้อนจาก orderId เดียวกัน (Idempotent checkout)
- ✅ `Phase B - Item 8`: คำนวณส่วนลดท้ายบิลแบบ Dynamic เมื่อสินค้าในตะกร้าเปลี่ยนหรือถูกลบ
- ✅ `Phase B - Item 8`: ปันส่วนลดทั้งบิลแบบเศษสตางค์ไม่ตกหล่นด้วยวิธี Largest-Remainder (Hamilton method)
- ✅ `Phase B - Item 11`: รวม logic คำนวณ Settlement ใน Repository Layer โดยอ่านจาก `order.artistTotals`
- ✅ `Phase C - Item 4`: Composite indexes ใน `firestore.indexes.json` สำหรับ query ออร์เดอร์ของ Member
- ✅ `Phase C - Item 4`: ข้อกำหนด Query Constraints ของ Member ให้กรองเฉพาะ `createdBy == uid`
- ✅ `Phase C - Item 5`: `firestore.rules.mvp` รองรับการสร้างร้านแบบ Batch บน Spark Tier ชั่วคราว
- ✅ `Phase C - Production Rules`: ตรวจสอบโครงสร้าง Data Model, Validator Functions และ Acceptance Criteria ใน `firestore.rules`

#### ชุดทดสอบตามแผน v1.5:
- ✅ `4.5 Proportional Discount`: การเฉลี่ยส่วนลดทั้งบิลตามสัดส่วนยอดขายศิลปิน (30:70)
- ✅ `4.5 Artist-Specific Discount`: ส่วนลดเฉพาะศิลปิน ไม่กระทบศิลปินคนอื่น
- ✅ `4.5 Clearing Discount`: การล้างส่วนลดคืนค่ายอดรวมบิลถูกต้อง
- ✅ `4.5 Itemized Discount Details`: ตรวจสอบความถูกต้องของส่วนลดรายชิ้น
- ✅ `4.6 Settlement & Commission`: คำนวณยอด Gross, หักค่าคอมมิชชัน 10% และ Net Payout
- ✅ `4.6 Voided Orders Excluded`: ไม่นำบิลที่ถูก Void มารวมในรายงาน Settlement
- ✅ `4.8 Cost Visibility Rules`: Owner เห็นต้นทุนทั้งหมด, Member เห็นเฉพาะของศิลปินที่ผูก
- ✅ `4.4 Overselling Allowed`: สต็อกติดลบได้เมื่อขายสินค้าเกินจำนวนที่มีในคลัง
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

#### ชุดทดสอบตามแผน v1.7 (Three-Tier Roles, Central Catalog, Negative Stock & Firebase Architecture):
- ✅ `12.1 Three-Tier Role Permissions`: สิทธิ์ของ Owner, Manager และ Member แยกตามขอบเขตความปลอดภัย
- ✅ `12.1 Cost Visibility Rules`: Owner เห็นทุนทุกคน; Manager และ Member เห็นเฉพาะศิลปินที่ผูก
- ✅ `12.1 Order Visibility Scope`: Member มองเห็นเฉพาะออร์เดอร์ที่ตัวเองเป็นคนขาย, Owner/Manager เห็นทั้งร้าน
- ✅ `12.2 Negative Stock Allowed`: สต็อกติดลบได้ (-1) ไม่บล็อกการคิดเงิน และแจ้งเตือนให้ปรับสต็อก
- ✅ `12.5 Atomic Order & artistTotals Aggregation`: ออร์เดอร์ฝัง artistTotals สรุปยอดรายศิลปินและทำ Settlement aggregation ได้แม่นยำ
- ✅ `12.4 Central Catalog & Event Selection`: สินค้าคลังกลางถูกเลือกเข้างานผ่าน eventProducts และ eventArtists
- ✅ `12.3 Multi-Shop Membership`: 1 บัญชีผู้ใช้สามารถดูแลได้หลายร้านผ่าน UserMembership index
- ✅ `12.1 Single-Void Protection`: Void ออร์เดอร์พร้อมบันทึกเหตุผลและป้องกันการกดยกเลิกซ้ำ
- ✅ `12.2 Sign-out Guard`: บล็อกการออกจากระบบหากยังมีรายการขายค้างซิงก์
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
