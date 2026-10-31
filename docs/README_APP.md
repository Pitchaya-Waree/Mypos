# Booth POS App v1.5 (Flutter) 🐙🎨

ระบบขายหน้าร้าน (Point of Sale) ออกแบบมาสำหรับงานอาร์ตแฟร์ / ออกบูธขายของสายผลิตโดยเฉพาะ พัฒนาด้วย **Flutter** รองรับการทำงานแบบ **Offline-First 100%** บน **iPad, Android Tablet, Web PWA และ Desktop**

อ้างอิงสถาปัตยกรรมและข้อกำหนดทั้งหมดตาม [plan_v1.5.md](plan_v1.5.md)

---

## 🚀 ฟังก์ชันหลัก (Key Features)

### 1. 📴 สถาปัตยกรรมออฟไลน์ 100% (Offline-First Architecture)
- **Local Database:** จัดเก็บข้อมูลทั้งหมดในเครื่องผ่าน **Hive** รวดเร็ว ไม่ต้องพึ่งพาเครือข่ายอินเทอร์เน็ต
- **Stock Movement Ledger:** ทุกการเปลี่ยนแปลงของสต็อก (ขาย, ยกเลิก/Void, ปรับสต็อกด้วยมือ) ถูกบันทึกผ่าน `StockMovement`
- **Client-Generated UUID:** ทุก Record มี `id` เป็น UUID ที่สร้างจากเครื่องทันที

### 2. 📁 หมวดหมู่สินค้าแบบโฟลเดอร์ (Category Folders - 2 Levels)
- รองรับโฟลเดอร์หลัก (Root) และโฟลเดอร์ย่อย (Subfolder) จำกัดความลึกไม่เกิน 2 ชั้น
- แถบ **Breadcrumb Navigation** (`คลังสินค้า > Sticker > ลายแมว`) สามารถกดเลือกบรรพบุรุษเพื่อกระโดดกลับหน้าแรกได้ในคลิกเดียว
- ปุ่มสลับดูแบบรวมทั้งหมด (**All Items**) แบบ Flat List
- ระบบ **Global Search** ค้นหาชื่อสินค้าข้ามทุกโฟลเดอร์ทันที
- **Safe Folder Deletion:** ลบโฟลเดอร์ สินค้าข้างในจะถูกย้ายไปที่ "ไม่มีหมวดหมู่" โดยอัตโนมัติ (ไม่ลบสินค้าทิ้ง)

### 3. 👥 ตะกร้าสินค้าแบบ Multi-Artist & ส่วนลดเฉลี่ยสัดส่วน
- 1 บูธแชร์ขายร่วมกับศิลปินหลายคนได้ในบิลเดียวกัน บันทึก `OrderItem.artist_id` แบบ Snapshot
- แสดงป้ายชื่อศิลปินกำกับบนการ์ดสินค้าและรายการในตะกร้า
- **ส่วนลดทั้งบิลแบบเฉลี่ยตามสัดส่วน (Proportional Whole-Bill Discount):** คำนวณส่วนแบ่งยอดขายของแต่ละศิลปิน และกระจายส่วนลดตามอัตราส่วนจริง (เช่น บิล 1,000 บาท ศิลปิน A มีของ 300, B มี 700 หากลดทั้งบิล 100 บาท ระบบจะหัก A 30 บาท และ B 70 บาท)
- **ส่วนลดเฉพาะศิลปิน (Artist-Specific Discount):** เลือกใส่ส่วนลดเฉพาะสินค้าของศิลปินท่านนั้นได้

### 4. 💰 คิดค่าคอมมิชชัน & ระบบ Settlement
- กำหนดอัตราส่วนแบ่งคอมมิชชัน (`commission_rate %`) ต่อศิลปินแต่ละคน
- หน้าจอ **Settlement**: สรุปยอดขายรวม (Gross), หักค่าคอมมิชชัน, และยอดสุทธิที่ต้องจ่ายคืน (Net Payout) ต่ออีเวนต์
- บันทึกสถานะ "จ่ายแล้ว (Mark as Paid)" พร้อมโน้ตช่วยจำ
- มีแบนเนอร์เตือนหากมีบิลค้างซิงก์ก่อนทำการปิด Settlement
- ส่งออกตาราง Settlement เป็นไฟล์ CSV

### 5. 💳 หน้าขายสำหรับ iPad & Tablet
- **Touch Numpad:** แป้นตัวเลขขนาดใหญ่ เหมาะกับนิ้วสัมผัส พร้อมปุ่มลัด `พอดี`, `+20`, `+50`, `+100`, `500`, `1000`
- **PromptPay QR Code:** สร้าง QR Code ระบุยอดเงินจากเครื่อง client ด้วยมาตรฐาน **EMVCo / BOT PromptPay** โดย **ไม่ต้องต่อเน็ต**
- **Stock Limit:** ป้องกันการเพิ่มสินค้าลงตะกร้าเกินจำนวนสต็อกจริง

### 6. 🔐 ระบบทีมงาน & สิทธิ์การมองเห็นราคาทุน (Team & Visibility)
- **Owner (เจ้าของร้าน):** มองเห็นราคาทุนทุกชิ้น จัดการร้าน เชิญทีมงาน และดูหน้า Settlement ได้
- **Member (ทีมงานช่วยขาย):** ซ่อนราคาทุน (`cost`) ของศิลปินคนอื่นให้แสดงเป็น `"-"` (เห็นเฉพาะของตัวเองหากผูกไว้ หรือซ่อนทั้งหมดหากไม่ผูก) และซ่อนเมนูตั้งค่าร้าน
- ระบบสร้างลิงก์เชิญเข้าร่วมร้าน (Invite Token) อายุ 7 วัน
- ปุ่มสลับบทบาททดสอบ (**Toggle Role for Testing**) ในหน้าทีมงาน

### 7. 🧹 การแยกข้อมูลจำลอง & หน้าเริ่มต้นแบบว่าง 100% (Seed Data Decoupling & Blank Slate)
- **Zero Mock Data on Fresh Start:** ฐานข้อมูลเริ่มต้นแบบว่างเปล่า 100% สำหรับการใช้งานจริง ไม่มีข้อมูลร้าน สินค้า หรือยอดขายจำลองค้างอยู่
- **MockSeedService:** แยกข้อมูลตัวอย่างทั้งหมด (ร้าน A, ร้าน B, หมวดหมู่ 2 ระดับ, สินค้า, อีเวนต์, ออร์เดอร์หลากหลายแบบ) ออกมาไว้ที่ `lib/services/mock_seed_service.dart` ไม่ปนกับโค้ดหลัก
- **On-Demand Demo & Wipe:** ในหน้าขายหน้าร้านและหน้าการตั้งค่า มีปุ่มกดสำหรับ:
  - สร้างร้านค้าใหม่สำหรับการใช้งานจริง
  - โหลดข้อมูลตัวอย่างสำหรับทดสอบ (Demo Seed Data)
  - ล้างข้อมูลทั้งหมด (Wipe All Data) เพื่อกลับสู่หน้าว่างเปล่าพร้อมใช้งานจริง

---

## 🛠 วิธีการรันโปรเจกต์ (How to Run)

### รันบน Web Browser (Chrome / Edge):
```bash
flutter run -d chrome
```

### รันบน Windows Desktop:
```bash
flutter run -d windows
```

### Build Web สำหรับเปิดใช้งานบน iPad:
```bash
flutter build web --release
```

---

## 🧪 การรันชุดทดสอบ (Automated Tests)

```bash
flutter test
```

### รายการทดสอบที่ผ่าน 100% (18/18 Tests):
- `4.5 Proportional whole-bill discount is split according to gross sales ratio (30:70)`
- `4.5 Artist-specific discount applies only to target artist items`
- `4.5 Clearing discount resets all items to 0 and restores full cart total`
- `4.5 Itemized discount details correctly tracks which items got discount`
- `4.6 Settlement computes 10% commission correctly (Gross: 1000 -> Comm: 100, Net: 900)`
- `4.6 Voided orders are excluded from settlement gross sales`
- `4.8 Cost visibility rules: Owner sees all, Member only sees linked artist cost`
- `4.4 Out of stock prevention: cart qty cannot exceed product stock`
- `PromptPay payload generates correct EMVCo tags and CRC16 offline`
- `3 & 4.5 OrderItem snapshots artist_id and price at sale time and remains unchanged even if artist/product is deleted`
- `4.7 Multi-user invite generates token with 7-day validity and expires on day 8`
- `4.6 End-to-end multi-artist settlement calculates gross, commission, and net payout per artist`
- `5.1 Orders from Shop A and Shop B are strictly isolated by shop_id`
- `5.2 Products with identical names in different shops are isolated by shop_id`
- `5.3 Settlement calculation per shop correctly computes gross, commission, and net payout`
- `5.4 Staff member of Shop A can only see cost for their linked artist in Shop A`
- `5.5 Initial state is clean blank slate with zero shops/products, and owner privileges are default`
- `App smoke test`

---

## 🤖 เกี่ยวกับการพัฒนาโค้ด (AI-Assisted Development Note)

> 🙏 **หมายเหตุชี้แจงอย่างสุภาพ (Polite Disclosure):**
> 
> แอปพลิเคชันและโค้ดทั้งหมดในโปรเจกต์นี้ได้รับการพัฒนาขึ้นผ่านกระบวนการทำงานร่วมกัน (Pair Programming) ระหว่างผู้พัฒนา (**Pitchaya Waree**) และ **ระบบปัญญาประดิษฐ์ (AI Coding Assistant)** โดยใช้ AI ในการช่วยออกแบบโครงสร้างข้อมูล Hive Local DB, ระบบจัดสรรส่วนลดเฉลี่ยตามสัดส่วน (Proportional Discounts), ระบบ Settlement, และชุดการทดสอบอัตโนมัติทั้งหมด
> 
> ซอร์สโค้ดทุกส่วนได้รับการตรวจสอบความถูกต้อง (Review) และผ่านการทดสอบครอบคลุม Acceptance Criteria 100% เรียบร้อยแล้ว หากมีข้อผิดพลาดหรือข้อเสนอแนะประการใด สามารถแจ้งเพื่อร่วมปรับปรุงพัฒนาให้ดียิ่งขึ้นได้เสมอครับ
> 
> *This codebase was developed with the assistance of AI (AI Pair Programming), thoroughly reviewed and tested to ensure high quality and reliability.*

---

## 👨‍💻 ผู้พัฒนา & ลิขสิทธิ์ (Author & License)
- ผู้พัฒนา: **Pitchaya Waree**
- ลิขสิทธิ์: [MIT License](LICENSE)
