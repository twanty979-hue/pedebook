# Pedebook SEO Roadmap (Phase 2 & Content Strategy)

เอกสารนี้ระบุแผนงานสำหรับ Phase 2 ในการทำ Catalog SEO และการขยายหน้าเนื้อหา (Content Roadmap) ของแบรนด์ Pedebook เพื่อดึงดูดผู้ใช้งานที่ต้องการสร้างแคตตาล็อกออนไลน์ โบรชัวร์ออนไลน์ และ E-Book

---

## 1. Catalog SEO (Phase 2 Technical Plan)

ปัจจุบันหน้า `/catalog/[slug]` เป็น Client-rendered component 100% จึงยังไม่เอื้ออำนวยต่อการทำ Technical SEO สำหรับรายแคตตาล็อก ใน Phase 2 จะปรับสถาปัตยกรรมและเพิ่มคุณสมบัติในฐานข้อมูล Firestore ดังนี้:

### 1.1 การปรับเปลี่ยนโครงสร้างฐานข้อมูล (Firestore Schema updates)
เพิ่มฟิลด์เหล่านี้ในแอตทริบิวต์ของเอกสารแคตตาล็อกในฐานข้อมูล:
- `displayTitle`: (string) ชื่อของหนังสือที่จะนำไปขึ้นหน้าเว็บจริงแทนชื่อไฟล์ PDFดิบ
- `seoDescription`: (string) คำอธิบายย่อ (150-160 ตัวอักษร) สำหรับ metadata description รายแคตตาล็อก
- `coverImage`: (string) ลิงก์รูปภาพปกสำหรับใช้ทำ Open Graph image รายแคตตาล็อก
- `isPublic`: (boolean) ระบุว่าแคตตาล็อกนี้เปิดเป็นสาธารณะหรือไม่ (หากเป็น `false` จะห้ามเปิดดู)
- `allowIndexing`: (boolean) บันทึกการยินยอมของผู้สร้าง (Indexing Consent) ในการอนุญาตให้ Google นำหน้านี้ไปดัชนี (Index) หากตั้งค่าเป็น `true` จะดึงขึ้น Sitemap และตั้งค่า `robots: { index: true }` หากเป็น `false` จะกำหนด `noindex`
- `updatedAt`: (timestamp) วันเวลาที่มีการบันทึกหรืออัปเดตแคตตาล็อกนี้จริง เพื่อใช้คำนวณ `lastModified` ใน Sitemap

### 1.2 การปรับปรุงความปลอดภัยและความสวยงามของ Slug
- **ปัญหาปัจจุบัน**: Slug มี Firebase User UID อยู่ด้วย ซึ่งอาจไม่ปลอดภัย (UID รั่วไหล) และทำให้อ่านยาก
- **แนวทางแก้ไข**: เปลี่ยนระบบสร้าง slug ใน Firestore ให้สุ่มรหัสความยาวขนาดสั้น เช่น `nanoid` (เช่น `/catalog/a7K2d9s`) หรือใช้ชื่อไฟล์มาทำ slug โดยไม่มี UID เช่น `/catalog/living-magazine-2026` โดยใช้คีย์เวิร์ดที่เป็นธรรมชาติมากขึ้น

### 1.3 การย้ายไปใช้ Server-side Data Fetching
- **การเปลี่ยนแปลง**: แก้ไข `app/catalog/[slug]/page.tsx` จาก Client Component ให้เป็น Server Component (หรือนำ dynamic load ออกในส่วน metadata)
- **การทำ generateMetadata**: ใช้ฟังก์ชัน `generateMetadata` ใน Next.js 16 เพื่ออ่านค่า `slug` จาก `params` แบบ async:
  ```typescript
  import { notFound } from 'next/navigation';
  import type { Metadata } from 'next';
  
  interface Props {
    params: Promise<{ slug: string }>;
  }

  export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const { slug } = await params;
    const catalog = await getCatalogBySlug(slug); // ดึงข้อมูลฝั่ง server (เช่น admin SDK หรือ direct Fetch)
    
    if (!catalog || !catalog.allowIndexing) {
      return {
        robots: {
          index: false,
          follow: true,
        }
      };
    }

    return {
      title: catalog.displayTitle,
      description: catalog.seoDescription,
      alternates: {
        canonical: absoluteUrl(`/catalog/${slug}`),
      },
      openGraph: {
        title: catalog.displayTitle,
        description: catalog.seoDescription,
        images: [{ url: catalog.coverImage }],
      }
    };
  }
  ```
- **การจัดการกรณีไม่พบข้อมูล**: นำเข้า `notFound()` จาก `next/navigation` และเรียกใช้เมื่อดึงข้อมูลแล้วไม่พบเอกสารตรงกับ slug เพื่อให้เซิร์ฟเวอร์ส่งรหัส HTTP Status 404 ที่ถูกต้องแก่ Google Search Console
- **JSON-LD Schema ราย Catalog**: เชื่อมโยงข้อมูลและสร้าง Schema ประเภท `CreativeWork` หรือ `DigitalDocument` รายแคตตาล็อก เพื่อช่วยระบุรายละเอียดเนื้อหาหนังสือดิจิทัลให้ดีขึ้น

---

## 2. Content Roadmap (แผนงานพัฒนาหน้าเนื้อหา)

เพื่อเพิ่มช่องทางเข้าชมแบบออร์แกนิก (Organic Traffic) แนะนำการจัดทำหน้าเนื้อหาเฉพาะทางที่เน้นตอบสนองความต้องการค้นหาข้อมูลของกลุ่มลูกค้าเป้าหมาย (SME, ฝ่ายขาย, ร้านค้า, เมนูอาหาร) โดยยังไม่เปิดใช้งานใน Phase 1 เพื่อหลีกเลี่ยง Thin Content (หน้าเว็บที่ไร้เนื้อหาที่มีประโยชน์จริง)

### 2.1 หน้าเนื้อหาหลักที่ต้องการสร้าง (Core Landing Pages)
1. `/pdf-to-flipbook` - หน้าอธิบายฟังก์ชันแปลงไฟล์ PDF เป็น Flipbook คีย์เวิร์ดหลัก: "แปลง PDF เป็น Flipbook ออนไลน์", "โปรแกรมทำแคตตาล็อกออนไลน์"
2. `/catalog-online` - หน้าแนะนำวิธีสร้างแคตตาล็อกสินค้าออนไลน์และเมนูอาหาร คีย์เวิร์ดหลัก: "สร้างแคตตาล็อกออนไลน์", "แคตตาล็อกสินค้าออนไลน์"
3. `/ebook-online` - หน้าแนะนำสำหรับผู้สร้าง E-Book นิตยสาร และเอกสารรายงานประจำปี คีย์เวิร์ดหลัก: "แปลง PDF เป็น E-Book", "สมุดพลิกออนไลน์"
4. `/brochure-online` - หน้าแนะนำสำหรับการจัดทำแผ่นพับหรือโบรชัวร์ประชาสัมพันธ์ของสถาบัน/องค์กร คีย์เวิร์ดหลัก: "สร้างโบรชัวร์ออนไลน์", "ทำ QR Code แคตตาล็อก"
5. `/examples` - หน้ารวบรวมตัวอย่าง Flipbook ที่จัดทำขึ้นจริงในรูปแบบต่างๆ เพื่อเพิ่มความน่าเชื่อถือ
6. `/pricing` - หน้าแจกแจงค่าบริการ สัญญา และแพ็กเกจการใช้งานจริง (เปิดใช้งานเมื่อมีการยืนยันราคาจากเจ้าของเว็บแล้วเท่านั้น)

### 2.2 กฎการทำ Content สำหรับเจ้าของเว็บ
- **หลีกเลี่ยง Thin Content**: ห้ามสร้างหน้าเว็บย่อยๆ ที่มีคำอธิบายเพียงเล็กน้อยหรือไม่กี่คำเพื่อหวังผลทางอันดับใน Google (Keyword Stuffing)
- **เน้นคุณภาพเนื้อหา**: ทุกหน้าเนื้อหาต้องมีคำอธิบายการใช้งาน ประโยชน์ที่แท้จริง ขั้นตอนชัดเจน รูปภาพตัวอย่าง หรือวิดีโอสาธิต เพื่อตอบคำถามผู้ใช้งานให้ดีที่สุด
