import Image from 'next/image';
import Link from 'next/link';
import NavbarClient from './NavbarClient';
import BookShelfClient from './BookShelfClient';
import { JsonLd } from '../src/lib/seo';

type Faq = {
  question: string;
  answer: string;
};

type EnglishSeoPageProps = {
  eyebrow: string;
  title: string;
  highlight: string;
  introduction: string;
  benefits: Array<{ title: string; body: string }>;
  steps: Array<{ title: string; body: string }>;
  useCases: Array<{ title: string; body: string }>;
  faqs: Faq[];
  showDemo?: boolean;
};

export default function EnglishSeoPage({
  eyebrow,
  title,
  highlight,
  introduction,
  benefits,
  steps,
  useCases,
  faqs,
  showDemo = false,
}: EnglishSeoPageProps) {
  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: faq.answer,
      },
    })),
  };

  return (
    <main lang="en" className="min-h-screen overflow-hidden bg-[#f6f4ee] font-sans text-[#17221c]">
      <JsonLd data={faqSchema} />
      <NavbarClient locale="en" />

      <section className="relative overflow-hidden px-5 py-14 text-center sm:py-20">
        <div className="absolute left-1/2 top-0 h-[420px] w-[420px] -translate-x-1/2 rounded-full bg-[#d3b894]/30 blur-[100px]" />
        <div className="relative mx-auto max-w-5xl">
          <div className="mx-auto mb-8 w-fit rounded-[28px] border border-[#e7dfd2] bg-white/90 px-4 py-2 shadow-[0_16px_40px_rgba(36,49,41,0.08)]">
            <Image
              src="/pedebook-logo-lockup.png"
              alt="Pedebook"
              width={360}
              height={108}
              priority
              className="h-auto w-[230px] mix-blend-multiply sm:w-[310px]"
            />
          </div>
          <p className="inline-flex rounded-full border border-[#d9d7cd] bg-white/70 px-4 py-2 text-xs font-bold uppercase tracking-[0.16em] text-[#755a47] shadow-sm">
            {eyebrow}
          </p>
          <h1 className="mx-auto mt-6 max-w-4xl text-4xl font-medium leading-[1.08] tracking-tight sm:text-6xl lg:text-7xl">
            {title} <span className="font-serif italic text-[#9a7257]">{highlight}</span>
          </h1>
          <p className="mx-auto mt-6 max-w-3xl text-lg leading-relaxed text-[#5f665f] sm:text-xl">
            {introduction}
          </p>
          <div className="mt-9 flex flex-wrap justify-center gap-3">
            <Link href="/login" className="rounded-full bg-[#243129] px-7 py-3.5 text-sm font-bold text-[#e8dcc7] shadow-[0_4px_16px_rgba(36,49,41,0.2)] transition hover:bg-[#314238]">
              Create your flipbook
            </Link>
            <Link href="/" hrefLang="th" className="rounded-full border border-[#b9ac9d] bg-white/70 px-7 py-3.5 text-sm font-bold text-[#4e594f] transition hover:bg-white">
              View Thai site
            </Link>
          </div>
          {showDemo && <BookShelfClient />}
        </div>
      </section>

      <section className="border-y border-[#e2dfd5] bg-white/65 px-6 py-16 sm:py-20">
        <div className="mx-auto max-w-6xl">
          <div className="mx-auto max-w-2xl text-center">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">Why Pedebook</p>
            <h2 className="mt-3 text-3xl font-medium tracking-tight sm:text-4xl">A more engaging way to share documents</h2>
          </div>
          <div className="mt-12 grid gap-5 sm:grid-cols-2">
            {benefits.map((benefit) => (
              <article key={benefit.title} className="rounded-3xl border border-[#e2dfd5] bg-white p-7 shadow-sm">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#243129] text-lg text-[#e8dcc7]">✓</span>
                <h3 className="mt-5 text-lg font-bold">{benefit.title}</h3>
                <p className="mt-2 leading-relaxed text-[#68706a]">{benefit.body}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="px-6 py-16 sm:py-20">
        <div className="mx-auto max-w-6xl">
          <div className="max-w-2xl">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">Simple workflow</p>
            <h2 className="mt-3 text-3xl font-medium tracking-tight sm:text-4xl">From PDF to shareable publication in three steps</h2>
          </div>
          <ol className="mt-12 grid gap-5 md:grid-cols-3">
            {steps.map((step, index) => (
              <li key={step.title} className="relative rounded-3xl border border-[#e2dfd5] bg-white/80 p-7">
                <span className="font-serif text-5xl text-[#d3b894]">0{index + 1}</span>
                <h3 className="mt-5 text-lg font-bold">{step.title}</h3>
                <p className="mt-2 leading-relaxed text-[#68706a]">{step.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="border-y border-[#e2dfd5] bg-[#efe7d8]/40 px-6 py-16 sm:py-20">
        <div className="mx-auto max-w-6xl">
          <div className="mx-auto max-w-2xl text-center">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">Built for real work</p>
            <h2 className="mt-3 text-3xl font-medium tracking-tight sm:text-4xl">Share the right document with the right audience</h2>
          </div>
          <div className="mt-12 grid gap-5 sm:grid-cols-2">
            {useCases.map((useCase) => (
              <article key={useCase.title} className="rounded-3xl border border-[#e2dfd5] bg-white/80 p-7">
                <h3 className="text-lg font-bold">{useCase.title}</h3>
                <p className="mt-2 leading-relaxed text-[#68706a]">{useCase.body}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="px-6 py-16 sm:py-20">
        <div className="mx-auto max-w-4xl">
          <p className="text-center text-xs font-bold uppercase tracking-[0.2em] text-[#9a7257]">Frequently asked questions</p>
          <h2 className="mt-3 text-center text-3xl font-medium tracking-tight sm:text-4xl">Everything you need to know before publishing</h2>
          <div className="mt-12 space-y-4">
            {faqs.map((faq) => (
              <article key={faq.question} className="rounded-2xl border border-[#e2dfd5] bg-white p-6">
                <h3 className="text-base font-bold">{faq.question}</h3>
                <p className="mt-2 leading-relaxed text-[#68706a]">{faq.answer}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-[#243129] px-6 py-16 text-center text-[#e8dcc7]">
        <h2 className="text-3xl font-medium tracking-tight sm:text-4xl">Ready to publish a better-looking document?</h2>
        <p className="mx-auto mt-4 max-w-2xl text-[#cfc1aa]">Upload your PDF, get a shareable link and QR code, and make it easy for anyone to read on any device.</p>
        <Link href="/login" className="mt-8 inline-flex rounded-full bg-[#e8dcc7] px-8 py-3.5 text-sm font-bold text-[#243129] transition hover:bg-white">
          Start for free
        </Link>
      </section>

      <footer className="bg-[#17221c] px-6 py-7 text-center text-xs text-[#a5aaa4]">
        <nav aria-label="English resources" className="mb-4 flex flex-wrap justify-center gap-x-5 gap-y-2 text-[#d8c9af]">
          <Link href="/en/pdf-to-flipbook">PDF to Flipbook</Link>
          <Link href="/en/online-catalog">Online Catalog</Link>
          <Link href="/en/ebook-online">Online E-book</Link>
          <Link href="/en/digital-brochure">Digital Brochure</Link>
        </nav>
        © {new Date().getFullYear()} Pedebook · Interactive Flipbooks and Online Catalogs
      </footer>
    </main>
  );
}
