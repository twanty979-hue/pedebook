'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import NavbarClient from '../components/NavbarClient';
import { PLANS, PlanId } from '../src/lib/plans';

export default function PricingPage() {
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [showUpgradeModal, setShowUpgradeModal] = useState<string | null>(null);

  const isYearly = billingCycle === 'yearly';

  const planKeys: PlanId[] = ['free', 'pro', 'ultra', 'business'];

  return (
    <div className="min-h-screen bg-[#f7f5f0] text-[#17221c] flex flex-col font-sans selection:bg-[#243129] selection:text-[#e8dcc7]">
      {/* Top Navbar */}
      <NavbarClient locale="th" />

      {/* Main Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-12">
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
            เริ่มต้นใช้งานได้ <span className="font-bold text-[#243129]">ฟรี 100 MB</span> (อัปโหลดเกินได้) หรือเลือกอัปเกรดเพื่อเพิ่มพื้นที่ ปลดล็อกลายน้ำ ดูสถิติหน้าคนสนใจ และเชิญสมาชิกในทีม
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

        {/* 4 Pricing Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 items-stretch mb-16">
          {planKeys.map((key) => {
            const plan = PLANS[key];
            const isPopular = plan.popular;

            return (
              <div
                key={key}
                className={`rounded-3xl bg-white p-6 shadow-sm flex flex-col justify-between relative transition-all duration-300 hover:shadow-xl ${
                  isPopular
                    ? 'border-2 border-[#243129] shadow-md md:-translate-y-2'
                    : 'border border-[#e2dfd5]'
                }`}
              >
                {isPopular && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-[#243129] text-[#e8dcc7] text-[10px] font-black uppercase tracking-wider px-3.5 py-1 rounded-full shadow-md">
                    ⭐ สุดคุ้ม แนะนำ
                  </div>
                )}

                <div>
                  <div className="flex items-center justify-between mb-3 mt-1">
                    <span className={`text-[11px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full ${
                      isPopular ? 'text-[#243129] bg-[#eef3f0]' : 'text-[#755a47] bg-[#f2efe9]'
                    }`}>
                      {plan.nameTh}
                    </span>
                  </div>
                  <p className="text-xs text-[#6e746f] mb-4 min-h-[36px] leading-relaxed">{plan.tagline}</p>

                  <div className="flex items-baseline gap-1 mb-6">
                    <span className="text-3xl font-black text-[#17221c]">
                      ฿{key === 'free' ? 0 : (isYearly ? Math.round(plan.priceYearly / 12) : plan.priceMonthly)}
                    </span>
                    <span className="text-xs text-[#6e746f]">
                      / เดือน {isYearly && key !== 'free' && `(รวม ${plan.priceYearly.toLocaleString()} บ./ปี)`}
                    </span>
                  </div>

                  <div className="space-y-3 mb-8 text-xs">
                    <div className="flex items-center gap-2 font-bold text-[#243129]">
                      <svg className="w-4 h-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                      </svg>
                      <span>พื้นที่จัดเก็บ: {plan.storageLabel}</span>
                    </div>

                    {key === 'free' && (
                      <div className="flex items-start gap-2 text-amber-800 bg-amber-50 p-2 rounded-xl text-[11px] leading-snug">
                        <span className="shrink-0 font-bold">ℹ️</span>
                        <span>อัปโหลดเกิน 100 MB ได้ โดยสมุดจะแสดงโฆษณาผู้สนับสนุน</span>
                      </div>
                    )}

                    {plan.canTeamCollab && (
                      <div className="flex items-center gap-2 font-bold text-emerald-800 bg-emerald-50 p-2 rounded-xl text-[11px]">
                        <span>👥</span>
                        <span>เชิญทีมงานได้สูงสุด 10 คนต่อทีม</span>
                      </div>
                    )}

                    {plan.features.map((feature, i) => (
                      <div key={i} className="flex items-start gap-2 text-[#4a524d]">
                        <svg className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        <span>{feature}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {key === 'free' ? (
                  <Link
                    href="/dashboard"
                    className="w-full text-center py-3 rounded-full border border-[#243129] text-[#243129] font-bold text-xs hover:bg-[#243129] hover:text-[#e8dcc7] transition shadow-xs cursor-pointer block"
                  >
                    เริ่มต้นใช้งานฟรีทันที
                  </Link>
                ) : (
                  <button
                    onClick={() =>
                      setShowUpgradeModal(
                        `${plan.name} (฿${isYearly ? `${plan.priceYearly} บ./ปี` : `${plan.priceMonthly} บ./เดือน`})`
                      )
                    }
                    className={`w-full py-3 rounded-full font-black text-xs transition shadow-md cursor-pointer text-center ${
                      isPopular
                        ? 'bg-[#243129] text-[#e8dcc7] hover:bg-[#314238] hover:scale-[1.02] active:scale-95'
                        : 'border border-[#243129] text-[#243129] hover:bg-[#243129] hover:text-[#e8dcc7]'
                    }`}
                  >
                    เลือก {plan.name}
                  </button>
                )}
              </div>
            );
          })}
        </div>

        {/* FAQ Section */}
        <div className="max-w-3xl mx-auto mt-16">
          <h3 className="text-xl sm:text-2xl font-black text-center text-[#17221c] mb-8">
            คำถามที่พบบ่อย (FAQ)
          </h3>
          <div className="space-y-4">
            <div className="bg-white rounded-2xl p-5 border border-[#e2dfd5]">
              <h4 className="text-sm font-bold text-[#17221c] mb-1">
                แพลนฟรี 100 MB ถ้าอัปโหลดไฟล์เกินจะเกิดอะไรขึ้น?
              </h4>
              <p className="text-xs text-[#6e746f] leading-relaxed">
                ระบบจะไม่บล็อกการอัปโหลดของคุณครับ สามารถสร้างและอัปโหลดได้ตามปกติ แต่เมื่อพื้นที่รวมเกิน 100 MB สมุด Flipbook ของคุณจะแสดงโฆษณาผู้สนับสนุน เพื่อช่วยสนับสนุนค่าใช้จ่ายเซิร์ฟเวอร์ หรือคุณสามารถอัปเกรดเป็นแพ็กเกจ Pro เพียง 49 บาท/เดือน เพื่อปลดล็อกเป็น 5 GB และไม่มีโฆษณา 100% ครับ
              </p>
            </div>

            <div className="bg-white rounded-2xl p-5 border border-[#e2dfd5]">
              <h4 className="text-sm font-bold text-[#17221c] mb-1">
                ระบบสถิติการเปิดอ่านแต่ละหน้าทำงานอย่างไร?
              </h4>
              <p className="text-xs text-[#6e746f] leading-relaxed">
                ระบบจะตรวจจับเวลาที่ผู้อ่านเปิดค้างไว้ในแต่ละหน้าของ Flipbook แบบเรียลไทม์ ทำให้คุณรู้ได้ทันทีว่าหน้าสินค้าใดที่ลูกค้าให้ความสนใจมากที่สุด และหน้าใดที่ลูกค้าพลิกผ่านไปเร็ว ช่วยให้ปรับปรุงเนื้อหาและเพิ่มยอดขายได้อย่างตรงจุด
              </p>
            </div>

            <div className="bg-white rounded-2xl p-5 border border-[#e2dfd5]">
              <h4 className="text-sm font-bold text-[#17221c] mb-1">
                ระบบทีม (Team Collaboration) ในแพ็กเกจ Business ทำงานอย่างไร?
              </h4>
              <p className="text-xs text-[#6e746f] leading-relaxed">
                เจ้าของบัญชี Business สามารถส่งอีเมลเชิญทีมงานเข้ามาร่วมจัดการ อัปโหลด แก้ไข และดูรายงานสถิติของแค็ตตาล็อกร่วมกันได้สูงสุด 10 คนต่อทีม โดยมีระบบกำหนดบทบาทและสิทธิ์อย่างชัดเจน
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
              className="absolute top-4 right-4 text-[#6e746f] hover:text-[#17221c] transition cursor-pointer"
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
            <p className="text-xs text-[#6e746f] mb-6">
              คุณกำลังเลือก: <span className="font-bold text-[#243129]">{showUpgradeModal}</span>
            </p>

            <div className="bg-[#f7f5f0] p-4 rounded-2xl border border-[#e2dfd5] mb-6 space-y-3 text-xs">
              <div className="flex justify-between items-center text-[#17221c]">
                <span>การเปิดใช้งาน:</span>
                <span className="font-bold text-emerald-700">ทันทีหลังยืนยันสลิป</span>
              </div>
              <div className="flex justify-between items-center text-[#17221c]">
                <span>ช่องทางชำระเงิน:</span>
                <span className="font-bold">PromptPay / โอนธนาคาร</span>
              </div>
              <div className="flex justify-between items-center text-[#17221c]">
                <span>ติดต่อทีมงาน:</span>
                <span className="font-bold text-[#243129]">LINE: @pedebook</span>
              </div>
            </div>

            <div className="flex flex-col gap-2.5">
              <a
                href="https://line.me"
                target="_blank"
                rel="noreferrer"
                className="w-full py-3.5 rounded-full bg-[#06c755] text-white font-bold text-xs text-center shadow-md hover:bg-[#05b34c] transition cursor-pointer flex items-center justify-center gap-2"
              >
                <span>💬 ติดต่อแอดมินทาง LINE ทันที</span>
              </a>
              <button
                onClick={() => setShowUpgradeModal(null)}
                className="w-full py-2.5 rounded-full border border-[#d9d7cd] text-[#6e746f] font-semibold text-xs text-center hover:bg-neutral-50 transition cursor-pointer"
              >
                ปิดหน้าต่าง
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
