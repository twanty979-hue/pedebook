import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Pedebook — แปลง PDF เป็น Flipbook ออนไลน์ฟรี',
    short_name: 'Pedebook',
    description: 'สร้าง Flipbook และแคตตาล็อกออนไลน์จาก PDF แชร์ลิงก์และ QR Code ได้ทันที',
    start_url: '/',
    scope: '/',
    display: 'standalone',
    background_color: '#f6f4ee',
    theme_color: '#243129',
    lang: 'th-TH',
    icons: [
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'maskable' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
  };
}
