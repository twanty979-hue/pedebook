'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import NavbarClient from '../components/NavbarClient';
import { PLANS } from '../src/lib/plans';

export default function PricingPage() {
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [showUpgradeModal, setShowUpgradeModal] = useState<string | null>(null);

  const isYearly = billingCycle === 'yearly';

  return (
    <div className="min-h-screen bg-[#f7f5f0] text-[#17221c] flex flex-col font-sans selection:bg-[#243129] selection:text-[#e8dcc7]">
      {/* Top Navbar */}
      <NavbarClient locale="th" />

      {/* Main Content */}
      <main className="flex-1 max-w-6xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Header Section */}
        <div className="text-center max-w-3xl mx-auto mb-12">
          <div className="inline-flex items-center gap-2 rounded-full border border-[#243129]/20 bg-white/80 px-4 py-1.5 text-xs font-bold text-[#243129] shadow-xs mb-4">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>แผนบริการที่โปร่งใส ไม่มีค่าใช้จ่ายแอบแฝง</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-black tracking-tight text-[#17221c] mb-4">
            เลือกแพ็กเกจที่ลงตัวกับธุรกิจของคุณ
          </h1>
          <p className="text-sm sm:text-base text-[#6e746f] leading-relaxed">
            เริ่มต้นใช้งานได้ <span className="font-bold text-[#243129]">ฟรี ไม่จำกัดจำนวนเล่ม</span> โดยไม่ต้องกรอกบัตรเครดิต สร้างยอดขายและแชร์แค็ตตาล็อกออนไลน์ให้ลูกค้าของคุณได้ทันที
          </p>

          {/* Billing Cycle Switcher */}
          <div className="mt-8 inline-flex items-center gap-1.5 bg-[#e8e4db] p-1.5 rounded-full border border-[#d9d5cb] shadow-inner">
            <button
              onClick={() => setBillingCycle('monthly')}
              className={`px-5 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
                !isYearly
                  ? 'bg-[#243129] text-[#e8dcc7] shadow-sm'
                  : 'text-[#6e746f] hover:text-[#17221c]'
              }`}
            >
              ชำระรายเดือน
            </button>
            <button
              onClick={() => setBillingCycle('yearly')}
              className={`flex items-center gap-2 px-5 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
                isYearly
                  ? 'bg-[#243129] text-[#e8dcc7] shadow-sm'
                  : 'text-[#6e746f] hover:text-[#17221c]'
              }`}
            >
              <span>ชำระรายปี</span>
              <span className="bg-emerald-600 text-white text-[10px] px-2 py-0.5 rounded-full font-bold">
                แถมฟรี 2 เดือน 🔥
              </span>
            </button>
          </div>
        </div>

        {/* Limited Early Bird Lifetime Banner */}
        <div className="mb-12 rounded-3xl bg-gradient-to-r from-[#243129] via-[#314238] to-[#17221c] p-6 sm:p-8 text-[#e8dcc7] shadow-xl relative overflow-hidden border border-[#d4af37]/30">
          <div className="absolute -right-12 -bottom-12 w-48 h-48 bg-[#d4af37]/10 rounded-full blur-3xl pointer-events-none" />
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6 relative z-10">
            <div>
              <div className="inline-flex items-center gap-1.5 bg-[#d4af37]/20 border border-[#d4af37]/40 text-[#f5e6a3] text-xs font-bold px-3 py-1 rounded-full mb-3">
                <span>⚡ สิทธิพิเศษช่วงเปิดตัว (จำกัด 50 ท่านแรก)</span>
              </div>
              <h2 className="text-xl sm:text-2xl font-black text-white">
                Early-Bird Lifetime Deal — จ่ายครั้งเดียวจบ 1,990 บาท
              </h2>
              <p className="text-xs sm:text-sm text-[#e8dcc7]/80 mt-1 max-w-2xl leading-relaxed">
                รับสิทธิ์ใช้งานฟังก์ชัน <strong className="text-white">Pro Trader ตลอดชีพ</strong> ไม่ต้องจ่ายรายเดือนอีกต่อไป รองรับไฟล์ใหญ่ 300 MB พื้นที่จัดเก็บไม่จำกัด และอัปเดตฟีเจอร์ใหม่ฟรีตลอดอายุการใช้งาน
              </p>
            </div>
            <button
              onClick={() => setShowUpgradeModal('Early-Bird Lifetime (1,990 บาท จ่ายครั้งเดียว)')}
              className="shrink-0 bg-[#d4af37] hover:bg-[#c29d2e] text-[#17221c] font-black text-xs sm:text-sm px-6 py-3.5 rounded-full shadow-lg transition-transform hover:scale-105 active:scale-95 cursor-pointer text-center"
            >
              จองสิทธิ์ 1,990 บ. (ตลอดชีพ)
            </button>
          </div>
        </div>

        {/* 3 Pricing Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch mb-16">
          {/* Card 1: Free Starter */}
          <div className="rounded-3xl bg-white border border-[#e2dfd5] p-7 shadow-xs flex flex-col justify-between hover:shadow-md transition">
            <div>
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-bold uppercase tracking-wider text-[#755a47] bg-[#f2efe9] px-3 py-1 rounded-full">
                  {PLANS.free.nameTh}
                </span>
              </div>
              <p className="text-xs text-[#6e746f] mb-6 min-h-[32px]">{PLANS.free.tagline}</p>
              <div className="flex items-baseline gap-1 mb-6">
                <span className="text-4xl font-black text-[#17221c]">฿0</span>
                <span className="text-xs text-[#6e746f]">/ ตลอดชีพ</span>
              </div>

              <div className="space-y-3.5 mb-8 text-xs text-[#17221c]">
                <div className="flex items-center gap-2 font-bold text-[#243129]">
                  <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>ไม่จำกัดจำนวนเล่ม (Unlimited)</span>
                </div>
                <div className="flex items-center gap-2 font-bold text-[#243129]">
                  <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>ขนาดไฟล์สูงสุด 300 MB / เล่ม</span>
                </div>
                {PLANS.free.features.slice(2).map((feature, i) => (
                  <div key={i} className="flex items-start gap-2 text-[#6e746f]">
                    <svg className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>{feature}</span>
                  </div>
                ))}
              </div>
            </div>

            <Link
              href="/dashboard"
              className="w-full text-center py-3 rounded-full border border-[#243129] text-[#243129] font-bold text-xs hover:bg-[#243129] hover:text-[#e8dcc7] transition shadow-xs cursor-pointer block"
            >
              เริ่มต้นใช้งานฟรีทันที
            </Link>
          </div>

          {/* Card 2: Pro Trader (Popular) */}
          <div className="rounded-3xl bg-white border-2 border-[#243129] p-7 shadow-xl flex flex-col justify-between relative hover:shadow-2xl transition-all duration-300 transform md:-translate-y-2">
            <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-[#243129] text-[#e8dcc7] text-[11px] font-black uppercase tracking-wider px-4 py-1 rounded-full shadow-md">
              ⭐ แนะนำ / คุ้มค่าที่สุด
            </div>

            <div>
              <div className="flex items-center justify-between mb-4 mt-2">
                <span className="text-xs font-bold uppercase tracking-wider text-[#243129] bg-[#eef3f0] px-3 py-1 rounded-full">
                  {PLANS.starter.nameTh}
                </span>
              </div>
              <p className="text-xs text-[#6e746f] mb-6 min-h-[32px]">{PLANS.starter.tagline}</p>

              <div className="flex items-baseline gap-1 mb-6">
                <span className="text-4xl font-black text-[#17221c]">
                  ฿{isYearly ? Math.round(PLANS.starter.priceYearly / 12) : PLANS.starter.priceMonthly}
                </span>
                <span className="text-xs text-[#6e746f]">
                  / เดือน {isYearly && `(รวม ${PLANS.starter.priceYearly.toLocaleString()} บ./ปี)`}
                </span>
              </div>

              <div className="space-y-3.5 mb-8 text-xs text-[#17221c]">
                <div className="flex items-center gap-2 font-bold text-[#243129]">
                  <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>แค็ตตาล็อกสูงสุด 30 เล่ม</span>
                </div>
                <div className="flex items-center gap-2 font-bold text-[#243129]">
                  <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>ขนาดไฟล์สูงสุด 100 MB / เล่ม (รวม 5 GB)</span>
                </div>
                <div className="flex items-center gap-2 font-bold text-[#243129] bg-[#eef3f0] p-2 rounded-xl">
                  <span className="text-amber-600 font-bold">✨</span>
                  <span>ปลดล็อกลายน้ำ Pedebook ออก 100%</span>
                </div>
                {PLANS.starter.features.slice(3).map((feature, i) => (
                  <div key={i} className="flex items-start gap-2 text-[#243129]">
                    <svg className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>{feature}</span>
                  </div>
                ))}
              </div>
            </div>

            <button
              onClick={() => setShowUpgradeModal(`Pro Trader (${isYearly ? `${PLANS.starter.priceYearly} บ./ปี` : `${PLANS.starter.priceMonthly} บ./เดือน`})`)}
              className="w-full py-3.5 rounded-full bg-[#243129] text-[#e8dcc7] font-black text-xs hover:bg-[#314238] transition shadow-md cursor-pointer text-center hover:scale-[1.02] active:scale-95"
            >
              เลือกแพ็กเกจ Pro
            </button>
          </div>

          {/* Card 3: Business Enterprise */}
          <div className="rounded-3xl bg-white border border-[#e2dfd5] p-7 shadow-xs flex flex-col justify-between hover:shadow-md transition">
            <div>
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-bold uppercase tracking-wider text-[#755a47] bg-[#f2efe9] px-3 py-1 rounded-full">
                  {PLANS.business.nameTh}
                </span>
              </div>
              <p className="text-xs text-[#6e746f] mb-6 min-h-[32px]">{PLANS.business.tagline}</p>

              <div className="flex items-baseline gap-1 mb-6">
                <span className="text-4xl font-black text-[#17221c]">
                  ฿{isYearly ? Math.round(PLANS.business.priceYearly / 12) : PLANS.business.priceMonthly}
                </span>
                <span className="text-xs text-[#6e746f]">
                  / เดือน {isYearly && `(รวม ${PLANS.business.priceYearly.toLocaleString()} บ./ปี)`}
                </span>
              </div>

              <div className="space-y-3.5 mb-8 text-xs text-[#17221c]">
                <div className="flex items-center gap-2 font-bold text-[#243129]">
                  <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>ไม่จำกัดจำนวนเล่ม (Unlimited)</span>
                </div>
                <div className="flex items-center gap-2 font-bold text-[#243129]">
                  <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>ขนาดไฟล์สูงสุด 250 MB / เล่ม (รวม 25 GB)</span>
                </div>
                {PLANS.business.features.slice(2).map((feature, i) => (
                  <div key={i} className="flex items-start gap-2 text-[#243129]">
                    <svg className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>{feature}</span>
                  </div>
                ))}
              </div>
            </div>

            <button
              onClick={() => setShowUpgradeModal(`Business Enterprise (${isYearly ? `${PLANS.business.priceYearly} บ./ปี` : `${PLANS.business.priceMonthly} บ./เดือน`})`)}
              className="w-full py-3 rounded-full border border-[#243129] text-[#243129] font-bold text-xs hover:bg-[#243129] hover:text-[#e8dcc7] transition shadow-xs cursor-pointer text-center"
            >
              เลือกแพ็กเกจ Business
            </button>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="max-w-3xl mx-auto mt-16">
          <h3 className="text-xl sm:text-2xl font-black text-center text-[#17221c] mb-8">
            คำถามที่พบบ่อย (FAQ)
          </h3>
          <div className="space-y-4">
            <div className="bg-white rounded-2xl p-5 border border-[#e2dfd5]">
              <h4 className="text-sm font-bold text-[#17221c] mb-1">
                แพลนฟรี ใช้งานได้นานแค่ไหน?
              </h4>
              <p className="text-xs text-[#6e746f] leading-relaxed">
                ใช้งานได้ตลอดชีพครับ สามารถอัปโหลดไฟล์ PDF ได้ไม่จำกัดจำนวนเล่ม รองรับไฟล์ขนาดใหญ่สูงสุด 300 MB ต่อเล่ม และแชร์ลิงก์หรือ QR Code ให้ลูกค้าเปิดอ่านได้ไม่จำกัดจำนวนครั้ง
              </p>
            </div>

            <div className="bg-white rounded-2xl p-5 border border-[#e2dfd5]">
              <h4 className="text-sm font-bold text-[#17221c] mb-1">
                ถ้าไฟล์ PDF มีขนาดใหญ่ จะเปิดอ่านได้เร็วไหม?
              </h4>
              <p className="text-xs text-[#6e746f] leading-relaxed">
                ระบบเชื่อมต่อกับ Cloudflare Edge CDN ทั่วโลก ทำให้ไม่ว่าไฟล์จะมีขนาดใหญ่แค่ไหน ลูกค้าที่กดเปิดผ่านมือถือก็สามารถเปิดพลิกอ่านได้อย่างลื่นไหล รวดเร็ว ไม่ต้องรอดาวน์โหลดทั้งเล่มครับ
              </p>
            </div>

            <div className="bg-white rounded-2xl p-5 border border-[#e2dfd5]">
              <h4 className="text-sm font-bold text-[#17221c] mb-1">
                วิธีชำระเงินและเปิดใช้งานแพ็กเกจทำอย่างไร?
              </h4>
              <p className="text-xs text-[#6e746f] leading-relaxed">
                สามารถสแกน QR Code พร้อมเพย์ หรือโอนเงินผ่านธนาคาร แล้วส่งสลิปผ่านทาง LINE Official Account ได้ทันที ทีมงานจะทำการปรับสถานะบัญชีให้พร้อมใช้งานภายใน 5 นาทีครับ
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Upgrade / Payment Contact Modal */}
      {showUpgradeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4" onClick={() => setShowUpgradeModal(null)}>
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-md w-full border border-[#e2dfd5] shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setShowUpgradeModal(null)}
              className="absolute top-4 right-4 text-[#6e746f] hover:text-[#17221c] transition"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            <div className="w-12 h-12 rounded-2xl bg-[#243129]/10 text-[#243129] flex items-center justify-center mb-4">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
              </svg>
            </div>

            <h3 className="text-lg font-bold text-[#17221c] mb-1">แจ้งอัปเกรดแพ็กเกจ</h3>
            <p className="text-xs text-[#6e746f] mb-4">
              คุณกำลังเลือก: <span className="font-bold text-[#243129]">{showUpgradeModal}</span>
            </p>

            <div className="bg-[#f7f5f0] border border-[#e2dfd5] rounded-2xl p-4 mb-5 text-center">
              <p className="text-xs font-bold text-[#17221c] mb-2">สแกนชำระเงิน หรือทักแชตแอดมิน</p>
              <p className="text-[11px] text-[#6e746f] leading-relaxed mb-3">
                แจ้งอีเมลของคุณที่ใช้สมัครเพื่อเปิดใช้งานสิทธิ์ Pro / Business ได้ทันที
              </p>
              <a
                href="https://line.me"
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center gap-2 w-full py-3 rounded-full bg-[#06c755] text-white font-bold text-xs shadow-md hover:bg-[#05b34c] transition"
              >
                <span>💬 ทักแชต LINE เพื่อเปิดใช้งานทันที</span>
              </a>
            </div>

            <button
              onClick={() => setShowUpgradeModal(null)}
              className="w-full text-center py-2 text-xs font-semibold text-[#6e746f] hover:text-[#17221c]"
            >
              ไว้คราวหน้า
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
