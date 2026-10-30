# Dev Brief — Booth POS App v1.7 (Flutter + Firebase)

*ต่อยอดจาก `plan_v1.6.md` เอกสารนี้สรุปการตัดสินใจที่คุยกันทั้งหมด สิ่งที่ต้องแก้จากแผนเดิม และออกแบบระบบ Firebase ฉบับเริ่มต้น ที่เขียนให้ Antigravity IDE หรือ Claude Code ใช้ลงมือทำได้*

---

## 0. การตัดสินใจที่ล็อกแล้ว

| หัวข้อ | ตัดสินใจ |
|---|---|
| Framework | Flutter (ต่อยอดจาก repo `Pitchaya-Waree/Mypos`) |
| Local data | **Firestore offline cache อย่างเดียว** เลิกใช้ Hive |
| Backend | Firebase: Auth (Google), Firestore, Storage, Cloud Functions |
| Firestore region | `asia-southeast1` (Singapore) เลือกแล้วเปลี่ยนไม่ได้ |
| สต็อก | ติดลบได้ แล้วแจ้งเตือนให้ปรับ |
| จำนวนร้านต่อบัญชี | 1 บัญชี Google ดูแลได้หลายร้าน แต่ **1 ร้านมี 1 Owner** |
| บทบาท | **Owner** (1 คน/ร้าน) / **Manager** (หลายคน) / **Member** |
| รูปสินค้า | Firebase Storage (ต้องใช้แผน Blaze) |
| โครงสินค้า | **คลังกลางของร้าน** รูปอัปโหลดครั้งเดียว งานเลือกสินค้าจากคลังกลางไปขาย |

### ข้อที่ยืนยันแล้ว
- **สต็อกเป็นแบบกลาง**: 1 สินค้ามีสต็อกเดียวทั้งร้าน ไม่แยกตามงาน
- **Member เห็นเฉพาะออเดอร์ที่ตัวเองเป็นคนขาย** (ถ้าภายหลังต้องการให้เห็นทั้งร้าน ปรับตามหัวข้อ 6.2)
- **ช่องทางส่งมอบบน iPad**: รอตัดสินใจ (หัวข้อ 10.5)

---

## 1. สิ่งที่ต้องแก้จากแผน v1.5 / v1.6

1. **เลิกใช้ Hive** ย้ายข้อมูลทั้งหมดไป Firestore พร้อม offline cache ต้องเขียน Repository layer ครอบ (หัวข้อ 10.3) แล้วถอด `Local Hive Database service` ออก
2. **ยกเลิกกติกา "1 คน อยู่ได้ 1 ร้าน"** (ข้อ 4.7 ของ v1.5) เปลี่ยนเป็นหนึ่งบัญชีมีได้หลายร้าน เพิ่มหน้าเลือกร้านหลังล็อกอิน
3. **เพิ่มบทบาท Manager** v1.5 มีแค่ Owner/Member ตอนนี้เป็น 3 บทบาท (หัวข้อ 3)
4. **แยกราคาทุนออกจากสินค้า** Firestore Rules ซ่อนบาง field ไม่ได้ จึงแยกเป็นเอกสาร `productCosts` (หัวข้อ 4)
5. **แยก `commissionRate` ออกจาก Artist** ไปอยู่ใน `artistTerms` ที่ Owner เท่านั้นอ่านได้ เพราะเป็นข้อมูลการเงิน
6. **สินค้าไม่ผูกกับงาน** สินค้าอยู่ในคลังกลาง งานเลือกสินค้าผ่าน `eventProducts` (แทน `hiddenProducts` ในแผนเดิมที่เป็นแนวคิด "ซ่อน")
7. **ออเดอร์เก็บ items เป็น array ในเอกสารเดียว** เพื่อให้เขียนครั้งเดียวแบบ atomic ตอน offline และประหยัดจำนวน write (หัวข้อ 5)
8. **ใช้ `WriteBatch` + `FieldValue.increment` ห้ามใช้ `runTransaction` ตอนขาย** เพราะ transaction ทำงานตอน offline ไม่ได้
9. **แก้ acceptance criteria เดิมที่ขัดกัน**: ข้อ "ผู้ใช้ 1 คนอยู่ได้แค่ 1 ร้าน" และข้อ "Member เห็นยอดทุกคน" ให้ใช้ตามเอกสารนี้แทน
10. **เพิ่มงาน Cloud Functions** สำหรับสร้างร้าน เชิญทีม เปลี่ยนบทบาท นำออก และโอนความเป็นเจ้าของ (หัวข้อ 7) เพื่อไม่ให้ client เขียนข้อมูลสิทธิ์เองได้

> หมายเหตุ: ข้อมูลเกี่ยวกับโค้ดใน repo มาจาก README เท่านั้น Antigravity ต้องเปิดโค้ดจริงตรวจก่อนว่าโครงสร้างตรงกับที่ README อ้างหรือไม่

---

## 2. สถาปัตยกรรม

```
Flutter app (iPad / Android tablet / Web PWA)
  └─ PosProvider (state) ──> Repository layer (หัวข้อ 10.3)
                                 ├─ Firestore  (+ offline cache)   ข้อมูลทั้งหมด
                                 ├─ Storage                         รูปสินค้า
                                 ├─ Auth (Google Sign-In)           ตัวตนผู้ใช้
                                 └─ Cloud Functions (callable)      งานที่เกี่ยวกับสิทธิ์
```

หลักการ: **ทุกการขายเขียนลง Firestore cache ในเครื่องก่อน** SDK จะซิงก์ขึ้นเซิร์ฟเวอร์เมื่อมีเน็ต แอปไม่ต้องรอ network ตอนขาย

---

## 3. บทบาทและสิทธิ์

| ความสามารถ | Owner | Manager | Member |
|---|---|---|---|
| ขายสินค้า / ชำระเงิน | ✅ | ✅ | ✅ |
| ดูสินค้า / หมวดหมู่ | ✅ | ✅ | ✅ |
| เพิ่ม/แก้สินค้า หมวดหมู่ อีเวนต์ ศิลปิน | ✅ | ✅ | ❌ |
| ดูออเดอร์ / รายงานยอดขาย | ทั้งร้าน | ทั้งร้าน | เฉพาะที่ตัวเองขาย |
| Void ออเดอร์ | ✅ | ✅ | ❌ |
| ดูราคาทุน | ทุกชิ้น | เฉพาะของศิลปินที่ผูกกับตัวเอง | เฉพาะของศิลปินที่ผูกกับตัวเอง |
| แก้ PromptPay / ข้อมูลร้าน | ✅ | ❌ | ❌ |
| ดู/ตั้งค่า commission, Settlement | ✅ | ❌ | ❌ |
| เชิญคน | เชิญได้ทุกบทบาท (ยกเว้น Owner) | เชิญได้เฉพาะ Member | ❌ |
| เปลี่ยนบทบาท / นำสมาชิกออก | ✅ | ❌ | ❌ |
| โอนความเป็นเจ้าของ | ✅ | ❌ | ❌ |

ข้อกำหนด: ทุกร้านต้องมี Owner **พอดี 1 คน** เสมอ

---

## 4. Firestore Schema

```
users/{uid}
  displayName, email, createdAt
  memberships/{shopId}                 ← ดัชนีร้านของผู้ใช้ (ให้หน้าเลือกร้านใช้)
    role, shopName, joinedAt           (เขียนโดย Cloud Functions เท่านั้น)

shops/{shopId}
  name, ownerUid, promptpayId, promptpayName, currency, createdAt

  members/{uid}
    role (owner|manager|member), artistId (nullable), displayName, email, joinedAt

  invites/{inviteId}
    emailLower, role (manager|member), artistId (nullable),
    tokenHash, status (pending|accepted|expired|revoked),
    createdBy, createdAt, expiresAt (7 วัน)

  artists/{artistId}
    name, active, linkedUid (nullable)

  artistTerms/{artistId}               ← Owner เท่านั้น
    commissionRate (percent), note

  categories/{categoryId}
    name, parentId (null = root, ลึกสุด 2 ชั้น), sortOrder

  products/{productId}                 ← คลังกลาง ไม่สังกัดงาน
    artistId, categoryId, name, price, stock (ติดลบได้),
    imagePath, imageUrl, isBestseller, active (soft delete),
    updatedAt, updatedBy

  productCosts/{productId}
    cost, artistId                     (artistId ซ้ำจาก products เพื่อให้ rules ตรวจได้)

  events/{eventId}
    name, startDate, endDate, status (planned|active|closed)
    eventArtists/{artistId}            ← ศิลปินที่มาออกงานนี้
    eventProducts/{productId}          ← สินค้าที่นำมาขายในงานนี้

  orders/{orderId}                     ← orderId = UUID ที่ client สร้าง
    eventId, status (completed|voided), paymentMethod (cash|promptpay),
    subtotal, discountTotal, total, cashReceived, change,
    items: [ {productId, artistId, name, price, qty, discount, lineTotal} ],
    artistTotals: { "<artistId>": {gross, discount, net, qty} },
    createdBy, createdAt (serverTimestamp), createdAtClient (เวลาในเครื่อง),
    deviceId, voidedAt, voidedBy, voidReason

  stockMovements/{movementId}
    productId, orderId (nullable), type (sale|void|adjust|import),
    qtyChange, createdAt, createdBy

  settlements/{eventId}_{artistId}     ← Owner เท่านั้น
    eventId, artistId, grossSales, commissionAmount, netPayout,
    paid, paidAt, note, calculatedAt
```

### 4.1 เหตุผลของโครงสร้างสำคัญ
- **`items` เป็น array ในออเดอร์**: เขียนออเดอร์ใบเดียวจบ atomic และนับเป็น 1 write ออเดอร์หนึ่งใบไม่น่าเกินไม่กี่สิบรายการ ไม่ชนข้อจำกัด 1 MiB ของเอกสาร
- **`artistTotals`**: คำนวณสรุปรายศิลปินตอนขายและเก็บไว้ในออเดอร์ ทำให้ Settlement ใช้ aggregation `sum` ของ `artistTotals.<artistId>.net` ได้โดยไม่ต้องอ่านทุกออเดอร์
- **snapshot** (`name`, `price`, `artistId` ใน items): ประวัติการขายไม่เปลี่ยนแม้สินค้าถูกแก้หรือปิดการขายทีหลัง
- **soft delete** (`active: false`) แทนการลบสินค้า เพราะประวัติและรูปอาจยังถูกอ้างอิง

### 4.2 กติกาการตั้งค่าสินค้าและงาน (คลังกลาง)
- สร้างสินค้า + อัปโหลดรูป **ครั้งเดียว** ในคลังกลาง
- สร้างงานใหม่ → เลือกศิลปิน → เลือกสินค้าจากคลังกลางลง `eventProducts` ไม่ต้องอัปโหลดรูปซ้ำ
- ปุ่ม "ใช้ชุดเดียวกับงานล่าสุด" คัดลอกรายการ `eventArtists` และ `eventProducts` จากงานก่อนหน้า
- ปุ่ม "คัดลอกสินค้า" (duplicate) คัดลอกข้อมูลสินค้า ใช้ `imagePath` / `imageUrl` เดิมร่วมกัน (ไม่ copy ไฟล์รูป)
- ลบสินค้าออกจากงาน = ลบเฉพาะ `eventProducts/{id}` ไม่กระทบคลังกลาง
- ปิดสินค้าในคลังกลาง (`active: false`) ต้องเตือนก่อนว่ามีงานที่ใช้สินค้านี้อยู่กี่งาน
- หน้าขายแสดงสินค้าตามงานที่เปิดใช้อยู่: `eventProducts` ∩ ศิลปินใน `eventArtists` และ `active == true`
- ถ้าไม่เลือกงานใดเลย หน้าขายแสดงสินค้าทั้งคลัง (พฤติกรรมเดิม)

---

## 5. รูปแบบการเขียนข้อมูลที่ปลอดภัยตอน Offline

### 5.1 ขายสินค้า (`placeOrder`) — ใช้ WriteBatch เดียว
```
batch.set(orders/{orderId}, {...})                        // 1 write
for each item:
  batch.update(products/{pid}, {stock: increment(-qty),   // N writes
                                updatedAt, updatedBy})
  batch.set(stockMovements/sale_{orderId}_{pid}, {...})   // N writes
batch.commit()
```
- ใช้ `increment` เพราะเป็นการบวกลบแบบสลับที่ได้ หลายเครื่องขายพร้อมกัน/ซิงก์ทีหลังจึงไม่ทับกัน
- movement id แบบกำหนดเอง (`sale_{orderId}_{pid}`) ป้องกันการสร้างซ้ำ
- **สต็อกติดลบได้**: ไม่ต้องตรวจก่อนปิดการขาย แต่ UI ต้องแจ้งเตือนเมื่อสต็อกต่ำกว่า 0 ทั้งตอนขายและในหน้าคลัง
- หนึ่ง batch รับได้ไม่เกิน 500 operation (รายการต่อบิลจึงไม่ควรเกินราว 200 ชิ้น)

### 5.2 Void ออเดอร์ (`voidOrder`) — WriteBatch เดียว
```
batch.update(orders/{orderId}, {status:'voided', voidedAt, voidedBy, voidReason})
for each item:
  batch.update(products/{pid}, {stock: increment(+qty), ...})
  batch.set(stockMovements/void_{orderId}_{pid}, {...})
```
Rules อนุญาตให้ update ออเดอร์เฉพาะกรณี `completed → voided` ดังนั้นถ้าสองเครื่อง void ใบเดียวกัน เครื่องที่สองจะถูกปฏิเสธทั้ง batch (atomic) สต็อกจึงไม่ถูกคืนซ้ำ

### 5.3 จุดที่ต้องระวังกับ Firestore ตอน offline
1. **`await batch.commit()` จะไม่เสร็จจนกว่าจะออนไลน์** ห้ามบล็อก UI รอ ให้ถือว่าบันทึกสำเร็จเมื่อเขียนลง cache แล้ว และแนบ `.catchError` เพื่อบันทึกกรณีเซิร์ฟเวอร์ปฏิเสธภายหลังลงที่เก็บในเครื่อง แล้วแสดงแบนเนอร์ "รายการซิงก์ไม่สำเร็จ"
2. **ห้ามออกจากระบบหรือสลับบัญชีขณะมี pending writes**: รายการที่ค้างจะถูกส่งด้วยตัวตนผู้ใช้ปัจจุบัน ถ้าสลับบัญชีจะถูกปฏิเสธด้วย permission-denied แล้วหายไป (ตรงกับบทเรียนจาก Loyverse) ให้ตรวจ pending writes และบล็อก logout/switch shop
3. **`serverTimestamp` ของรายการ offline จะรู้ค่าเมื่อซิงก์** จึงเก็บ `createdAtClient` แยกไว้ใช้เรียงและทำกราฟรายชั่วโมง
4. **Firestore ไม่ cache ไฟล์ใน Storage** รูปต้อง cache เองด้วยแพ็กเกจ cache รูป (หัวข้อ 8)
5. **ค่าเริ่มต้นของ cache บนมือถือ** จำกัดขนาด ให้ตั้ง `cacheSizeBytes` ให้เหมาะสม และบนเว็บต้องเปิด persistence เอง

---

## 6. Security Rules

### 6.1 Firestore (`firestore.rules`)
โครงนี้เป็นฉบับเริ่มต้น ต้องทดสอบด้วย Emulator ก่อน deploy ทุกครั้ง

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function memberPath(shopId) {
      return /databases/$(database)/documents/shops/$(shopId)/members/$(request.auth.uid);
    }
    function isMember(shopId) { return signedIn() && exists(memberPath(shopId)); }
    function roleOf(shopId) { return get(memberPath(shopId)).data.role; }
    function isOwner(shopId) { return isMember(shopId) && roleOf(shopId) == 'owner'; }
    function isManagerUp(shopId) {
      return isMember(shopId) && roleOf(shopId) in ['owner', 'manager'];
    }
    function myArtistId(shopId) { return get(memberPath(shopId)).data.get('artistId', null); }
    function onlyChanges(keys) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(keys);
    }

    match /users/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
      match /memberships/{shopId} {
        allow read: if signedIn() && request.auth.uid == uid;
        allow write: if false;                       // Cloud Functions เท่านั้น
      }
    }

    match /shops/{shopId} {
      allow read: if isMember(shopId);
      allow update: if isOwner(shopId)
                    && request.resource.data.ownerUid == resource.data.ownerUid;
      allow create, delete: if false;                // createShop (Function) เท่านั้น

      match /members/{uid} {
        allow get: if isMember(shopId) && (request.auth.uid == uid || isManagerUp(shopId));
        allow list: if isManagerUp(shopId);
        allow write: if false;                       // Cloud Functions เท่านั้น
      }

      match /invites/{inviteId} {
        allow read: if isManagerUp(shopId);
        allow create: if isManagerUp(shopId)
          && request.resource.data.status == 'pending'
          && (isOwner(shopId)
              ? request.resource.data.role in ['manager', 'member']
              : request.resource.data.role == 'member');
        allow update, delete: if isManagerUp(shopId);   // revoke
      }

      match /artists/{artistId} {
        allow read: if isMember(shopId);
        allow write: if isManagerUp(shopId);
      }
      match /artistTerms/{artistId} {
        allow read, write: if isOwner(shopId);
      }
      match /categories/{categoryId} {
        allow read: if isMember(shopId);
        allow write: if isManagerUp(shopId);
      }

      match /products/{productId} {
        allow read: if isMember(shopId);
        allow create: if isManagerUp(shopId);
        allow update: if isManagerUp(shopId)
          || (isMember(shopId) && onlyChanges(['stock', 'updatedAt', 'updatedBy']));
        allow delete: if false;                      // ใช้ soft delete
      }
      match /productCosts/{productId} {
        allow read: if isOwner(shopId)
          || (isMember(shopId) && resource.data.artistId == myArtistId(shopId));
        allow create, update: if isOwner(shopId)
          || (isManagerUp(shopId) && request.resource.data.artistId == myArtistId(shopId));
        allow delete: if isOwner(shopId);
      }

      match /events/{eventId} {
        allow read: if isMember(shopId);
        allow write: if isManagerUp(shopId);
        match /{sub}/{docId} {                       // eventArtists, eventProducts
          allow read: if isMember(shopId);
          allow write: if isManagerUp(shopId);
        }
      }

      match /orders/{orderId} {
        allow get: if isMember(shopId)
          && (isManagerUp(shopId) || resource.data.createdBy == request.auth.uid);
        allow list: if isManagerUp(shopId)
          || (isMember(shopId) && resource.data.createdBy == request.auth.uid);
        allow create: if isMember(shopId)
          && request.resource.data.createdBy == request.auth.uid
          && request.resource.data.status == 'completed';
        allow update: if isManagerUp(shopId)
          && resource.data.status == 'completed'
          && request.resource.data.status == 'voided'
          && onlyChanges(['status', 'voidedAt', 'voidedBy', 'voidReason']);
        allow delete: if false;
      }

      match /stockMovements/{movementId} {
        allow read: if isManagerUp(shopId);
        allow create: if isMember(shopId);
        allow update, delete: if false;
      }

      match /settlements/{settlementId} {
        allow read, write: if isOwner(shopId);
      }
    }
  }
}
```

ข้อสังเกตเกี่ยวกับ rules ชุดนี้:
- **Query ต้องมีเงื่อนไขตรงกับ rules**: Member ที่ list ออเดอร์ต้องใส่ `where('createdBy', '==', uid)` และการ list `productCosts` ต้องใส่ `where('artistId', '==', myArtistId)` ไม่เช่นนั้นจะถูกปฏิเสธทั้ง query
- **Rules ที่เรียก `get()`/`exists()` นับเป็นการอ่านเพิ่ม** ช่วงแรกยอมรับได้ ถ้าโตขึ้นให้พิจารณาเก็บบทบาทไว้ใน custom claims ของ Auth token
- **`products` ที่ Member แก้ได้เฉพาะ `stock`**: ป้องกันการแก้ราคา แต่ Member ยังตั้งค่าสต็อกเป็นเลขอะไรก็ได้ ตรวจย้อนหลังได้จาก `stockMovements`
- **ตัวเลขยอดในออเดอร์คำนวณฝั่ง client** Rules ตรวจความถูกต้องของผลรวมไม่ได้ทั้งหมด จึงควรมีเครื่องมือกระทบยอด (หัวข้อ 12)

### 6.2 ถ้าต้องการให้ Member เห็นออเดอร์ทั้งร้าน
เปลี่ยน `allow get/list` ของ `orders` เป็น `isMember(shopId)` แต่ต้องยอมรับว่า Member จะเห็นยอดขายทุกศิลปิน (ไม่เห็นราคาทุนและ commission)

### 6.3 Storage (`storage.rules`)
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /shops/{shopId}/products/{fileName} {
      allow read: if request.auth != null
        && firestore.exists(/databases/(default)/documents/shops/$(shopId)/members/$(request.auth.uid));
      allow create, update: if request.auth != null
        && firestore.get(/databases/(default)/documents/shops/$(shopId)/members/$(request.auth.uid)).data.role in ['owner', 'manager']
        && request.resource.size < 300 * 1024
        && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null
        && firestore.get(/databases/(default)/documents/shops/$(shopId)/members/$(request.auth.uid)).data.role in ['owner', 'manager'];
    }
  }
}
```
หมายเหตุ: ลิงก์แบบ `getDownloadURL()` มี token ในตัว ใครมีลิงก์ก็เปิดรูปได้โดยไม่ผ่าน rules สำหรับรูปสินค้าขายหน้าบูธถือว่าความเสี่ยงต่ำ ถ้าต้องการเข้มกว่านี้ให้โหลดรูปผ่าน SDK ด้วยตัวตนผู้ใช้แทนการใช้ลิงก์ตรง

---

## 7. Cloud Functions (callable) — 5 ตัว

ทั้งหมดต้องตรวจ `request.auth` และสิทธิ์ฝั่งเซิร์ฟเวอร์ แล้วเขียน `members` และ `users/{uid}/memberships` พร้อมกันใน batch เดียว

| Function | หน้าที่ |
|---|---|
| `createShop(name)` | สร้าง `shops/{id}` ตั้ง `ownerUid`, สร้าง member role owner, สร้าง membership mirror, สร้าง artist เริ่มต้นหนึ่งคนให้เจ้าของ |
| `acceptInvite(shopId, inviteId, token)` | ตรวจ hash ของ token, อีเมลของผู้ล็อกอินตรงกับ `emailLower`, สถานะ `pending`, ยังไม่หมดอายุ แล้วสร้าง member + membership และเปลี่ยนสถานะเป็น `accepted` (ใช้ได้ครั้งเดียว) |
| `changeMemberRole(shopId, uid, role, artistId)` | Owner เท่านั้น เปลี่ยนเป็น manager/member และผูกกับศิลปิน ห้ามตั้งเป็น owner ผ่านฟังก์ชันนี้ |
| `removeMember(shopId, uid)` | Owner เท่านั้น ลบ member + membership และยกเลิกคำเชิญค้างของคนนั้น ห้ามลบ Owner |
| `transferOwnership(shopId, targetUid)` | Owner เท่านั้น ผู้รับต้องเป็น Manager อยู่แล้ว สลับบทบาท (เจ้าของเดิมเป็น Manager) และอัปเดต `ownerUid` ใน transaction เดียว |

การสร้างคำเชิญ: client สร้าง token สุ่ม เก็บเฉพาะ **hash (SHA-256)** ใน `invites/{id}.tokenHash` ส่ง token จริงในลิงก์เชิญ ห้ามเก็บ token ดิบ

ข้อควรพิจารณาในภายหลัง: การโอนความเป็นเจ้าของแบบยืนยันสองฝั่ง (ผู้รับกดรับ) เลื่อนไป v2

---

## 8. รูปสินค้า (Storage)

- Path: `shops/{shopId}/products/{productId}.jpg` (เขียนทับเมื่อเปลี่ยนรูป)
- ก่อนอัปโหลด ย่อด้านยาวสุดไม่เกินประมาณ 800 px บีบอัดให้ไม่เกิน ~250 KB (Rules จำกัดเพดานไว้ที่ 300 KB) ใช้แพ็กเกจ `flutter_image_compress`
- เอกสารสินค้าเก็บ `imagePath` และ `imageUrl`
- **Offline**: ใช้ `cached_network_image` และ **ดึงรูปทั้งหมดของสินค้าที่อยู่ในงานล่วงหน้า** (precache) ตอนเลือกงานหรือตอนออนไลน์ เพื่อไม่ให้รูปหายตอนออฟไลน์ (ปัญหาที่ MakerGO เจอ)
- อัปโหลดรูปต้องมีเน็ต แอปควรแสดงสถานะ "รอรูป" และอนุญาตให้บันทึกสินค้าก่อนได้ แล้วค่อยอัปโหลดทีหลัง

---

## 9. Indexes ที่คาดว่าต้องใช้ (`firestore.indexes.json`)

| Collection | Fields | ใช้ทำ |
|---|---|---|
| `orders` | `eventId` ↑, `createdAtClient` ↓ | ประวัติการขายต่องาน |
| `orders` | `createdBy` ↑, `createdAtClient` ↓ | Member ดูของตัวเอง |
| `orders` | `createdBy` ↑, `eventId` ↑, `createdAtClient` ↓ | Member ดูของตัวเองต่องาน |
| `products` | `active` ↑, `categoryId` ↑, `name` ↑ | มุมมองโฟลเดอร์ |
| `stockMovements` | `productId` ↑, `createdAt` ↓ | ประวัติสต็อกรายสินค้า |

Firestore จะแสดงลิงก์สร้าง index ใน error ตอนรัน query ครั้งแรก ให้ Antigravity นำมารวมไว้ในไฟล์นี้

**การค้นหาสินค้า**: Firestore ไม่รองรับค้นข้อความแบบมีคำอยู่ตรงไหนก็ได้ จึงโหลดสินค้าทั้งร้านเข้า memory (ใช้ listener + cache) แล้วกรองฝั่ง client ซึ่งพอสำหรับสินค้าระดับหลักร้อยถึงหลักพันชิ้น และโฟลเดอร์ต้องสร้างต้นไม้จากรายการ `categories` ทั้งหมดฝั่ง client เช่นกัน

---

## 10. คู่มือลงมือทำ (Flutter)

### 10.1 ตั้งค่าโปรเจกต์ Firebase (ผู้ใช้ทำเอง ครั้งเดียว)
1. สร้างโปรเจกต์ใน Firebase Console (เช่น `booth-pos-dev` และแยก `booth-pos-prod` ภายหลัง)
2. เปิด Firestore (Production mode, `asia-southeast1`) และ Authentication (Google)
3. อัปเกรดเป็น **Blaze** เมื่อพร้อมใช้ Storage และ Functions แล้ว **ตั้ง Budget alert ต่ำ ๆ ทันที** (เป็นแค่การแจ้งเตือน ไม่ได้หยุดการใช้งานให้เอง)
4. ติดตั้ง `firebase-tools` และ `flutterfire_cli` แล้วรัน `firebase login` และ `flutterfire configure` ในโฟลเดอร์ Flutter

### 10.2 แพ็กเกจที่ต้องใช้
`firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `firebase_storage`, `cloud_functions`, `cached_network_image`, `flutter_image_compress`, `uuid`, `shared_preferences` และแนะนำ `firebase_app_check` ในภายหลัง

### 10.3 Repository layer ที่ต้องสร้าง (แทนที่ Hive service)
```
AuthRepository         signInWithGoogle, signOut(ตรวจ pending writes ก่อน), authState
ShopRepository         listMyShops (users/{uid}/memberships), selectShop, updateShop
MemberRepository       listMembers, createInvite, revokeInvite  (+ เรียก Functions)
CatalogRepository      watchProducts, watchCategories, upsertProduct, setActive,
                       uploadProductImage
EventRepository        watchEvents, upsertEvent, setEventArtists, setEventProducts,
                       cloneFromEvent
OrderRepository        placeOrder (WriteBatch), voidOrder, watchOrders, pendingCount
StockRepository        manualAdjust, watchMovements
SettlementRepository   computeForEvent (aggregation), markPaid, exportCsv
```
- `PosProvider` เรียกผ่าน repository เท่านั้น ไม่เรียก Firestore ตรง
- Firestore settings: เปิด `persistenceEnabled`, ตั้ง `cacheSizeBytes` ให้พอ (บนเว็บต้องเปิด persistence เอง)
- ตัวนับ "รอซิงก์": ใช้ snapshot metadata (`hasPendingWrites`) และตรวจ `waitForPendingWrites` ก่อน logout

### 10.4 ทดสอบด้วย Firebase Emulator Suite (แนะนำเริ่มทันที)
รัน Firestore + Auth + Functions + Storage emulator ในเครื่อง พัฒนาและทดสอบ rules โดยไม่ใช้ข้อมูลจริง ไม่เสียค่าใช้จ่าย และกันความผิดพลาดกับข้อมูลจริง เขียน rules test ด้วย `@firebase/rules-unit-testing` ตาม acceptance criteria หัวข้อ 12

### 10.5 การส่งมอบแอปบน iPad (ต้องตัดสินใจ ส่งผลต่อค่าใช้จ่าย)
**แนวทางที่ตัดสินใจแล้ว**: ผู้ใช้โหลดแอปจาก App Store บน iPad ได้ฟรี แล้วล็อกอิน Google เข้าร้าน ผู้พัฒนาจ่ายค่า Apple Developer Program ปีละครั้ง (ประมาณ 99 USD) ตรวจราคาล่าสุดกับ Apple

- **Flutter Web / PWA** ทดสอบระหว่างพัฒนาเท่านั้น ไม่ใช้เป็นช่องทางใช้งานจริงหน้าบูธ เพราะ Safari อาจล้างข้อมูล offline
- **แอป iOS บน App Store** ใช้งานจริง โดยใช้การเผยแพร่แบบ Unlisted (เฉพาะคนที่มีลิงก์) หรือ Public ตามที่ตกลง
- **TestFlight** ใช้ตอนทดสอบกับกลุ่มเล็ก บิลด์หมดอายุใน 90 วัน
- ต้องมี **Sign in with Apple** คู่กับ Google Sign-In เพราะ App Store Guideline 4.8 กำหนดไว้เมื่อแอปมีการล็อกอินของบุคคลที่สาม
- Android tablet ไม่อยู่ในขอบเขตช่วงนี้

---

## 11. ค่าใช้จ่าย (สำหรับร้านขนาดเล็ก)

โควตาฟรีหลัก (ตรวจจากหน้าราคา Firebase ณ ตุลาคม 2026):
- **Firestore (ฟรีทั้ง Spark และ Blaze)**: เก็บ 1 GiB, อ่าน 50,000/วัน, เขียน 20,000/วัน, ลบ 20,000/วัน
- **Auth แบบมาตรฐาน (Google)**: ฟรี ถึง 50,000 MAU
- **Cloud Functions (Blaze)**: ฟรี 2 ล้านครั้ง/เดือน
- **Storage**: ต้องใช้ Blaze ตั้งแต่ 3 กุมภาพันธ์ 2026 แต่ยังมีโควตาฟรี (ราว 5 GB เก็บข้อมูล โควตาดาวน์โหลดและจำนวนครั้งต่างกันตามชนิด bucket) ตรวจตัวเลขของ bucket ที่ใช้อยู่ในหน้า pricing
- **Hosting**: ฟรี 10 GB เก็บ และโควตาถ่ายโอนรายวัน

ประมาณการภาระ: ออเดอร์ 5 รายการ = ประมาณ 11 writes (1 ออเดอร์ + 5 อัปเดตสต็อก + 5 movement) ถ้าขาย 200 ใบ/วัน ≈ 2,200 writes ต่ำกว่าโควตา 20,000 มาก ภาระการอ่านขึ้นกับ listener และการดึงรายงาน ต้องเฝ้าดูจากหน้า Usage ช่วงแรก

ราคาเมื่อเกินโควตา **แต่ละแหล่งข้อมูลให้ตัวเลขไม่ตรงกันและขึ้นกับ region** จึงไม่ควรยึดตัวเลขในเอกสารนี้ ให้เปิดหน้า pricing ทางการตรวจกับ region ที่ใช้จริง

**มาตรการกันค่าใช้จ่ายบานปลาย**
1. ตั้ง Budget alert ต่ำ (เช่น 100–200 บาท) และตรวจ Usage สัปดาห์แรก ๆ
2. ห้ามดึงทั้ง collection ทุกครั้ง ใช้ listener + cache และ query ที่มีเงื่อนไข
3. จำกัดขนาดรูป (หัวข้อ 8)
4. อย่าเปิดการยืนยันตัวตนด้วย SMS (คิดเงินต่อข้อความ)

---

## 12. Acceptance Criteria (เฉพาะส่วน Firebase)

### 12.1 Security Rules (ทดสอบด้วย Emulator)
- ผู้ใช้ที่ไม่ได้ล็อกอิน อ่าน/เขียนข้อมูลใด ๆ ไม่ได้
- ผู้ใช้ที่ไม่ใช่สมาชิกของร้าน A อ่านเอกสารใต้ `shops/A` ไม่ได้
- Member แก้ราคาสินค้าไม่ได้ แต่ลดสต็อกสินค้าได้
- Manager อ่าน `settlements` และ `artistTerms` ไม่ได้
- Manager แก้ `promptpayId` ไม่ได้ ส่วน Owner แก้ได้
- Member ที่ผูกกับศิลปิน X อ่าน `productCosts` ของศิลปิน Y ไม่ได้
- Owner อ่าน `productCosts` ได้ทุกชิ้น
- Member list ออเดอร์โดยไม่ใส่ `createdBy == uid` ถูกปฏิเสธ
- ไม่มีใครลบออเดอร์หรือแก้ `stockMovements` ได้
- Update ออเดอร์ที่ `voided` แล้วให้เป็น `voided` ซ้ำ ถูกปฏิเสธ
- Client เขียน `members` และ `users/*/memberships` เองไม่ได้
- Manager สร้างคำเชิญบทบาท manager ไม่ได้ (ทำได้เฉพาะ member)

### 12.2 Offline และ Sync
- ปิดเน็ต ขาย 5 บิล แล้วเปิดเน็ต → ออเดอร์ทั้ง 5, การตัดสต็อก และ movement ขึ้น Firestore ครบ ไม่ซ้ำ
- สองเครื่องขายสินค้าชิ้นสุดท้ายพร้อมกันตอน offline แล้วซิงก์ → สต็อกเป็น -1 (ไม่ error) และมีแจ้งเตือนให้ปรับสต็อก
- มี pending writes อยู่ แล้วกด logout หรือสลับร้าน → ถูกบล็อกพร้อมแสดงจำนวนที่ค้าง
- สองเครื่อง void ออเดอร์เดียวกัน → สต็อกถูกคืนเพียงครั้งเดียว
- ปิดแอปกลางคันขณะมีรายการค้างแล้วเปิดใหม่ตอนออนไลน์ → รายการที่ค้างซิงก์ครบไม่ซ้ำ
- รายการที่เซิร์ฟเวอร์ปฏิเสธภายหลังต้องปรากฏในแบนเนอร์ความผิดพลาดและไม่หายเงียบ ๆ
- ปิดเน็ตแล้วเปิดแอปใหม่ → เห็นสินค้าและรูปของงานที่เลือกไว้ล่วงหน้าครบ

### 12.3 หลายร้าน / ทีม / บทบาท
- บัญชีเดียวที่เป็นสมาชิก 2 ร้านเห็นหน้าเลือกร้าน และข้อมูลของแต่ละร้านไม่ปนกัน
- ลิงก์เชิญหมดอายุหลัง 7 วัน และใช้ซ้ำไม่ได้
- ใช้ลิงก์เชิญด้วยอีเมลคนละอีเมลกับที่เชิญ → ถูกปฏิเสธ
- `removeMember` แล้ว ผู้ถูกนำออกเข้าถึงข้อมูลร้านไม่ได้ทันทีที่ซิงก์ และคำเชิญค้างของเขาถูกยกเลิก
- `transferOwnership` ให้คนที่ไม่ใช่ Manager ไม่ได้ และหลังโอนร้านมี Owner พอดี 1 คน
- ไม่มีทางทำให้ร้านมี Owner 0 คนหรือมากกว่า 1 คนผ่านฟังก์ชันใด

### 12.4 คลังกลาง รูป และงาน
- สร้างสินค้า 1 ชิ้นแล้วเลือกเข้างาน A และงาน B → รูปไฟล์เดียวใน Storage ไม่มีการอัปโหลดซ้ำ
- "ใช้ชุดเดียวกับงานล่าสุด" คัดลอก `eventArtists` และ `eventProducts` ครบ
- ลบสินค้าออกจากงาน A → ยังอยู่ในคลังกลางและงาน B
- ปิดสินค้า (`active: false`) ที่ใช้อยู่ใน 2 งาน → แสดงคำเตือนระบุจำนวนงาน และประวัติขายเดิมยังแสดงชื่อ/ราคา ณ ตอนขายถูกต้อง
- อัปโหลดรูปเกิน 300 KB หรือไม่ใช่ไฟล์รูป → ถูก Storage Rules ปฏิเสธ
- สมาชิกที่ไม่ใช่ Manager ขึ้นไป อัปโหลดรูปไม่ได้

### 12.5 Settlement
- ยอดรวมจาก aggregation ต่อศิลปินตรงกับผลรวมของ `artistTotals.<id>.net` ในออเดอร์ `completed` ของงานนั้น และไม่รวมออเดอร์ที่ void
- Settlement ไม่ถูกปิดถ้ายังมี pending writes ค้างอยู่ (เตือนก่อน)
- กด "จ่ายแล้ว" เก็บ `paid`, `paidAt` และกดซ้ำไม่จ่ายซ้ำ

---

## 13. ความเสี่ยงและคำถามค้าง

1. **ยืนยันสต็อกแบบกลาง** (หัวข้อ 0)
2. **ยืนยันขอบเขตที่ Member เห็นออเดอร์** (หัวข้อ 0 และ 6.2)
3. **ช่องทางส่งมอบบน iPad**: PWA หรือแอปเนทีฟ (หัวข้อ 10.5) กระทบทั้งค่าใช้จ่ายและพฤติกรรม offline
4. **ลิงก์เชิญ** ต้องกำหนดรูปแบบ (deep link / URL ของเว็บ) ให้เปิดแอปหรือหน้ารับคำเชิญได้
5. **Cloud Functions เพิ่มความซับซ้อน** ถ้าต้องการลดภาระช่วงแรก อาจทำเฉพาะ `createShop` และ `acceptInvite` ก่อน แล้วปล่อยการเปลี่ยนบทบาท/นำออก/โอน ให้ Owner ทำผ่าน rules ที่เข้มพร้อมเครื่องมือกู้คืน (แต่ปลอดภัยน้อยกว่า)
6. **สต็อกคำนวณซ้ำ**: `products.stock` เป็นค่า cache ถ้าผิดเพี้ยน ควรมีปุ่ม "ตรวจสอบสต็อก" ของ Owner ที่คำนวณจาก `stockMovements` เทียบกับค่าปัจจุบัน
7. **รายงานรายวัน** ถ้าออเดอร์เยอะขึ้น การดึงรายงานด้วยการอ่านออเดอร์ทั้งช่วงจะเปลืองจำนวนอ่าน อาจต้องสรุปรายวันด้วย Function ใน v2
8. **ความถูกต้องของตัวเลขยอด** คำนวณฝั่ง client ถ้าเกิดความผิดพลาดต้องแก้โดย Void แล้วขายใหม่ ไม่ให้แก้ออเดอร์เดิม

---

## 14. ลำดับการสร้าง (Milestones)

1. ตั้งค่า Firebase + `flutterfire configure` + Emulator Suite + ล็อกอิน Google
2. `createShop` + หน้าเลือกร้าน (หลายร้านต่อบัญชี)
3. Repository layer แทน Hive: ร้าน ศิลปิน หมวดหมู่ สินค้า + ราคาทุน (พร้อม rules และ rules tests)
4. อัปโหลดรูป (Storage + บีบอัด + precache)
5. `placeOrder` / `voidOrder` ด้วย WriteBatch + แบนเนอร์ pending/failed + บล็อก logout
6. อีเวนต์: `eventArtists`, `eventProducts`, คัดลอกจากงานก่อน
7. รายงานและ Settlement (aggregation) + commission
8. เชิญทีม: `acceptInvite`, `changeMemberRole`, `removeMember`, `transferOwnership`
9. ทดสอบตามหัวข้อ 12 ทั้งหมดบนอุปกรณ์จริง (ปิดเน็ตจริงหน้างานจำลอง)
