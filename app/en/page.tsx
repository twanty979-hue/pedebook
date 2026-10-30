import type { Metadata } from 'next';
import EnglishSeoPage from '../components/EnglishSeoPage';
import { englishMetadata } from '../src/lib/english-seo';

export const metadata: Metadata = englishMetadata({
  path: '/en',
  title: 'Free PDF to Flipbook Maker | 3D Online Catalog & E-Book Creator',
  description: 'Convert PDF to interactive 3D flipbook, online catalog, and digital brochure for free. Realistic page turning, instant link & QR code sharing worldwide.',
  includeThaiAlternate: true,
});

export default function EnglishHomePage() {
  return (
    <EnglishSeoPage
      eyebrow="100% Free Online 3D Flipbook Creator"
      title="Turn any PDF into an interactive 3D"
      highlight="flipbook"
      introduction="Pedebook is a free, modern digital publishing platform that transforms standard PDF files into stunning 3D flipbooks, online product catalogs, brochures, and e-books. Enjoy realistic page-turn physics, instant link & QR code sharing, and lightning-fast worldwide reading on mobile and desktop."
      benefits={[
        {
          title: '100% Free to Get Started',
          body: 'No credit card required. Upload documents up to 100MB+ for free. Large files are never blocked, making it the most generous flipbook tool on the web.',
        },
        {
          title: 'Realistic 3D Page-Flip Physics',
          body: 'Delight readers with natural page turns, authentic paper rustle sound, and smooth 60FPS fluid animations instead of static PDF attachments.',
        },
        {
          title: 'Instant Link & High-Res QR Code',
          body: 'Share your publication anywhere in one click: WhatsApp, Messenger, LINE, email campaigns, or print high-resolution QR codes for physical counters.',
        },
        {
          title: 'Lightning-Fast Global CDN Streaming',
          body: 'Powered by Cloudflare CDN across 300+ edge cities worldwide. Readers in America, Europe, Asia, and worldwide enjoy instant 0ms reading.',
        },
      ]}
      steps={[
        {
          title: '1. Sign In Instantly',
          body: 'Log in with one click via Google or email to access your personal dashboard workspace.',
        },
        {
          title: '2. Upload Your PDF Document',
          body: 'Drag and drop your sales catalog, product brochure, company profile, portfolio, magazine, or restaurant menu.',
        },
        {
          title: '3. Share Worldwide & Track Views',
          body: 'Get your unique 3D flipbook web link and QR code ready to send to clients, partners, or social media audiences immediately.',
        },
      ]}
      useCases={[
        {
          title: 'E-Commerce, Retailers & Brands',
          body: 'Transform seasonal collections, lookbooks, wholesale price lists, and brochures into interactive digital shopping experiences.',
        },
        {
          title: 'Sales & B2B Enterprises',
          body: 'Replace heavy email attachments with a sleek, trackable link that prospects can open instantly on phones and tablets during presentations.',
        },
        {
          title: 'Restaurants, Cafes & Hospitality',
          body: 'Display contact-free digital menus and wine lists via QR codes on dining tables and reception desks.',
        },
        {
          title: 'Educators, Creators & Students',
          body: 'Showcase student portfolios, annual reports, research papers, magazines, and e-books in an elegant, interactive book format.',
        },
      ]}
      faqs={[
        {
          question: 'Is Pedebook really free to use?',
          answer: 'Yes! Pedebook offers a free plan with 100MB storage. Even if your PDF file exceeds 100MB (e.g., 150MB+), our platform allows you to upload and publish it smoothly without blocking your document.',
        },
        {
          question: 'What is an interactive 3D flipbook?',
          answer: 'An interactive flipbook is a digital representation of a publication that feels like reading a physical book, complete with page turns, shadow effects, and responsive navigation on any screen.',
        },
        {
          question: 'Do my readers need to download an app or software?',
          answer: 'Not at all. Readers simply tap your link or scan your QR code to open the flipbook instantly in Chrome, Safari, Edge, Firefox, or any modern web browser.',
        },
        {
          question: 'Does it work smoothly on smartphones and tablets?',
          answer: 'Yes, Pedebook is mobile-first and fully responsive across iOS (iPhone/iPad), Android, Mac, and Windows computers.',
        },
        {
          question: 'How fast will my flipbook load for international readers?',
          answer: 'Our infrastructure uses Cloudflare Global CDN with HTTP Range streaming. Even for massive 100MB+ documents, page 1 opens in under 1 second worldwide.',
        },
      ]}
      showDemo
    />
  );
}
