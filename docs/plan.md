# Dev Brief — Booth POS App v1.0 (สำหรับส่งต่อให้ Antigravity IDE)

---

## 1. ภาพรวมโปรเจกต์

สร้าง **แอปพลิเคชัน POS** (ไม่ใช่แค่เว็บเพจธรรมดา) สำหรับขายสินค้าหน้าบูธงานอาร์ตแฟร์ ใช้งานบน **iPad เป็นหลัก** ต้องทำงานได้แม้ไม่มีอินเทอร์เน็ต (เน็ตหน้างานไม่เสถียร) แรงบันดาลใจจาก Loyverse POS, MakerGO, BoothMate

**สิ่งสำคัญที่สุดของโปรเจกต์นี้คือ offline-first** — ไม่ใช่แอปที่เรียก API ทุกครั้งที่กดปุ่ม แต่บันทึกลงเครื่องก่อนเสมอ แล้วค่อย sync ทีหลัง

## 2. แพลตฟอร์มและสถาปัตยกรรม

- **ทำเป็น PWA** (Progressive Web App) — ติดตั้งหน้าจอ Home บน iPad ได้ ทำงานแบบแอปจริง ไม่ต้องผ่าน App Store
- ต้องมี **Service Worker** สำหรับ cache ไฟล์แอปทั้งหมด (JS/CSS/รูปสินค้า) ให้เปิดใช้ได้แม้ปิดเน็ตสนิท
- **Local database ในเครื่อง**: ใช้ IndexedDB (ผ่าน Dexie.js หรือ RxDB) เป็นแหล่งข้อมูลหลักที่แอปอ่าน/เขียนตลอดเวลา — ห้ามเรียก backend ตรงๆ ตอนขายของ
- **Backend/Cloud sync**: Firebase Firestore (มี offline persistence ในตัว ใช้ฟรีได้ในแผน Spark สำหรับ data ระดับนี้) — sync ขึ้นคลาวด์เมื่อมีเน็ตเท่านั้น ไม่ block การใช้งานหลัก
- Auth: Firebase Authentication ด้วย Google Sign-In

## 3. Data Model (ออกแบบรองรับหลายศิลปินตั้งแต่ day 1 แม้ v1.0 จะเปิดใช้แค่คนเดียว)

```
Shop
 - id, name, owner_user_id, promptpay_id, promptpay_name

Artist
 - id, shop_id, name
 (v1.0: สร้าง default artist 1 คน = เจ้าของร้าน อัตโนมัติ ไม่ต้องมี UI จัดการหลายคนก็ได้)

Category
 - id, shop_id, name

Product
 - id, shop_id, artist_id, name, image, price, cost, category_id, stock, is_bestseller

Event (งาน/อีเวนต์)
 - id, shop_id, name, start_date, end_date, is_active

Order
 - id (client-generated UUID), shop_id, event_id, status (completed/voided),
   payment_method (cash/qr), total, cash_received, change, created_at,
   synced (bool), created_offline (bool)

OrderItem
 - id, order_id, product_id, artist_id (snapshot ตอนขาย ห้าม join ทีหลัง),
   name_snapshot, price_snapshot, qty, discount_amount

StockMovement
 - id, product_id, order_id (nullable), type (sale/void/manual_adjust/import),
   qty_change, created_at
 (ห้ามเขียนทับ stock ตรงๆ — ทุกการเปลี่ยนแปลงสต็อกต้องผ่านตารางนี้ เพื่อกัน conflict ตอน sync)
```

**กติกาสำคัญ**: ทุก record ที่สร้างฝั่ง client ต้องมี `id` เป็น UUID สร้างเองตั้งแต่ต้น (ไม่รอ backend generate) เพื่อให้ sync ชนกันได้น้อยที่สุดเวลาหลายเครื่อง/offline นาน

## 4. ฟีเจอร์ที่ต้องมีก่อน v1.0 (เรียงตามลำดับที่ควรสร้าง)

### 4.1 Auth & Setup
- [ ] ล็อกอินด้วย Google
- [ ] สร้างร้านครั้งแรก (shop name, PromptPay ID)

### 4.2 คลังสินค้า (Inventory)
- [ ] เพิ่ม/แก้ไข/ลบสินค้า (ชื่อ, รูป, ราคา, ราคาทุน, หมวดหมู่, สต็อก)
- [ ] คัดลอกสินค้า (duplicate)
- [ ] Import สินค้าจำนวนมากจาก CSV พร้อมหน้า preview ก่อนยืนยัน (เพิ่มใหม่ vs อัปเดต, ตั้งค่าสต็อกใหม่ vs บวกเพิ่ม)
- [ ] Export รายการสินค้าเป็น CSV/Excel

### 4.3 หน้าขาย (Point of Sale) — หน้าหลักของแอป
- [ ] ตารางสินค้าแบบการ์ดรูปใหญ่ กดเพิ่มลงตะกร้า เหมาะกับนิ้วสัมผัส iPad
- [ ] ค้นหาสินค้าด้วยชื่อ + กรองตามหมวดหมู่
- [ ] แสดงจำนวนสต็อกคงเหลือบนการ์ดแบบเรียลไทม์ (อัปเดตจาก local DB ทันที)
- [ ] ตะกร้า: ปรับจำนวน, ลบรายการ, ใส่ส่วนลด (% หรือจำนวนเงิน ทั้งรายการ/ทั้งบิล)
- [ ] ชำระเงินสด: ใส่จำนวนที่รับมา + ปุ่มลัด (พอดี / +20 / +50 / +100 / +500 / +1000) + คำนวณเงินทอนอัตโนมัติ
- [ ] ชำระ QR พร้อมเพย์: สร้าง QR ระบุยอดจากฝั่ง client (ไลบรารี promptpay-qr หรือเทียบเท่า — ทำงานได้โดยไม่ต้องใช้เน็ต) + ปุ่มยืนยันด้วยมือ (ไม่เช็กยอดอัตโนมัติ)
- [ ] ตัดสต็อกอัตโนมัติทันทีที่ปิดการขาย (ผ่าน StockMovement)
- [ ] หน้า "Checkout Success"

### 4.4 ประวัติการขาย & Void
- [ ] ดูประวัติการขายทั้งหมด เรียงตามเวลาล่าสุด
- [ ] Void รายการขาย (คืนสต็อกอัตโนมัติ, ทำได้แม้ offline, ยืนยันก่อนทำเพราะย้อนกลับไม่ได้)

### 4.5 รายงาน (Reports)
- [ ] การ์ดสรุป: ยอดขายวันนี้ / ยอดรวมทั้งหมด / จำนวนบิล
- [ ] กราฟสินค้าขายดี Top 5
- [ ] กราฟยอดขายตามช่วงเวลาในวัน
- [ ] กรองตามอีเวนต์และช่วงวันที่
- [ ] Export รายงานเป็น Excel

### 4.6 อีเวนต์ (Event)
- [ ] สร้าง/แก้ไข/ลบ อีเวนต์ (ชื่องาน, วันที่)
- [ ] เลือก "อีเวนต์ที่กำลังใช้งาน" เพื่อกรองหน้าขาย
- [ ] รายงานกรองแยกตามอีเวนต์ได้

### 4.7 Offline Sync Engine (ฝังอยู่ในทุกฟีเจอร์ด้านบน ไม่ใช่ฟีเจอร์แยก)
- [ ] เขียนทุกอย่างลง local DB (IndexedDB) ก่อนเสมอ ไม่รอ network response
- [ ] แถบ/ไอคอนสถานะแสดงจำนวนรายการที่ยัง "รอ sync" ให้เห็นตลอดเวลา
- [ ] Sync ขึ้น Firestore อัตโนมัติเมื่อกลับมามีเน็ต (background, ไม่ block UI)
- [ ] **บล็อกการ logout ถ้ายังมีรายการค้าง sync** (บทเรียนจาก Loyverse ที่ปล่อยให้ logout แล้วข้อมูลหาย)
- [ ] Cache รูปสินค้าทั้งหมดล่วงหน้าตอนออนไลน์ (กันปัญหารูปไม่ขึ้นตอน offline แบบที่ MakerGO เจอ)

## 5. สิ่งที่ตั้งใจ "ไม่ทำ" ใน v1.0 (ตัดออกชัดเจน กันขอบเขตบวม)

- ระบบหลายศิลปินแชร์บูธแบบเต็มรูปแบบ (multi-artist cart, commission, settlement) — เก็บแค่ field `artist_id` ไว้ในโครงสร้างข้อมูล แต่ยังไม่ทำ UI
- เชิญทีมงาน/หลายผู้ใช้ (multi-user invite)
- Variant สินค้า (ขนาด/ลาย), bundle/โปรโมชัน
- สแกนบาร์โค้ด, พิมพ์ใบเสร็จ Bluetooth
- บัตรเครดิต/payment gateway
- Partial void (void ได้แค่ทั้งบิล ยังไม่ต้องแยกรายชิ้น)

## 6. Non-functional requirements

- ใช้งานได้ลื่นบน Safari/iPad แม้ปิด Wi-Fi สนิท
- ข้อมูลการเงิน (Order, StockMovement) ต้องไม่สูญหายแม้ปิดแอปกะทันหันก่อน sync
- UI ต้องออกแบบให้กดด้วยนิ้วบนจอสัมผัส ปุ่มขนาดใหญ่พอ ไม่ใช่ UI สำหรับเมาส์
