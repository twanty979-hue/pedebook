'use client';

import React, { useState } from 'react';
import dynamic from 'next/dynamic';
import { Book } from './FlipBookModal';

const FlipBookModal = dynamic(() => import('./FlipBookModal'), {
  ssr: false,
  loading: () => (
    <div className="fixed inset-0 z-[999] flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="flex flex-col items-center gap-3">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#e8dcc7] border-t-transparent"></div>
        <p className="text-xs font-bold text-[#e8dcc7] tracking-widest uppercase">กำลังโหลดสมุดภาพ 3D...</p>
      </div>
    </div>
  ),
});

const mockBooks: Book[] = [
  {
    id: 1,
    title: "LIVING",
    cover:
      "https://placehold.co/800x1120/243129/ffffff?text=LIVING+2026",
    pages: [
      "https://placehold.co/800x1120/f4f2ec/243129?text=LIVING+2026",
      "https://placehold.co/800x1120/e8dcc7/243129?text=Welcome+Home",
      "https://placehold.co/800x1120/efe7d8/243129?text=Warm+Spaces",
      "https://placehold.co/800x1120/f4f2ec/243129?text=Materials+and+Details",
      "https://placehold.co/800x1120/e8dcc7/243129?text=Comfort+in+Every+Room",
      "https://placehold.co/800x1120/243129/ffffff?text=Thank+You",
    ],
  },
  {
    id: 2,
    title: "SPACE",
    cover:
      "https://placehold.co/800x1120/9a7257/ffffff?text=SPACE+MAG",
    pages: [
      "https://placehold.co/800x1120/f8f3eb/412e24?text=The+New+Collection",
      "https://placehold.co/800x1120/e7d6c7/412e24?text=Designed+for+Living",
      "https://placehold.co/800x1120/f8f3eb/412e24?text=Your+Next+Room",
      "https://placehold.co/800x1120/e7d6c7/412e24?text=Explore+More",
      "https://placehold.co/800x1120/f8f3eb/412e24?text=Create+Your+Space",
      "https://placehold.co/800x1120/e7d6c7/412e24?text=Pedebook",
    ],
  },
  {
    id: 3,
    title: "NATURE",
    cover:
      "https://placehold.co/800x1120/cdbb9f/17221c?text=NATURE",
    pages: [
      "https://placehold.co/800x1120/f3eddf/17221c?text=Start+Here",
      "https://placehold.co/800x1120/dde0cf/17221c?text=Calm+and+Natural",
      "https://placehold.co/800x1120/f3eddf/17221c?text=Stories+in+Green",
      "https://placehold.co/800x1120/dde0cf/17221c?text=Find+Your+Balance",
      "https://placehold.co/800x1120/f3eddf/17221c?text=See+You+Again",
      "https://placehold.co/800x1120/cdbb9f/17221c?text=Pedebook",
    ],
  },
];

export default function BookShelfClient() {
  const [activeBook, setActiveBook] = useState<Book | null>(null);

  return (
    <>
      {activeBook && (
        <FlipBookModal
          book={activeBook}
          onClose={() => setActiveBook(null)}
        />
      )}

      {/* ชั้นหนังสือตัวอย่าง Flipbook */}
      <div className="mb-16 mt-20 flex flex-col items-center justify-center gap-10 w-full">
        <div className="relative flex w-full max-w-[900px] items-end justify-center gap-4 border-b-[20px] border-[#c4a77d] px-4 pb-1 shadow-[0_35px_40px_-15px_rgba(154,114,87,0.3)] sm:gap-12 sm:px-12 lg:border-b-[24px]">
          <div className="absolute -bottom-[24px] left-10 h-8 w-6 rounded-b-sm bg-[#a88a5d] shadow-inner lg:-bottom-[30px] lg:h-10 lg:w-8" />
          <div className="absolute -bottom-[24px] right-10 h-8 w-6 rounded-b-sm bg-[#a88a5d] shadow-inner lg:-bottom-[30px] lg:h-10 lg:w-8" />

          {mockBooks.map((book, index) => (
            <button
              key={book.id}
              type="button"
              onClick={() => setActiveBook(book)}
              className={`group relative z-10 cursor-pointer text-left outline-none transition-all duration-500 ease-out hover:-translate-y-12 hover:scale-110 focus-visible:ring-4 focus-visible:ring-[#9a7257]/45 ${
                index === 1 ? "z-20 scale-105 hover:scale-115" : ""
              }`}
            >
              <div className="relative h-[180px] w-[110px] overflow-hidden rounded-r-[4px] border-l-[3px] border-white/80 shadow-[-10px_10px_20px_rgba(50,43,34,0.2)] transition-all duration-500 group-hover:shadow-[-20px_25px_40px_rgba(50,43,34,0.3)] sm:h-[260px] sm:w-[170px] lg:h-[300px] lg:w-[200px]">
                {/* eslint-disable-next-line @next/next/no-img-element -- External placeholder URL from placehold.co */}
                <img
                  src={book.cover}
                  alt={`ตัวอย่างสมุดภาพพลิก 3D เล่มที่ ${index + 1} - หัวข้อ ${book.title}`}
                  className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
                />

                {index === 0 && (
                  <span className="absolute -right-7 top-5 rotate-45 bg-[#9a7257] px-8 py-1.5 text-[10px] font-bold text-white shadow-md">
                    NEW
                  </span>
                )}

                <span className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 backdrop-blur-[2px] transition-opacity duration-300 group-hover:opacity-100">
                  <span className="rounded-full bg-white/20 px-4 py-2 text-xs font-bold tracking-widest text-white backdrop-blur-md">
                    CLICK TO READ
                  </span>
                </span>
              </div>

              <span className="absolute -bottom-1 left-0 h-1.5 w-full bg-[#e8dcc7]" />
              <span className="absolute -right-1 top-0 h-full w-1.5 origin-bottom-right skew-y-[45deg] bg-[#d3b894]" />
            </button>
          ))}
        </div>
      </div>
    </>
  );
}
