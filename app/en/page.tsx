import type { Metadata } from 'next';
import EnglishSeoPage from '../components/EnglishSeoPage';
import { englishMetadata } from '../src/lib/english-seo';

export const metadata: Metadata = englishMetadata({
  path: '/en',
  title: 'Free PDF to Flipbook Maker',
  description: 'Turn PDFs into interactive flipbooks, online catalogs, brochures, and e-books. Share a mobile-friendly link and QR code in minutes.',
  includeThaiAlternate: true,
});

export default function EnglishHomePage() {
  return (
    <EnglishSeoPage
      eyebrow="Free online flipbook maker"
      title="Turn every PDF into an interactive"
      highlight="flipbook"
      introduction="Pedebook helps businesses, creators, and teams turn PDF documents into polished online catalogs, brochures, and e-books that are easy to share and read on any device."
      benefits={[
        { title: 'A natural page-flip experience', body: 'Present documents in a memorable format with a smooth, book-like reading experience instead of a plain attachment.' },
        { title: 'Share with one link or QR code', body: 'Send your publication in chat, add it to a campaign, or let visitors scan a QR code to open it immediately.' },
        { title: 'Designed for every screen', body: 'Readers can browse comfortably on phones, tablets, and desktop computers without installing an app.' },
        { title: 'Made for catalogs and more', body: 'Use the same simple workflow for sales catalogs, product brochures, portfolios, magazines, menus, and reports.' },
      ]}
      steps={[
        { title: 'Sign in to your workspace', body: 'Create an account to manage your publications in one place.' },
        { title: 'Upload your PDF', body: 'Choose a brochure, catalog, menu, portfolio, or any document that is ready to publish.' },
        { title: 'Publish and share', body: 'Get a dedicated reading link and QR code to share with customers, colleagues, or your audience.' },
      ]}
      useCases={[
        { title: 'Sales and marketing teams', body: 'Give prospects a polished product catalog or company profile that is easier to open and forward than a large PDF attachment.' },
        { title: 'Online stores and retailers', body: 'Turn seasonal collections, price lists, and lookbooks into a single mobile-ready link for social posts and messaging.' },
        { title: 'Schools and organizations', body: 'Publish annual reports, activity books, newsletters, and learning materials in a format that feels like a real publication.' },
        { title: 'Hospitality and local services', body: 'Share digital menus, service guides, and promotional brochures through a QR code at the point of service.' },
      ]}
      faqs={[
        { question: 'What is an online flipbook?', answer: 'An online flipbook is a web-based version of a document that readers can open in a browser and turn through like the pages of a book.' },
        { question: 'Can readers open a Pedebook publication on mobile?', answer: 'Yes. Published documents are designed to be read on phones, tablets, and desktop browsers.' },
        { question: 'Do I need to install an app?', answer: 'No. Readers simply open the shared link or scan the QR code in a web browser.' },
        { question: 'What can I publish?', answer: 'You can publish PDF catalogs, brochures, e-books, portfolios, menus, magazines, reports, and other presentation-ready documents.' },
      ]}
      showDemo
    />
  );
}
