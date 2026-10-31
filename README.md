# 📖 PEDEBOOK (`catalog-book-app`)
> **3D Interactive Flipbook & Digital Catalog SaaS Platform**  
> เว็บไซต์และแอปพลิเคชันสร้างสมุดแค็ตตาล็อกออนไลน์และ E-Book 3D พร้อมเสียงเปิดหน้าเสมือนจริง, ระบบสถิติรายหน้าเชิงลึก (Page-by-Page Analytics) และแอปพลิเคชันมือถือ Flutter Companion

---

## 🌟 จุดเด่นและฟีเจอร์หลัก (Key Features)

- **📚 3D Realistic Page-Turning:** แปลงไฟล์ PDF ขนาดใหญ่ให้กลายเป็นหนังสือ 3D เปิดพลิกหน้าได้ พร้อมเสียงเปิดสมุดเสมือนจริง รองรับทั้ง Touch Screen บนสมาร์ตโฟน/แท็บเล็ต และเมาส์บนคอมพิวเตอร์
- **📱 Monorepo Architecture (Web + Mobile App):**
  - **Web Frontend & API:** Next.js 16 (App Router + Turbopack), React 19, Tailwind CSS v4
  - **Mobile Companion App (`pedebook_app`):** Flutter 3.x รองรับทั้ง iOS, Android, macOS, Windows และ Web
- **⚡ High-Performance Storage & Streaming:** สตรีมและแคชไฟล์ PDF ผ่าน Cloudflare R2 CDN โหลดรวดเร็ว 0ms ไม่เปลือง Bandwidth
- **📊 Deep Page-by-Page Stay Duration Analytics:**
  - ติดตามระยะเวลาที่ผู้อ่านเปิดค้างไว้ในแต่ละหน้าแบบเรียลไทม์
  - แดชบอร์ด Heatmap & Bar Chart สรุปว่าหน้าไหนคนสนใจมากที่สุด (Hot Pages 🔥)
  - จำแนกผู้อ่านใหม่ (New Readers) และผู้อ่านประจำ (Returning Visitors)
- **👥 Multi-Tier Plans & Monetization:**
  - **Free:** พื้นที่ 100 MB พร้อมระบบสปอนเซอร์โฆษณา (Unblockable Ad 5s)
  - **Pro & Ultra:** ลายน้ำแบรนด์ตัวเอง, ไม่มีโฆษณา, สถิติเชิงลึก
  - **Business:** ระบบสมาชิกและเชิญทีมงาน (Team Collaboration) สูงสุด 10 คน
- **🛡️ Modern Backend:** Supabase (PostgreSQL) พร้อม Row Level Security (RLS) และ RPC Stored Procedures สำหรับการบันทึกสถิติแบบอะตอมิก

---

## 📁 โครงสร้างโปรเจกต์ (Monorepo Directory Structure)

```text
catalog-book-app/
├── app/                        # Next.js 16 App Router (Web & API)
│   ├── admin/                  # แดชบอร์ดผู้ดูแลระบบ (Admin Control Center)
│   ├── api/                    # Backend Handlers & Universal REST API
│   │   ├── delete-file/        # ลบไฟล์จาก Cloudflare R2
│   │   ├── pdf-proxy/          # พร็อกซีสตรีมมิงและแคชไฟล์ PDF
│   │   ├── upload/             # อัปโหลดไฟล์และสร้าง Presigned URL
│   │   └── v1/                 # Universal RESTful API (Web & Mobile App)
│   │       ├── analytics/      # API บันทึก Ping และสรุปผลสถิติรายหน้า
│   │       ├── catalogs/       # จัดการข้อมูลแค็ตตาล็อกและสิทธิ์ทีม
│   │       ├── teams/          # ระบบเชิญและจัดการทีม
│   │       └── user/           # ข้อมูลโปรไฟล์และสถานะแพ็กเกจ
│   ├── catalog/[slug]/         # หน้าเครื่องเล่น Flipbook 3D พร้อมตัวจับเวลา
│   ├── components/             # Reusable UI Components (FlipBook, Viewer, AdOverlay)
│   ├── dashboard/              # แดชบอร์ดเจ้าของสมุด จัดการเล่ม และ Analytics Studio
│   ├── en/                     # หน้า Landing Page ภาษาอังกฤษ (SEO Optimized)
│   └── src/lib/                # ไลบรารีส่วนกลาง (Supabase, SEO, Plans, Tracking)
├── pedebook_app/               # Flutter Cross-Platform Companion Mobile App
│   ├── lib/
│   │   ├── models/             # Data Models (Book, User, Analytics)
│   │   ├── screens/            # หน้าจอแอป (Home, BookDetail, QRStudio, Analytics)
│   │   ├── services/           # Supabase & Backend API Services
│   │   └── widgets/            # Flutter UI Widgets
│   └── pubspec.yaml            # การตั้งค่าและ Dependencies ของ Flutter
├── supabase/                   # สกีมาฐานข้อมูลและ SQL Migrations
│   ├── schema.sql              # สกีมาหลัก (Tables, Enums, RLS, Triggers, RPC)
│   └── seed.sql                # ข้อมูลตั้งต้นสำหรับทดสอบระบบ
├── docs/                       # เอกสารสถาปัตยกรรมและ SEO Roadmap
├── .env.example                # ตัวอย่างการตั้งค่า Environment Variables
├── eslint.config.mjs           # การตั้งค่า ESLint 9 & TypeScript Rules
└── package.json                # Web Dependencies & NPM Scripts
```

---

## 🚀 เริ่มต้นใช้งาน (Getting Started)

### ความต้องการขั้นต่ำ (Prerequisites)
- **Node.js:** v18.17+ หรือ v20+ (แนะนำ v20 ขึ้นไป)
- **npm:** v9+ หรือ v10+
- **Flutter SDK:** v3.12+ (กรณีต้องการรันแอปพลิเคชันมือถือ)

---

### 1. การติดตั้งและรัน Web Application (Next.js)

```bash
# 1. ติดตั้ง Dependencies
npm install

# 2. คัดลอกและตั้งค่า Environment Variables
cp .env.example .env.local

# 3. เริ่มต้นรันเซิร์ฟเวอร์สำหรับการพัฒนา (Turbopack)
npm run dev
```

เปิดเบราว์เซอร์ไปที่ [http://localhost:3000](http://localhost:3000)

#### คำสั่งอื่นๆ สำหรับ Web:
```bash
# ตรวจสอบ TypeScript Types
npx tsc --noEmit

# ตรวจสอบ Code Quality ด้วย ESLint
npm run lint

# สร้าง Production Build
npm run build

# รัน Production Server
npm start
```

---

### 2. การติดตั้งและรัน Mobile Companion App (Flutter)

```bash
# เข้าสู่โฟลเดอร์แอปพลิเคชัน Flutter
cd pedebook_app

# ติดตั้ง Dependencies
flutter pub get

# ตรวจสอบความถูกต้องของโค้ด Dart
flutter analyze

# รันแอปพลิเคชันบน Simulator หรือ Device ที่เชื่อมต่อ
flutter run
```

---

## 🔑 การตั้งค่า Environment Variables (`.env.local`)

| ตัวแปร | รายละเอียด | ตัวอย่าง |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | URL ของโปรเจกต์ Supabase | `https://xxxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public Anon Key ของ Supabase | `eyJhbGciOi...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Secret Service Role Key (Backend Only) | `eyJhbGciOi...` |
| `R2_ENDPOINT` | Endpoint URL ของ Cloudflare R2 | `https://xxxx.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID` | Access Key ID ของ R2 | `xxxxxxxxxxxx` |
| `R2_SECRET_ACCESS_KEY` | Secret Access Key ของ R2 | `xxxxxxxxxxxx` |
| `R2_BUCKET_NAME` | ชื่อ Bucket สำหรับจัดเก็บ PDF | `catalog-files` |
| `R2_PUBLIC_DOMAIN` | CDN Domain สำหรับส่งไฟล์ความเร็วสูง | `https://cdn.pedebook.com` |
| `NEXT_PUBLIC_SITE_URL` | โดเมนหลักของเว็บไซต์ (Production) | `https://pedebook.com` |
| `NEXT_PUBLIC_ADMIN_EMAILS` | อีเมลที่ได้รับสิทธิ์เข้าใช้งานหน้า Admin | `admin@pedebook.com` |

---

## 🗄️ การติดตั้งฐานข้อมูล Supabase (Database Setup)

1. สร้างโปรเจกต์บน [Supabase Dashboard](https://supabase.com)
2. ไปที่เมนู **SQL Editor** -> กดปุ่ม **+ New Query**
3. คัดลอกโค้ดทั้งหมดจาก [`supabase/schema.sql`](./supabase/schema.sql) มาวางและกด **Run**
4. ตาราง, ฟังก์ชัน `record_page_stay_time`, Triggers และ Row Level Security (RLS) จะถูกสร้างขึ้นพร้อมใช้งานทันที
5. รายละเอียดสถาปัตยกรรมเพิ่มเติม สามารถอ่านได้ที่ [`MIGRATION_TO_SUPABASE.md`](./MIGRATION_TO_SUPABASE.md)

---

## 📄 ใบอนุญาต (License)
ลิขสิทธิ์ของทีมพัฒนา Pedebook สงวนลิขสิทธิ์ทุกประการ
