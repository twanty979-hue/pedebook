import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pedebook | ระบบแปลง PDF เป็นแค็ตตาล็อกและสมุดเปิดอ่าน 3D ออนไลน์",
  description: "Pedebook (พีดีบุ๊ก) แพลตฟอร์มแปลงไฟล์เอกสาร PDF เป็น E-Book, Catalog และ Brochure เปิดอ่านแบบพลิกหน้าได้ 3D อัจฉริยะ รองรับระบบ iOS, Android, iPad และ PC สมบูรณ์แบบ สร้างและแชร์ง่ายผ่าน QR Code",
  keywords: [
    "แปลง PDF เป็น flipbook",
    "สมุดเปิดอ่านดิจิทัล",
    "e-book 3D",
    "แปลงแค็ตตาล็อก PDF",
    "Pedebook",
    "ใบโอนสินค้าออนไลน์",
    "สร้างคิวอาร์โค้ดหนังสือ",
    "flipbook ภาษาไทย",
    "Brochure online",
    "Interactive Catalog"
  ],
  authors: [{ name: "Pedebook Team" }],
  openGraph: {
    title: "Pedebook | ระบบแปลง PDF เป็นแค็ตตาล็อกและสมุดเปิดอ่าน 3D ออนไลน์",
    description: "แพลตฟอร์มแปลง PDF เป็น E-Book 3D และแค็ตตาล็อกเปิดอ่านได้แบบสมจริง แชร์ด่วนผ่านคิวอาร์โค้ดในคลิกเดียว พร้อมรองรับทุกสมาร์ทโฟน",
    type: "website",
    url: "http://localhost:3001",
    images: [
      {
        url: "/system-screenshot.png",
        width: 1200,
        height: 630,
        alt: "Pedebook 3D Ebook Creator"
      }
    ]
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="th"
      className="h-full antialiased"
    >
      <body className="min-h-full flex flex-col font-sans">{children}</body>
    </html>
  );
}
