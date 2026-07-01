'use client';

import { Document, Page, pdfjs } from 'react-pdf';

// ตั้งค่าพาร์ทของ Worker เพื่อให้ PDF.js ทำงานในพื้นหลัง
pdfjs.GlobalWorkerOptions.workerSrc = '/pdf.worker.min.mjs';

interface BookCoverProps {
  slug: string;
  fileName: string;
  width?: number;
}

export default function BookCover({ slug, fileName, width = 157 }: BookCoverProps) {
  return (
    <Document
      file={`/api/pdf-proxy?slug=${slug}`}
      loading={
        <div className="flex flex-col items-center justify-center h-full w-full bg-[#243129] text-[#e8dcc7] p-2 text-center select-none">
          <span className="text-[9px] font-bold tracking-widest animate-pulse">โหลดปก...</span>
        </div>
      }
      error={
        <div className="flex flex-col items-center justify-between h-full w-full bg-[#243129] text-[#e8dcc7] p-3 text-center select-none">
          <svg className="w-5 h-5 text-[#e8dcc7] mx-auto" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
          </svg>
          <span className="text-[7px] font-bold leading-normal uppercase tracking-wider line-clamp-3">
            {fileName.replace(/-/g, ' ').replace(/\.pdf$/i, '')}
          </span>
          <span className="text-[6px] tracking-widest text-[#9a7257] font-semibold">
            PEDEBOOK
          </span>
        </div>
      }
    >
      <Page
        pageNumber={1}
        width={width}
        renderTextLayer={false}
        renderAnnotationLayer={false}
      />
    </Document>
  );
}
