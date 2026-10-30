'use client';

import { useMemo, useState, useEffect, useRef } from 'react';
import { Document, Page, pdfjs } from 'react-pdf';

// ตั้งค่าพาร์ทของ Worker เพื่อให้ PDF.js ทำงานในพื้นหลัง
if (typeof window !== 'undefined' && !pdfjs.GlobalWorkerOptions.workerSrc) {
  pdfjs.GlobalWorkerOptions.workerSrc = '/pdf.worker.min.mjs';
}

interface BookCoverProps {
  id?: string;
  slug: string;
  fileName: string;
  title?: string;
  coverImage?: string;
  updatedAt?: string;
  width?: number;
}

export default function BookCover({
  id,
  slug,
  fileName,
  title,
  coverImage,
  updatedAt,
  width = 200,
}: BookCoverProps) {
  const [rendered, setRendered] = useState(false);
  const [localCover, setLocalCover] = useState<string | null>(coverImage || null);
  const containerRef = useRef<HTMLDivElement>(null);

  const displayTitle = (title || fileName || 'PEDEBOOK')
    .replace(/\.pdf$/i, '')
    .replace(/[-_]/g, ' ')
    .trim();

  // ตรวจสอบรูปภาพหน้าปกจาก localStorage (แคชระดับเบราว์เซอร์เร็ว 0ms)
  useEffect(() => {
    if (coverImage) {
      setLocalCover(coverImage);
      return;
    }
    try {
      const stored = localStorage.getItem(`pedebook_cover_${slug}`);
      if (stored) {
        setLocalCover(stored);
      }
    } catch (_) {}
  }, [coverImage, slug]);

  // แคชเวอร์ชันของไฟล์ PDF เพื่อให้ Cloudflare Edge แคชได้ถาวร
  const cacheVersion = updatedAt ? new Date(updatedAt).getTime() : '1';
  const fileConfig = useMemo(
    () => ({
      url: `/api/pdf-proxy?slug=${encodeURIComponent(slug)}&v=${cacheVersion}`,
      disableAutoFetch: true,
      disableStream: true,
    }),
    [slug, cacheVersion]
  );

  // เมื่อ PDF.js วาดหน้าแรกสำเร็จ ให้ดึงเป็นรูปภาพบันทึกเข้าแคช
  const handleRenderSuccess = () => {
    setRendered(true);
    if (!localCover && containerRef.current) {
      try {
        const canvas = containerRef.current.querySelector('canvas');
        if (canvas) {
          const dataUrl = canvas.toDataURL('image/webp', 0.82);
          setLocalCover(dataUrl);
          try {
            localStorage.setItem(`pedebook_cover_${slug}`, dataUrl);
          } catch (_) {}

          // อัปเดตไปยังฐานข้อมูล Supabase เบื้องหลังแบบเงียบๆ
          if (id) {
            fetch(`/api/v1/catalogs/${id}`, {
              method: 'PATCH',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ coverImage: dataUrl }),
            }).catch(() => {});
          }
        }
      } catch (_) {}
    }
  };

  return (
    <div
      ref={containerRef}
      className="relative w-full h-full overflow-hidden select-none flex items-center justify-center bg-[#1e2a22]"
    >
      {/* ── 1. กรณีมีรูปปกที่แคชไว้แล้ว (แสดงผลทันที 0ms) ── */}
      {localCover ? (
        <img
          src={localCover}
          alt={displayTitle}
          className="w-full h-full object-cover rounded-r-lg transition-transform duration-300 group-hover:scale-105"
          loading="lazy"
        />
      ) : (
        /* ── 2. หน้าปก 3D Luxury Hardcover สำเร็จรูป (แสดงผลทันที 0ms ระหว่างรอ PDF) ── */
        <div className="absolute inset-0 w-full h-full bg-gradient-to-br from-[#27382e] via-[#1e2b23] to-[#121c16] text-[#e8dcc7] p-3 flex flex-col justify-between shadow-inner">
          {/* แถบสันปกหนังสือสีทองหรูหราทางซ้าย */}
          <div className="absolute left-0 top-0 bottom-0 w-2.5 bg-gradient-to-r from-[#7a5836] via-[#c5a059] to-transparent opacity-90 shadow-sm" />

          {/* กรอบทองฟอยล์ด้านใน */}
          <div className="border border-[#c5a059]/40 rounded-sm p-3.5 flex flex-col justify-between items-center text-center h-full relative z-10 backdrop-blur-[1px]">
            {/* โลโก้ Pedebook สีทองด้านบน */}
            <div className="flex flex-col items-center gap-1 mt-1">
              <svg className="w-6 h-6 text-[#d4af37]" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              <span className="text-[7px] tracking-[0.25em] font-bold text-[#c5a059] uppercase">PEDEBOOK</span>
            </div>

            {/* ชื่อเรื่องหนังสือตัวพิมพ์สีทองอร่าม */}
            <div className="my-auto px-1 max-w-full">
              <p className="font-serif font-bold text-xs sm:text-sm leading-snug tracking-wide text-[#f5eedb] line-clamp-4 drop-shadow-[0_1px_3px_rgba(0,0,0,0.8)]">
                {displayTitle}
              </p>
            </div>

            {/* ตราสัญลักษณ์หนังสือดิจิทัลด้านล่าง */}
            <div className="flex flex-col items-center gap-0.5 mb-1">
              <div className="w-8 h-[1px] bg-[#c5a059]/50 mb-1" />
              <span className="text-[6.5px] tracking-[0.2em] font-semibold text-[#c5a059]/90 uppercase">
                DIGITAL EDITION
              </span>
            </div>
          </div>

          {/* เงาและไฮไลต์จำลองความโค้งมนของปกหนังสือจริง */}
          <div className="absolute inset-0 bg-gradient-to-tr from-black/20 via-transparent to-white/10 pointer-events-none" />
        </div>
      )}

      {/* ── 3. เรนเดอร์ PDF หน้าแรกในพื้นหลังแบบไร้รอยต่อ ── */}
      {!localCover && (
        <div
          className={`absolute inset-0 flex items-center justify-center transition-opacity duration-700 ${
            rendered ? 'opacity-100' : 'opacity-0 pointer-events-none'
          }`}
        >
          <Document file={fileConfig} loading={null} error={null}>
            <Page
              pageNumber={1}
              width={width}
              renderTextLayer={false}
              renderAnnotationLayer={false}
              onRenderSuccess={handleRenderSuccess}
            />
          </Document>
        </div>
      )}
    </div>
  );
}
