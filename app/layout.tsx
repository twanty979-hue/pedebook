import type { Metadata } from "next";
import { SEO_CONFIG } from "./src/lib/seo";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(SEO_CONFIG.siteUrl),
  title: {
    default: "แปลง PDF เป็น Flipbook ออนไลน์ | Pedebook",
    template: "%s | Pedebook",
  },
  description: "สร้างแคตตาล็อก E-Book และโบรชัวร์ออนไลน์จาก PDF เปิดอ่านแบบพลิกหน้า แชร์ลิงก์และ QR Code ได้ทันที รองรับมือถือและคอมพิวเตอร์",
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
    "โปรแกรมทำแคตตาล็อกออนไลน์"
  ],
  applicationName: SEO_CONFIG.siteName,
  authors: [{ name: "Pedebook Team" }],
  creator: "Pedebook Team",
  publisher: "Pedebook Team",
  verification: SEO_CONFIG.googleSiteVerification
    ? { google: SEO_CONFIG.googleSiteVerification }
    : undefined,
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

