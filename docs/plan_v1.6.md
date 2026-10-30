# Dev Brief — Booth POS App v1.6 (ฉบับอัปเดตจาก GitHub MyPOS)

*ต่อยอดจาก `plan_v1.5.md` โดยเพิ่มข้อมูลจาก repository https://github.com/Pitchaya-Waree/Mypos และแยกรายละเอียดยอดขายต่อร้าน (ร้าน A / ร้าน B) ให้ชัดเจน*

---

## 0. ข้อสังเกตสำคัญก่อนอ่าน

1. **Repo ไม่มีข้อมูลสินค้าหรือยอดขายของร้าน A / ร้าน B** — ข้อมูลร้านทั้งหมดในแอปถูกเก็บในเครื่องผ่าน Hive Local Database ตอนใช้งานจริง ไม่ได้ commit มาใน repo ส่วนนี้ต้องได้รับจากเจ้าของโปรเจกต์ (ดูหัวข้อ 6)
2. **เทคโนโลยีใน repo ต่างจากแผน v1.5** — แผนเดิมเขียนเป็น PWA + Dexie/IndexedDB แต่ repo ใช้ **Flutter + Hive** ดูหัวข้อ 2
3. **โครงสร้างโปรเจกต์ใน repo** ที่เห็นจากหน้าเว็บ มีเพียง `Mypos/` (Landing Page) และ `booth_pos_app/` ซึ่งอ้างใน README แต่ไม่ปรากฏในรายการไฟล์ระดับ root ของหน้า GitHub จึงยืนยันไม่ได้ว่าโค้ดแอปอยู่ใน repo ครบหรือไม่

---

## 1. ภาพรวมจาก README ของ repo

ระบบเป็น POS สำหรับขายสินค้าหน้าบูธงานอาร์ตแฟร์ (Art Fair / Creator Booth) ใช้งานได้บน iPad, Android Tablet, Web PWA และ Desktop ออกแบบแบบ **Offline-First** ตามเจตนารมณ์เดียวกับแผน v1.5

สิ่งที่ README ระบุว่าทำแล้ว (ตรงกับแผน v1.5 เกือบทั้งหมด):
- Offline-First ด้วย Local DB และ `StockMovement` ป้องกันสต็อกชนกันตอน sync
- แถบสถานะซิงก์ (`ออฟไลน์พร้อม` / `X รอซิงก์`) และบล็อกการ logout ถ้ายังมีข้อมูลค้าง
- หมวดหมู่แบบโฟลเดอร์ 2 ระดับ พร้อม breadcrumb, All Items และ Global Search
- ตะกร้าหลายศิลปิน, Snapshot `artist_id` ตอนขาย, ส่วนลดแบบสัดส่วน (Proportional) และส่วนลดเฉพาะศิลปิน
- Commission (`commission_rate %`), หน้า Settlement (Gross → หักค่าคอม → Net Payout), Mark as Paid, ส่งออก CSV
- แป้นตัวเลขรับเงินสด พร้อมปุ่มลัด และ PromptPay QR แบบ EMVCo สร้างออฟไลน์ได้
- บทบาท Owner / Member, ซ่อนราคาทุนของศิลปินอื่นสำหรับ Member, ลิงก์เชิญอายุ 7 วัน

### ชุดทดสอบที่ README ระบุ (ใช้เป็น acceptance criteria อ้างอิงได้)
- Proportional Discount, Artist-Specific Discount
- Settlement & Commission, Voided Orders Excluded
- Cost Visibility Rules (Owner vs Member)
- Stock Limit Prevention
- PromptPay EMVCo Payload

> หมายเหตุ: README ระบุว่ามี automated tests แต่ยังไม่ได้ตรวจสอบโค้ดจริงใน repo จึงยืนยันว่าเทสต์ผ่านหรือครอบคลุมครบไม่ได้

---

## 2. ความต่างด้านเทคโนโลยี (ต้องตัดสินใจ)

| หัวข้อ | แผน v1.5 | repo (ตาม README) |
|---|---|---|
| Framework | PWA (HTML/JS) | Flutter 3.24+ / Dart 3.10+ |
| Local DB | IndexedDB ผ่าน Dexie.js หรือ RxDB | Hive |
| Backend | Firebase Firestore | ไม่ระบุใน README |
| Auth | Firebase Auth + Google | ไม่ระบุใน README |
| Target | iPad ผ่าน Safari (PWA) | iPad, Android, Web, Windows Desktop |
| State management | ไม่ระบุ | PosProvider |

**คำถามที่ต้องตอบก่อนพัฒนาต่อ**: จะเดินหน้าด้วย Flutter (ตาม repo) หรือกลับไปใช้ PWA (ตามแผน v1.5)
- ถ้าเลือก Flutter: ได้แอปข้ามแพลตฟอร์มจริง แต่ต้องตรวจว่าการเชื่อม Firebase และ Hive sync ทำงานได้ตามเกณฑ์ offline ในหัวข้อ 4.12 ของ v1.5
- ถ้าเลือก PWA: ทำตามแผน v1.5 เดิมได้ทันที แต่ต้องทิ้งโค้ดที่มีใน repo บางส่วน

---

## 3. โครงสร้างโมเดลข้อมูลตาม repo (จาก README)

README ระบุ models ไว้ดังนี้ ซึ่งสอดคล้องกับ data model ของ v1.5:

```
lib/models/
  Shop, Member, Artist, Category, Product, Order, Settlement
lib/services/
  Local Hive Database, PromptPay Generator
lib/providers/
  PosProvider (state + multi-artist calculations)
lib/views/
  POS, Inventory, Settlement, Team, History, Reports, Settings
```

**สิ่งที่ยังไม่ปรากฏใน README** (ควรเช็กกับโค้ดจริงก่อนยืนยัน):
- `Event` และ `EventArtist` (ความสัมพันธ์ many-to-many ตามข้อ 4.11 ของ v1.5) — README ไม่ได้ระบุชื่อ model นี้
- `Invite` (ตารางคำเชิญ) — README ระบุเพียงว่ามีลิงก์เชิญ Invite Token
- `OrderItem` ที่เก็บ `name_snapshot`, `price_snapshot`, `artist_id`

---

## 4. รายละเอียดยอดขายแยกตามร้าน (ร้าน A / ร้าน B)

**สถานะ: สร้างชุดข้อมูลตัวอย่าง (Seed Data) และบันทึกลงใน Hive Local DB พร้อมระบบสลับร้านค้าเรียบร้อยแล้ว**

### ร้าน A: Mako Shop (Booth #A14)
- **Shop ID:** `shop_a` | **PromptPay:** `0812345678` (Rickky PosMaker)
- **เจ้าของ (Owner):** Rickky (User ID: `user_rickky_01`)
- **ศิลปินในร้าน:**
  1. `Rickky Art` (artist_rickky) — ค่าคอมมิชชัน 0% (เจ้าของร้าน)
  2. `Mimi Craft` (artist_mimi) — ค่าคอมมิชชัน 10.0%

#### รายการสินค้าและยอดจำหน่ายสะสม (ร้าน A)
| ลำดับ | สินค้า | ศิลปิน (artist_id) | หมวดหมู่ | ราคาขาย | ราคาทุน | จำนวนที่ขายได้ | ยอดขายรวม (Gross) | ส่วนลด | ยอดสุทธิ (Net Sales) |
|:---:|---|---|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Sticker Cat Day | Rickky Art (`artist_rickky`) | Sticker > ลายแมว (Cat) | ฿45.00 | ฿15.00 | 2 | ฿90.00 | ฿0.00 | ฿90.00 |
| 2 | Coffee Boy Postcard | Rickky Art (`artist_rickky`) | Postcard | ฿35.00 | ฿10.00 | 3 | ฿105.00 | ฿10.77 | ฿94.23 |
| 3 | Holo Memo Pad | Rickky Art (`artist_rickky`) | Memo Pad | ฿80.00 | ฿30.00 | 0 *(ยกเลิก 1)* | ฿0.00 | ฿0.00 | ฿0.00 *(Voided)* |
| 4 | Shiba Inu Sticker | Mimi Craft (`artist_mimi`) | Sticker > ลายหมา (Dog) | ฿45.00 | ฿15.00 | 2 | ฿90.00 | ฿9.23 | ฿80.77 |
| 5 | Floral Acrylic Stand | Mimi Craft (`artist_mimi`) | Acrylic & Keyring | ฿120.00 | ฿45.00 | 1 | ฿120.00 | ฿0.00 | ฿120.00 |
| 6 | Galaxy Keyring | Mimi Craft (`artist_mimi`) | Acrylic & Keyring | ฿65.00 | ฿20.00 | 2 | ฿130.00 | ฿10.00 | ฿120.00 |

#### สรุปบิลขายตัวอย่างของร้าน A
1. **Order A1** (`order_a1` - เงินสด): Sticker Cat Day x2 (฿90) + Floral Acrylic Stand x1 (฿120) = **฿210.00**
2. **Order A2** (`order_a2` - PromptPay QR): Coffee Boy Postcard x3 (฿105) + Shiba Inu Sticker x2 (฿90) ยอดรวม ฿195 หักส่วนลดทั้งบิลแบบสัดส่วน ฿20.00 = **฿175.00**
3. **Order A3** (`order_a3` - เงินสด): Galaxy Keyring x2 (฿130) หักส่วนลดเฉพาะศิลปิน Mimi Craft ฿10.00 = **฿120.00**
4. **Order A4** (`order_a4` - ยกเลิกบิล Voided): Holo Memo Pad x1 (฿80) สถานะ `voided` ไม่นำมารวมยอดและคืนสต็อกเรียบร้อย

#### สรุปส่วนแบ่ง Settlement ร้าน A
- **Rickky Art:** ยอดขายสุทธิ ฿184.23 | หักค่าคอม 0% (฿0.00) | **ยอดรับสุทธิ (Net Payout): ฿184.23**
- **Mimi Craft:** ยอดขายสุทธิ ฿320.77 | หักค่าคอม 10% (฿32.08) | **ยอดรับสุทธิ (Net Payout): ฿288.69**
- **ยอดขายรวมร้าน A (Total Revenue):** **฿505.00** (ค่าคอมเข้าร้าน ฿32.08)

---

### ร้าน B: Crafty Fox Studio (Booth #B08)
- **Shop ID:** `shop_b` | **PromptPay:** `0899998888` (Kitsune Fox Studio)
- **เจ้าของ (Owner):** Kitsune (User ID: `user_kitsune_01`)
- **ศิลปินในร้าน:**
  1. `Kitsune Studio` (artist_kitsune) — ค่าคอมมิชชัน 0% (เจ้าของร้าน)
  2. `Neko Pottery` (artist_neko) — ค่าคอมมิชชัน 15.0%

#### รายการสินค้าและยอดจำหน่ายสะสม (ร้าน B)
| ลำดับ | สินค้า | ศิลปิน (artist_id) | หมวดหมู่ | ราคาขาย | ราคาทุน | จำนวนที่ขายได้ | ยอดขายรวม (Gross) | ส่วนลด | ยอดสุทธิ (Net Sales) |
|:---:|---|---|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Fox Ceramic Mug | Kitsune Studio (`artist_kitsune`) | Ceramics & Pottery | ฿280.00 | ฿90.00 | 2 | ฿560.00 | ฿18.67 | ฿541.33 |
| 2 | Linen Tote Bag | Kitsune Studio (`artist_kitsune`) | Linen & Textiles | ฿220.00 | ฿70.00 | 1 | ฿220.00 | ฿0.00 | ฿220.00 |
| 3 | Sticker Cat Day *(Shop B)* | Kitsune Studio (`artist_kitsune`) | Stickers & Prints | ฿50.00 | ฿18.00 | 3 | ฿150.00 | ฿0.00 | ฿150.00 |
| 4 | Neko Clay Figurine | Neko Pottery (`artist_neko`) | Ceramics & Pottery | ฿390.00 | ฿120.00 | 1 | ฿390.00 | ฿0.00 | ฿390.00 |
| 5 | Cat Teacup Set | Neko Pottery (`artist_neko`) | Ceramics & Pottery | ฿320.00 | ฿100.00 | 1 | ฿320.00 | ฿21.33 | ฿298.67 |

#### สรุปบิลขายตัวอย่างของร้าน B
1. **Order B1** (`order_b1` - PromptPay QR): Fox Ceramic Mug x1 (฿280) + Linen Tote Bag x1 (฿220) = **฿500.00**
2. **Order B2** (`order_b2` - เงินสด): Sticker Cat Day x3 (฿150) + Neko Clay Figurine x1 (฿390) = **฿540.00**
3. **Order B3** (`order_b3` - เงินสด): Cat Teacup Set x1 (฿320) + Fox Ceramic Mug x1 (฿280) ยอดรวม ฿600 หักส่วนลดทั้งบิลแบบสัดส่วน ฿40.00 = **฿560.00**

#### สรุปส่วนแบ่ง Settlement ร้าน B
- **Kitsune Studio:** ยอดขายสุทธิ ฿911.33 | หักค่าคอม 0% (฿0.00) | **ยอดรับสุทธิ (Net Payout): ฿911.33**
- **Neko Pottery:** ยอดขายสุทธิ ฿688.67 | หักค่าคอม 15% (฿103.30) | **ยอดรับสุทธิ (Net Payout): ฿585.37**
- **ยอดขายรวมร้าน B (Total Revenue):** **฿1,600.00** (ค่าคอมเข้าร้าน ฿103.30)

### หมายเหตุการแยกข้อมูล
- ยอดขายแยกตาม `OrderItem.artist_id` (snapshot ตอนขาย) ไม่ใช่ตาม Product ปัจจุบัน
- ตัด order ที่ `status = voided` ออกก่อนรวมยอด และคืนสต็อกในระบบ
- ราคาทุนแสดงเฉพาะ Owner หรือ Member ที่ผูกกับศิลปินนั้น ตามกติกาในข้อ 4.8 ของ v1.5
- สินค้า "Sticker Cat Day" ปรากฏทั้งสองร้าน แต่แยกคนละ `shop_id` ชัดเจน ไม่ปะปนกัน

---

## 5. Acceptance Criteria ที่เพิ่มจาก repo

ใช้ชุดทดสอบของ repo เป็นฐาน และเพิ่มเกณฑ์ต่อไปนี้เพื่อให้เห็นการแยกข้อมูลระหว่างร้าน

- มีร้าน A และร้าน B ในแอปเดียวกัน → การขายในร้าน A ต้องไม่ปรากฏในรายงานของร้าน B และกลับกัน
- ร้าน A มีสินค้าชื่อเดียวกับร้าน B (เช่น "Sticker ลายแมว") → ระบบต้องแยกเป็นคนละ Product โดยมี `shop_id` ต่างกัน ห้าม merge ตอน import CSV
- Owner ของร้าน A ไม่สามารถเปิดข้อมูลของร้าน B ได้ แม้ทั้งสองร้านอยู่บนเครื่องเดียวกัน
- Member ของร้าน A (ผูกกับศิลปิน X) เห็นราคาทุนได้เฉพาะสินค้าของศิลปิน X ในร้าน A เท่านั้น
- ผู้ใช้ 1 คนอยู่ได้แค่ 1 ร้านตามกติกาข้อ 4.7 ของ v1.5 → ถ้าต้องการให้ Owner คนเดียวดูแลทั้งร้าน A และ B ต้องพิจารณาเพิ่มเติม (ดูหัวข้อ 6)

---

## 6. ข้อมูลที่ต้องการจากเจ้าของโปรเจกต์เพื่อเติมหัวข้อ 4

เลือกอย่างใดอย่างหนึ่ง:
1. **Export ข้อมูลจากแอป** — ไฟล์ CSV หรือ Excel ของรายการขาย (ฟีเจอร์ export ที่ README ระบุไว้) แยกตามร้าน
2. **ไฟล์ Hive** หรือ JSON dump จากเครื่องที่ใช้งานจริง
3. **Screenshot หน้า Reports / Settlement** ของร้าน A และร้าน B พร้อมตัวเลขที่มองเห็น
4. **ยืนยันว่าร้าน A และ B เป็นตัวอย่างสำหรับทดสอบ** (ไม่ใช่ข้อมูลจริง) — ถ้าเป็นเช่นนั้นจะสร้าง seed data ให้แทนได้

และขอให้ยืนยันเพิ่มว่า
- โค้ดแอป `booth_pos_app/` อยู่ใน repo จริงหรือไม่ (ไม่เห็นในรายการไฟล์ระดับ root)
- จะใช้ Flutter หรือ PWA เป็นแนวทางหลักต่อไป (ดูหัวข้อ 2)

---

## 7. สิ่งที่ยังไม่ทำใน v1.6 (คงตาม v1.5)

- Partial void
- Role "artist" ที่เห็นเฉพาะยอดของตัวเอง
- หลายเครื่องใน 1 บูธ sync กันผ่านเครือข่ายท้องถิ่น
- Variant สินค้า, bundle/โปรโมชัน
- สแกนบาร์โค้ด, พิมพ์ใบเสร็จ Bluetooth
- บัตรเครดิต/payment gateway
- โฟลเดอร์หมวดหมู่ซ้อนเกิน 2 ชั้น
- Owner คนเดียวดูแลหลายร้าน (รอตัดสินใจ)

---

## 8. Non-functional requirements (คงตาม v1.5)

- ใช้งานได้ลื่นบน iPad แม้ปิด Wi-Fi สนิท
- ข้อมูลการเงิน (Order, StockMovement, Settlement) ต้องไม่สูญหายแม้ปิดแอปกะทันหันก่อน sync
- UI กดด้วยนิ้วบนจอสัมผัส ปุ่มขนาดใหญ่
- การแยกข้อมูลระหว่างร้านต้องทำที่ระดับ `shop_id` ทุกตารางและทุก query
