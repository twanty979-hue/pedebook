'use client';

import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import { useParams } from 'next/navigation';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '../../src/lib/firebase';

const EbookViewer = dynamic(() => import('../../components/EbookViewer'), {
  ssr: false,
  loading: () => (
    <div style={{ color: '#aaa', textAlign: 'center', padding: 80, letterSpacing: 4, textTransform: 'uppercase', fontSize: 13, background: '#1c1c1e', minHeight: '100vh' }}>
      กำลังเตรียมหน้ากระดาษครับนาย...
    </div>
  ),
});

export default function CatalogSlugPage() {
  const params = useParams();
  const slug = params?.slug as string;
  const [catalog, setCatalog] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!slug) return;
    
    // ใช้ onSnapshot เพื่อดึงและอัปเดตการตั้งค่าสีพื้นหลังได้แบบเรียลไทม์โดยไม่ต้องรีเฟรชหน้า
    const q = query(collection(db, 'catalogs'), where('slug', '==', slug));
    const unsubscribe = onSnapshot(
      q,
      (snap) => {
        if (!snap.empty) {
          setCatalog(snap.docs[0].data());
        }
        setLoading(false);
      },
      (err) => {
        console.error('Error listening to catalog updates:', err);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, [slug]);

  if (loading) {
    return (
      <div style={{ color: '#aaa', textAlign: 'center', padding: 80, letterSpacing: 4, textTransform: 'uppercase', fontSize: 13, background: '#1c1c1e', minHeight: '100vh' }}>
        กำลังเตรียมหน้ากระดาษครับนาย...
      </div>
    );
  }

  if (!catalog) {
    return <div className="text-center py-20 text-white font-sans bg-[#1c1c1e] min-h-screen flex items-center justify-center">ไม่พบลิงก์แค็ตตาล็อกนี้ครับ</div>;
  }

  // ส่ง slug ให้ server โหลด R2 PDF ผ่าน proxy เพื่อหลีกเลี่ยง CORS
  const pdfUrl = `/api/pdf-proxy?slug=${encodeURIComponent(slug)}&t=${Date.now()}`;

  return (
    <EbookViewer
      pdfUrl={pdfUrl}
      bgType={catalog.bgType || 'gradient'}
      bgValue={catalog.bgValue || 'auto'}
    />
  );
}
