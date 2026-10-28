'use client';

import React, { useState, useEffect } from 'react';

interface UnblockableAdOverlayProps {
  onAdFinished?: () => void;
  sponsorName?: string;
  title?: string;
  imageUrl?: string;
  targetUrl?: string;
}

export default function UnblockableAdOverlay({
  onAdFinished,
  sponsorName = 'ผู้สนับสนุน Pedebook',
  title = 'ค้นพบดีลพิเศษและสินค้าคุณภาพจากพาร์ทเนอร์ของเรา',
  imageUrl = 'https://images.unsplash.com/photo-1542744094-24638eff58bb?auto=format&fit=crop&w=1200&q=80',
  targetUrl = 'https://www.pedebook.com/pricing',
}: UnblockableAdOverlayProps) {
  const [secondsRemaining, setSecondsRemaining] = useState(5);
  const [canClose, setCanClose] = useState(false);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    if (secondsRemaining <= 0) {
      setCanClose(true);
      return;
    }

    const timer = setInterval(() => {
      setSecondsRemaining((prev) => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [secondsRemaining]);

  const handleDismiss = () => {
    if (!canClose) return;
    setDismissed(true);
    if (onAdFinished) onAdFinished();
  };

  if (dismissed) {
    return (
      <div className="fixed bottom-3 left-3 z-40 bg-[#17221c]/90 text-white/90 backdrop-blur-md px-3 py-1.5 rounded-full text-[11px] font-semibold border border-white/10 shadow-lg flex items-center gap-2">
        <span className="text-amber-400">✨</span>
        <span>สนับสนุนโดย <strong>{sponsorName}</strong></span>
        <a
          href={targetUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="text-amber-300 underline hover:text-white"
        >
          ดูรายละเอียด →
        </a>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-md p-4 animate-fade-in select-none">
      <div className="bg-[#17221c] text-[#e8dcc7] rounded-3xl p-6 sm:p-7 max-w-lg w-full border border-white/15 shadow-2xl relative overflow-hidden flex flex-col justify-between">
        {/* Top Bar with Countdown */}
        <div className="flex items-center justify-between mb-4">
          <div className="inline-flex items-center gap-1.5 bg-amber-400/20 text-amber-300 text-[10px] font-bold px-2.5 py-1 rounded-full border border-amber-400/30">
            <span>📢 สปอนเซอร์</span>
            <span>•</span>
            <span>{sponsorName}</span>
          </div>

          <div className="text-xs font-bold text-white/70">
            {canClose ? (
              <span className="text-emerald-400">✓ พร้อมเปิดอ่านสมุด</span>
            ) : (
              <span>เปิดอ่านได้ใน {secondsRemaining} วินาที...</span>
            )}
          </div>
        </div>

        {/* Sponsor Banner Image */}
        <a
          href={targetUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="block rounded-2xl overflow-hidden border border-white/10 shadow-md group relative mb-4 cursor-pointer"
        >
          <img
            src={imageUrl}
            alt={sponsorName}
            className="w-full h-48 sm:h-56 object-cover group-hover:scale-105 transition-transform duration-300"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent flex flex-col justify-end p-4">
            <h3 className="text-sm sm:text-base font-bold text-white group-hover:underline">
              {title}
            </h3>
            <p className="text-[11px] text-amber-300 mt-1 flex items-center gap-1 font-semibold">
              คลิกเพื่อดูรายละเอียดเพิ่มเติม →
            </p>
          </div>
        </a>

        {/* Notice text */}
        <p className="text-[10px] text-[#e8dcc7]/60 leading-relaxed mb-4 text-center">
          สมุดเล่มนี้ใช้งานผ่านแพ็กเกจฟรี (เกิน 100 MB) จึงมีโฆษณาผู้สนับสนุน เพื่อร่วมสนับสนุนค่าบริการคลาวด์ความเร็วสูง
        </p>

        {/* Action Button */}
        <div className="flex items-center gap-3">
          <a
            href={targetUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex-1 py-3 rounded-full bg-[#d4af37] text-[#17221c] font-black text-xs text-center hover:bg-[#c29d2e] transition shadow-md cursor-pointer"
          >
            เปิดดูข้อเสนอพิเศษ
          </a>

          <button
            onClick={handleDismiss}
            disabled={!canClose}
            className={`px-6 py-3 rounded-full font-bold text-xs transition cursor-pointer ${
              canClose
                ? 'bg-white/15 text-white hover:bg-white/25 active:scale-95'
                : 'bg-white/5 text-white/40 cursor-not-allowed'
            }`}
          >
            {canClose ? 'เข้าอ่านสมุด →' : `รอ ${secondsRemaining}s`}
          </button>
        </div>
      </div>
    </div>
  );
}
