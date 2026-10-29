import React from 'react';
import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import NavbarClient from './components/NavbarClient';
import BookShelfClient from './components/BookShelfClient';
import { 
  SEO_CONFIG,
  absoluteUrl, 
  JsonLd, 
  generateOrganizationJsonLd, 
  generateWebSiteJsonLd, 
  generateWebApplicationJsonLd, 
  generateFAQJsonLd 
} from './src/lib/seo';

/** Homepage-specific metadata (canonical, OG, Twitter, and positive robots) */
export const metadata: Metadata = {
  alternates: {
    canonical: absoluteUrl('/'),
    languages: {
      th: absoluteUrl('/'),
      en: absoluteUrl('/en'),
      'x-default': absoluteUrl('/'),
    },
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  openGraph: {
    title: "แปลง PDF เป็น Flipbook ออนไลน์ฟรี | Pedebook",
    description: "สร้างแคตตาล็อก E-Book และโบรชัวร์ออนไลน์ฟรีจาก PDF เปิดอ่านแบบพลิกหน้า แชร์ลิงก์และ QR Code ได้ทันที รองรับมือถือและคอมพิวเตอร์",
    type: "website",
    url: absoluteUrl('/'),
    siteName: SEO_CONFIG.siteName,
    locale: "th_TH",
    alternateLocale: ["en_US"],
  },
  twitter: {
    card: "summary_large_image",
    title: "แปลง PDF เป็น Flipbook ออนไลน์ฟรี | Pedebook",
    description: "สร้างแคตตาล็อก E-Book และโบรชัวร์ออนไลน์ฟรีจาก PDF เปิดอ่านแบบพลิกหน้า แชร์ลิงก์และ QR Code ได้ทันที รองรับมือถือและคอมพิวเตอร์",
  },
};

// Definition of FAQs for rendering and schema generation
const FAQS = [
  {
    question: "Pedebook คืออะไร?",
    answer: "Pedebook คือเครื่องมือออนไลน์ที่ช่วยแปลงเอกสาร PDF ของคุณให้เป็นสมุดพลิก (Flipbook) หรือแคตตาล็อกออนไลน์แบบ 3D พลิกหน้าได้เสมือนจริง เปิดอ่านง่ายผ่านเว็บเบราว์เซอร์"
  },
  {
    question: "ขั้นตอนการแปลง PDF เป็นแคตตาล็อกออนไลน์มีอะไรบ้าง?",
    answer: "ใช้งานง่ายเพียง 3 ขั้นตอน: (1) เข้าสู่ระบบหรือสมัครสมาชิก (2) อัปโหลดไฟล์ PDF ของคุณเข้าสู่ระบบ และ (3) รับลิงก์แชร์เฉพาะและภาพ QR Code ไปส่งต่อให้ลูกค้าหรือเผยแพร่บนสื่อประชาสัมพันธ์ได้ทันที"
  },
  {
    question: "รองรับการเปิดอ่านบนสมาร์ทโฟนและแท็บเล็ตหรือไม่?",
    answer: "รองรับมือถือ แท็บเล็ต และคอมพิวเตอร์ แสดงผลได้สวยงามทั้งระบบ iOS, Android, iPad และคอมพิวเตอร์ทั่วไป โดยอ่านผ่านเว็บเบราว์เซอร์ได้ทันทีโดยไม่ต้องติดตั้งแอปพลิเคชันเพิ่มเติม"
  },
  {
    question: "สามารถแชร์แคตตาล็อกสินค้าออนไลน์ผ่านช่องทางใดได้บ้าง?",
    answer: "คุณสามารถคัดลอกลิงก์เฉพาะของแคตตาล็อกเพื่อแชร์ผ่านแอปพลิเคชัน LINE, LINE Official Account, Facebook Messenger หรือใช้วิธีส่งภาพคิวอาร์โค้ด (QR Code) เพื่อให้คู่ค้าสแกนอ่านอย่างรวดเร็ว"
  }
];

export default function LandingPage() {
  const canonicalUrl = absoluteUrl('/');

  // Schema data configurations
  const orgSchema = generateOrganizationJsonLd(canonicalUrl);
  const websiteSchema = generateWebSiteJsonLd(canonicalUrl);
  const webAppSchema = generateWebApplicationJsonLd(canonicalUrl);
  const faqSchema = generateFAQJsonLd(canonicalUrl, FAQS);

  return (
    <main className="min-h-screen overflow-hidden bg-[#f6f4ee] font-sans text-[#17221c]">
      {/* JSON-LD Structured Data */}
      <JsonLd data={orgSchema} />
      <JsonLd data={websiteSchema} />
      <JsonLd data={webAppSchema} />
      <JsonLd data={faqSchema} />

      <style
        dangerouslySetInnerHTML={{
          __html: `
            html {
              scrollbar-gutter: stable;
            }

            .pedebook-flipbook .stf__item {
              box-shadow: 0 28px 70px rgba(0, 0, 0, 0.28);
              border-radius: 10px;
              overflow: hidden;
            }

            @keyframes pedebook-floating-book-in {
              0% {
                opacity: 0;
                transform: translateY(40px) scale(0.94) rotateX(8deg);
              }
              100% {
                opacity: 1;
                transform: translateY(0) scale(1) rotateX(0deg);
              }
            }

            @keyframes pedebook-soft-float {
              0%, 100% {
                transform: translateY(0px);
              }
              50% {
                transform: translateY(-8px);
              }
            }

            .pedebook-floating-book {
              animation:
                pedebook-floating-book-in 260ms cubic-bezier(.2,.8,.2,1) both,
                pedebook-soft-float 4s ease-in-out 260ms infinite;
              transform-origin: center center;
              will-change: transform, opacity;
            }

            @keyframes float-slow {
              0%, 100% {
                transform: translateY(0px) rotate(0deg);
              }
              50% {
                transform: translateY(-15px) rotate(2deg);
              }
            }

            .animate-float {
              animation: float-slow 6s ease-in-out infinite;
            }
          `,
        }}
      />

      {/* Navigation Header */}
      <NavbarClient />

      {/* Hero Section */}
      <section className="relative flex flex-col items-center justify-center py-10 text-center lg:py-20 overflow-hidden">
        <div className="animate-float absolute left-1/2 top-[30%] h-[400px] w-[400px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#d3b894]/30 blur-[90px] lg:h-[600px] lg:w-[600px]" />

        <div className="relative z-10 mx-auto max-w-[1200px] px-5">
          <div className="mx-auto mb-7 w-fit rounded-[28px] border border-[#e7dfd2] bg-white/90 px-4 py-2 shadow-[0_16px_40px_rgba(36,49,41,0.08)] backdrop-blur">
            <Image
              src="/pedebook-logo-lockup.png"
              alt="Pedebook"
              width={360}
              height={108}
              priority
              className="h-auto w-[230px] mix-blend-multiply sm:w-[310px]"
            />
          </div>

          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#d9d7cd] bg-white/60 px-4 py-2 text-xs font-bold tracking-[0.12em] text-[#755a47] shadow-sm backdrop-blur">
            <span className="h-2 w-2 animate-pulse rounded-full bg-[#9a7257]" />
            สร้างได้ฟรี · แชร์ได้ทันที
          </div>

          {/* H1 SEO Main Header */}
          <h1 className="text-4xl font-medium leading-[1.1] tracking-tight text-[#17221c] sm:text-5xl lg:text-[72px]">
            แปลง PDF เป็น <br className="sm:hidden" />
            <span className="font-serif italic text-[#9a7257]">Flipbook</span> และแคตตาล็อกออนไลน์
          </h1>

          <p className="mx-auto mt-6 max-w-2xl text-lg text-[#6e746f] sm:text-xl font-sans">
            เปลี่ยนเอกสารนำเสนอและคู่มือ PDF ของคุณให้เป็นสมุดพลิก 3D ดิจิทัลเสมือนจริง เปิดหน้าสมจริง<br className="hidden sm:block" />
            <span className="font-semibold text-[#8a654d]">
              แชร์ลิงก์ด่วนและสร้างคิวอาร์โค้ดได้ทันที รองรับมือถือ แท็บเล็ต และคอมพิวเตอร์ ออกแบบเพื่อธุรกิจและร้านค้าไทย
            </span>
          </p>

          {/* Client-Side Interactive Books Shelf */}
          <BookShelfClient />
        </div>
      </section>

      {/* Value Proposition / Benefits Section */}
      <section className="relative py-16 bg-white/50 border-y border-[#e2dfd5] backdrop-blur-sm">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2 className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">ทำไมต้องเลือกใช้ Pedebook?</h2>
            <p className="mt-2 text-3xl font-medium tracking-tight text-[#17221c] sm:text-4xl">
              เปลี่ยนเอกสารธรรมดาให้เป็นความประทับใจระดับพรีเมียม
            </p>
            <p className="mt-4 text-base text-[#6e746f]">
              เรามอบโซลูชันที่ง่ายและรวดเร็วที่สุดสำหรับธุรกิจ SME ฝ่ายขาย และผู้ประกอบการไทยในการนำเสนอผลงานผ่านสมุดดิจิทัล
            </p>
          </div>

          <div className="mx-auto mt-12 max-w-5xl sm:mt-16 lg:mt-20">
            <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-2">
              <div className="relative pl-16">
                <dt className="text-base font-bold text-[#17221c]">
                  <div className="absolute left-0 top-0 flex h-10 w-10 items-center justify-center rounded-xl bg-[#243129] text-[#e8dcc7]">
                    ✓
                  </div>
                  แปลงไฟล์ง่าย ประสิทธิภาพสูง
                </dt>
                <dd className="mt-2 text-sm text-[#6e746f]">
                  เพียงลากและวางเอกสาร PDF เข้าสู่ระบบ ระบบจะเปลี่ยนเป็นแคตตาล็อกหน้าสมุดพลิกทันทีโดยอัตโนมัติ
                </dd>
              </div>

              <div className="relative pl-16">
                <dt className="text-base font-bold text-[#17221c]">
                  <div className="absolute left-0 top-0 flex h-10 w-10 items-center justify-center rounded-xl bg-[#243129] text-[#e8dcc7]">
                    ✓
                  </div>
                  สร้าง QR Code และลิงก์สำหรับแชร์
                </dt>
                <dd className="mt-2 text-sm text-[#6e746f]">
                  รับภาพคิวอาร์โค้ดขนาดใหญ่ คมชัด และลิงก์เฉพาะของแคตตาล็อก นำไปส่งต่อในห้องแชต LINE หรือวางบนป้ายหน้าร้านค้าของคุณได้อย่างง่ายดาย
                </dd>
              </div>

              <div className="relative pl-16">
                <dt className="text-base font-bold text-[#17221c]">
                  <div className="absolute left-0 top-0 flex h-10 w-10 items-center justify-center rounded-xl bg-[#243129] text-[#e8dcc7]">
                    ✓
                  </div>
                  เอฟเฟกต์พลิก 3D ลื่นไหลแบบมีมิติ
                </dt>
                <dd className="mt-2 text-sm text-[#6e746f]">
                  ช่วยเพิ่มประสบการณ์การอ่านให้ดูสนุกและพรีเมียมมากขึ้นด้วยฟังก์ชันสมุดกางเปิดหน้า พลิกกระดาษ 3D สมจริง สะกดสายตาลูกค้า
                </dd>
              </div>

              <div className="relative pl-16">
                <dt className="text-base font-bold text-[#17221c]">
                  <div className="absolute left-0 top-0 flex h-10 w-10 items-center justify-center rounded-xl bg-[#243129] text-[#e8dcc7]">
                    ✓
                  </div>
                  รองรับมือถือ แท็บเล็ต และคอมพิวเตอร์
                </dt>
                <dd className="mt-2 text-sm text-[#6e746f]">
                  หมดปัญหาความยุ่งยากในมุมมองโทรศัพท์มือถือ หน้ากระดาษจะปรับขนาดให้เข้ากับอัตราส่วนของสมาร์ทโฟนโดยอัตโนมัติ
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </section>

      {/* 3 Steps Guide Section */}
      <section className="py-16">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2 className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">คู่มือการใช้งาน</h2>
            <p className="mt-2 text-3xl font-medium tracking-tight text-[#17221c] sm:text-4xl">
              เริ่มต้นสร้างเอกสารดิจิทัลใน 3 ขั้นตอน
            </p>
          </div>

          <div className="mx-auto mt-12 grid max-w-5xl grid-cols-1 gap-8 sm:grid-cols-3">
            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-8 backdrop-blur-md shadow-sm relative overflow-hidden text-center">
              <span className="absolute -right-2 -top-2 text-7xl font-bold font-serif text-neutral-100 select-none">1</span>
              <h3 className="text-lg font-bold text-[#17221c] z-10 relative">เข้าสู่ระบบเพื่อจัดการ</h3>
              <p className="mt-2 text-sm text-[#6e746f] z-10 relative">
                ลงชื่อเข้าใช้งานอย่างสะดวกด้วย Google Account หรือใช้อีเมลเพื่อเข้าสู่แผงควบคุมส่วนตัวเฉพาะบัญชีของคุณ
              </p>
            </div>

            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-8 backdrop-blur-md shadow-sm relative overflow-hidden text-center">
              <span className="absolute -right-2 -top-2 text-7xl font-bold font-serif text-neutral-100 select-none">2</span>
              <h3 className="text-lg font-bold text-[#17221c] z-10 relative">อัปโหลดไฟล์ PDF</h3>
              <p className="mt-2 text-sm text-[#6e746f] z-10 relative">
                เลือกคู่มือ แผ่นพับ หรือแคตตาล็อกสินค้าในรูปแบบเอกสาร PDF เพื่อดำเนินการอัปโหลดเข้าสู่ระบบ
              </p>
            </div>

            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-8 backdrop-blur-md shadow-sm relative overflow-hidden text-center">
              <span className="absolute -right-2 -top-2 text-7xl font-bold font-serif text-neutral-100 select-none">3</span>
              <h3 className="text-lg font-bold text-[#17221c] z-10 relative">รับลิงก์และแชร์ใช้งาน</h3>
              <p className="mt-2 text-sm text-[#6e746f] z-10 relative">
                รับลิงก์เฉพาะเจาะจงพร้อมภาพ QR Code ความคมชัดสูง เพื่อส่งทาง LINE แชต หรือพิมพ์แนบสื่อต่างๆ ได้อย่างง่ายดาย
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Target Audience / Use cases Section */}
      <section className="py-16 bg-[#efe7d8]/30 border-y border-[#e2dfd5]">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2 className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">กลุ่มผู้ใช้ที่แนะนำ</h2>
            <p className="mt-2 text-3xl font-medium tracking-tight text-[#17221c] sm:text-4xl">
              ตอบโจทย์งานเอกสารและสื่อนำเสนอของทุกรูปแบบธุรกิจ
            </p>
          </div>

          <div className="mx-auto mt-12 grid max-w-5xl grid-cols-1 gap-8 sm:grid-cols-2">
            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-6 backdrop-blur-md shadow-sm flex items-start gap-4">
              <span className="text-2xl mt-1">🏪</span>
              <div>
                <h3 className="text-base font-bold text-[#17221c]">ผู้ประกอบการ SME และร้านค้าออนไลน์</h3>
                <p className="mt-1.5 text-xs text-[#6e746f] leading-relaxed">
                  แปลงโบรชัวร์สินค้าหรือแคตตาล็อกหน้ากระดาษแบบเดิม ให้แชร์และเปิดดูได้บนมือถือลูกค้าทันที ช่วยให้ส่งข้อมูลสินค้าให้ลูกค้าได้สะดวกและภาพลักษณ์ทันสมัย
                </p>
              </div>
            </div>

            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-6 backdrop-blur-md shadow-sm flex items-start gap-4">
              <span className="text-2xl mt-1">👔</span>
              <div>
                <h3 className="text-base font-bold text-[#17221c]">ฝ่ายขายและทีมงานฝ่ายการตลาด</h3>
                <p className="mt-1.5 text-xs text-[#6e746f] leading-relaxed">
                  นำเสนอโปรโมชันสินค้า ข้อมูลสเปกต่างๆ ในรูปแบบ Flipbook พรีเมียม ส่งต่อง่ายทาง LINE แชต หรือ LINE Official Account รวดเร็ว
                </p>
              </div>
            </div>

            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-6 backdrop-blur-md shadow-sm flex items-start gap-4">
              <span className="text-2xl mt-1">🏫</span>
              <div>
                <h3 className="text-base font-bold text-[#17221c]">สถาบันการศึกษาและโรงเรียน</h3>
                <p className="mt-1.5 text-xs text-[#6e746f] leading-relaxed">
                  จัดทำวารสารประชาสัมพันธ์โรงเรียน รายงานผลงานประจำปี E-Book หรือสมุดบันทึกภาพกิจกรรมของนักเรียน ให้น่าสนใจ เปิดอ่านแบบมีมิติ
                </p>
              </div>
            </div>

            <div className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-6 backdrop-blur-md shadow-sm flex items-start gap-4">
              <span className="text-2xl mt-1">☕</span>
              <div>
                <h3 className="text-base font-bold text-[#17221c]">ร้านอาหาร ร้านกาแฟ และแบรนด์บริการ</h3>
                <p className="mt-1.5 text-xs text-[#6e746f] leading-relaxed">
                  สร้างสรรค์เมนูอาหารดิจิทัล (Digital Menu) แผ่นพับแนะนำบริการ หรือคู่มือการดูแลรักษาสินค้า ให้สแกนหน้าร้านผ่าน QR Code ประหยัดเวลาพิมพ์กระดาษ
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FAQs Section */}
      <section className="py-16">
        <div className="mx-auto max-w-4xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center mb-12">
            <h2 className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">คำถามที่พบบ่อย (FAQs)</h2>
            <p className="mt-2 text-3xl font-medium tracking-tight text-[#17221c] sm:text-4xl">
              ข้อสงสัยและคำแนะนำการใช้งานเบื้องต้น
            </p>
          </div>

          <div className="space-y-6">
            {FAQS.map((faq, index) => (
              <div 
                key={index} 
                className="bg-white/80 border border-[#e2dfd5] rounded-3xl p-6 backdrop-blur-md shadow-sm"
              >
                <h3 className="text-base font-bold text-[#17221c] flex items-center gap-2">
                  <span className="text-[#9a7257] font-serif font-bold">Q.</span> {faq.question}
                </h3>
                <p className="mt-2 text-sm text-[#6e746f] pl-6 border-l border-[#d9d7cd] leading-relaxed">
                  {faq.answer}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 bg-[#243129] text-[#e8dcc7] border-t border-[#17221c] relative overflow-hidden">
        <div className="absolute right-[-10%] top-[-30%] w-[500px] h-[500px] rounded-full bg-[#d3b894]/10 blur-[100px] pointer-events-none" />
        <div className="mx-auto max-w-5xl px-6 text-center relative z-10">
          <h2 className="text-3xl font-medium tracking-tight sm:text-4xl">
            เริ่มแปลงเอกสาร PDF เป็น Flipbook ของคุณวันนี้
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-sm text-[#c4a77d]">
            แผงควบคุมระบบสำหรับสมาชิก อัปโหลด สร้าง และรับคิวอาร์โค้ดไปใช้แชร์ได้ทันที
          </p>
          <div className="mt-8 flex justify-center">
            <Link
              href="/dashboard"
              className="rounded-full bg-[#e8dcc7] px-8 py-3.5 text-sm font-bold text-[#243129] shadow-[0_4px_16px_rgba(232,220,199,0.2)] hover:bg-white active:scale-[0.98] transition-all cursor-pointer"
            >
              เริ่มสร้างแคตตาล็อก
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-8 bg-[#17221c] text-[#6e746f] text-xs border-t border-[#121b16]">
        <div className="mx-auto max-w-7xl px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <Image src="/pedebook-icon.png" alt="Pedebook Logo" width={24} height={24} className="rounded-lg opacity-80" />
            <span>&copy; {new Date().getFullYear()} Pedebook. All rights reserved.</span>
          </div>
          <div className="flex gap-4">
            <Link href="/dashboard" className="hover:text-white transition">เข้าสู่แดชบอร์ด</Link>
            <span className="text-neutral-700">|</span>
            <span className="text-neutral-500">Digital Flipbook & E-Catalog Generator</span>
          </div>
        </div>
      </footer>
    </main>
  );
}
