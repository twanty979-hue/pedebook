import type { Metadata } from "next";
import { SEO_CONFIG } from "./src/lib/seo";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(SEO_CONFIG.siteUrl),
  icons: {
    icon: [
      { url: '/icon.png', type: 'image/png' },
      { url: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/icon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-icon.png', sizes: '180x180', type: 'image/png' }],
    shortcut: ['/icon.png'],
  },
  appleWebApp: {
    capable: true,
    title: 'Pedebook',
    statusBarStyle: 'default',
  },
  title: {
    default: "แปลง PDF เป็น Flipbook ออนไลน์ฟรี | Pedebook",
    template: "%s | Pedebook",
  },
  description: "สร้างแคตตาล็อก E-Book และโบรชัวร์ออนไลน์ฟรีจาก PDF เปิดอ่านแบบพลิกหน้า แชร์ลิงก์และ QR Code ได้ทันที รองรับมือถือและคอมพิวเตอร์",
  keywords: [
    "แปลง PDF เป็น Flipbook ออนไลน์",
    "สร้างแคตตาล็อกออนไลน์",
    "Flipbook ออนไลน์",
    "E-Catalog ออนไลน์",
    "แปลง PDF เป็น E-Book",
    "สร้างโบรชัวร์ออนไลน์",
    "แคตตาล็อกสินค้าออนไลน์",
    "สมุดพลิกออนไลน์",
    "Flipbook ภาษาไทย",
    "ทำ QR Code แคตตาล็อก",
    "แชร์แคตตาล็อกผ่าน LINE",
    "โปรแกรมทำแคตตาล็อกออนไลน์",
    "สร้างเมนูอาหารออนไลน์",
    "ทำพอร์ตโฟลิโอออนไลน์",
    "แปลง PDF เป็นลิงก์",
    "สร้าง e-Book ฟรี",
    "สมุดออนไลน์เปิดอ่านได้",
    "โปรแกรมทำ e-book พลิกหน้าได้",
    "สร้างแมกกาซีนออนไลน์",
    "เมนูอาหาร QR Code",
    "ทำโบชัวร์ออนไลน์",
    "PDF to Flipbook free",
    "Online catalog creator",
    "Interactive flipbook builder",
    "ทำหนังสือออนไลน์",
    "สร้างวารสารออนไลน์",
    "รายงานประจำปีออนไลน์",
    "Annual Report ออนไลน์",
    "โปรแกรมสร้าง Flipbook ออนไลน์",
    "สร้าง Flipbook จาก PDF",
    "ทำ PDF ให้เปิดแบบพลิกหน้า",
    "สร้างแคตตาล็อกดิจิทัล",
    "แคตตาล็อกออนไลน์สำหรับร้านค้า",
    "แคตตาล็อกสินค้าเปิดบนมือถือ",
    "สร้างเมนูดิจิทัล",
    "เมนูร้านอาหารออนไลน์",
    "ทำ QR Code เมนูอาหาร",
    "สร้างโบรชัวร์ดิจิทัล",
    "สร้าง Portfolio ออนไลน์",
    "สร้างรายงานประจำปีออนไลน์",
    "ทำหนังสือออนไลน์จาก PDF",
    "แชร์เอกสารด้วยลิงก์",
    "เปิด PDF ผ่านลิงก์",
    "Flipbook สำหรับธุรกิจ",
    "E-Catalog สำหรับ SME",
    "Digital brochure ภาษาไทย",
    "Online product catalog",
    "PDF to digital catalog",
    "แปลง PDF เป็น Flipbook ฟรี",
    "สร้างแคตตาล็อกออนไลน์ฟรี",
    "โปรแกรมทำ E-Catalog ฟรี",
    "สร้าง E-Book ฟรี",
    "สร้างเมนู QR Code ฟรี",
    "Flipbook ออนไลน์ฟรี",
    "Free online catalog creator"
  ],
  applicationName: SEO_CONFIG.siteName,
  authors: [{ name: "Pedebook Team" }],
  creator: "Pedebook Team",
  publisher: "Pedebook Team",
  verification: SEO_CONFIG.googleSiteVerification
    ? { google: SEO_CONFIG.googleSiteVerification }
    : undefined,
  other: {
    'google-adsense-account': 'ca-pub-3349574408761231',
  },
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
      <head>
        <script
          async
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-3349574408761231"
          crossOrigin="anonymous"
        />
      </head>
      <body className="min-h-full flex flex-col font-sans">{children}</body>
    </html>
  );
}
