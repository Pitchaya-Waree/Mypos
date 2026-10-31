Gemini ในคอนโซล Firebase เขียน Security Rules ไม่ได้ เอกสาร Firebase ระบุไว้ตรงๆ ให้แบ่งงานแบบนี้:

- **Gemini ในคอนโซล**: นำทางตั้งค่าในหน้าเว็บ (Firestore, Auth, แอป, งบ)
- **Antigravity**: เขียน rules, เขียน test, รันกับ Emulator, deploy

Antigravity ใช้ Firebase ได้ผ่าน agent skills และ MCP server ติดตั้งด้วยคำสั่งนี้ในโปรเจกต์:

```
npx skills add firebase/agent-skills --agent=antigravity
```

จากนั้นสั่ง Antigravity: `Generate Firestore security rules for this project, then run the unit tests.` ให้ส่ง `plan_v1.7.md` ให้อ่านก่อน

## ผลค้นหาที่เปลี่ยนแผน

- **เลือก Standard edition ตอนสร้าง Firestore** รองรับ offline และ realtime ตรงกับแผน โควตาฟรีรายวัน: อ่าน 50,000, เขียน 20,000, ลบ 20,000
- **Standard ต้องสร้าง composite index เอง** รัน query ครั้งแรกจะได้ลิงก์ error ให้กดสร้าง
- **Spark ใช้ Storage และ Functions ไม่ได้** rules ใน v1.7 ห้าม client สร้างร้านเอง (ต้องผ่าน `createShop`) บน Spark แอปจึงสร้างร้านไม่ได้ ทางออก: พัฒนากับ Emulator ก่อน แล้วอัปเกรด Blaze ตอนพร้อม deploy Functions
- **Rules ตอนนี้: ปล่อยค่าเริ่มต้น (ล็อกทุกอย่าง)** อย่าวาง rules จาก v1.7 ในคอนโซล จนกว่า Antigravity ทดสอบผ่าน

## Prompt ส่งให้ Gemini ในคอนโซล

วางทั้งก้อนในช่อง "Ask Gemini":

```
I am a beginner with Firebase. My project is "MyPOS" (Spark plan). I am building an offline-first point-of-sale app for art-fair booths. It is a Flutter iOS app for iPad, distributed through the App Store. Users sign in with Google. Data lives in Cloud Firestore (offline cache enabled in the app). Later I need Cloud Storage (product images) and Cloud Functions.

Guide me step by step through the Firebase console. For each step give the exact menu path and the exact options to pick. After each step, tell me how to verify it worked. Do not skip steps. Do not assume I know the terms; explain each in one sentence.

Do these tasks in this order:

1. Cloud Firestore database
   - Build > Firestore Database > Create database.
   - Edition: Standard. Mode: Native (Core operations). Not Enterprise, not MongoDB-compatible.
   - Database ID: (default).
   - Location: asia-southeast1 (Singapore). Warn me that the location cannot be changed later.
   - Security rules: start in Production mode (all access denied). I will deploy tested rules later from my code editor, not from the console.
   - Tell me how to check the Usage tab and which free daily quotas apply on Spark.

2. Authentication
   - Build > Authentication > Get started.
   - Enable the Google sign-in provider. Set the project public-facing name and the support email.
   - Check the Authorized domains list.
   - Do NOT enable phone/SMS sign-in (it costs money).
   - Explain what "Sign in with Apple" needs (Apple Developer account, Services ID, key) and tell me to do it later, after I have the Apple account.

3. Register the apps
   - Explain the difference between registering an app in the console and running "flutterfire configure".
   - Tell me what Bundle ID rules apply (reverse-domain format, hard to change later) and what I must decide before registering the iOS app.
   - Tell me what to do with GoogleService-Info.plist and the URL scheme (REVERSED_CLIENT_ID) that Google Sign-In needs on iOS.

4. Project settings
   - Project settings > General: check the Project ID, set the default GCP resource location to asia-southeast1 if the console offers it, and add a support email.
   - Project settings > Users and permissions: explain who has access now and how to add a collaborator safely.

5. Things I must NOT do yet
   - Do not create Cloud Storage or Cloud Functions on Spark. Explain exactly what the Blaze upgrade changes and what stays free.
   - Do not paste any Security Rules in the console yet.

6. Cost safety before any upgrade to Blaze
   - Explain how to set a budget alert in Google Cloud Billing (low amount, e.g. 100-200 THB equivalent).
   - Explain clearly that a budget alert only sends notifications and does NOT stop spending.
   - Explain how to set quota caps in Google Cloud Console where possible.
   - Tell me which Firebase features can create unexpected cost (for example SMS auth, large Storage downloads, reading entire collections repeatedly).

At the end, give me a checklist of the values I should write down: Project ID, Firestore location, the Google sign-in provider status, and the Bundle ID I chose. Then list what is still left to do outside the console (flutterfire configure, rules, indexes, Functions, Storage).

If you cannot make a change yourself, say so and give me the clicks to do it. Tell me if anything in these instructions does not match what you see in my console.
```

## ทำนอกคอนโซล

- ตั้ง Bundle ID ก่อนลงทะเบียนแอป iOS เปลี่ยนทีหลังยาก
- รัน `firebase login` และ `flutterfire configure` ในโฟลเดอร์ Flutter
- ติดตั้ง agent skills ให้ Antigravity แล้วให้สร้าง rules, rules test, `firestore.indexes.json`
- Apple Developer และ Sign in with Apple ทำตอนใกล้ส่ง App Store

ผมไม่รู้ว่า Gemini ในคอนโซลลงมือกดเปลี่ยนค่าให้ได้หรือแค่แนะนำ ผมจึงใส่ประโยคให้มันบอกเองในท้าย prompt

อยากอัปเกรด Blaze ตอนนี้ หรือรอจนพร้อม deploy Functions ครับ