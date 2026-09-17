import type { Metadata } from 'next';
import EnglishSeoPage from '../../components/EnglishSeoPage';
import { englishMetadata } from '../../src/lib/english-seo';

export const metadata: Metadata = englishMetadata({
  path: '/en/ebook-online',
  title: 'Publish an E-book Online from PDF',
  description: 'Publish an e-book, magazine, report, or portfolio online from PDF. Give readers a simple link and a realistic page-turning experience.',
});

export default function EbookOnlinePage() {
  return (
    <EnglishSeoPage
      eyebrow="Online e-book publisher"
      title="Publish an e-book readers will want to"
      highlight="open"
      introduction="Whether you are sharing a magazine, guide, annual report, or portfolio, Pedebook gives your PDF a dedicated online reading experience that feels more like a publication than a download."
      benefits={[
        { title: 'A home for every publication', body: 'Give an e-book or report a stable browser link that is simple for readers to save and revisit.' },
        { title: 'More inviting than an attachment', body: 'Present long-form documents as a publication with an intuitive page-by-page reading experience.' },
        { title: 'A reader-friendly format', body: 'Let audiences choose their device while keeping the document available in a familiar web browser.' },
        { title: 'Easy to promote', body: 'Use the publication link and QR code in newsletters, event materials, websites, and social channels.' },
      ]}
      steps={[
        { title: 'Finish your publication', body: 'Export your manuscript, magazine, report, or portfolio as a polished PDF with a clear cover.' },
        { title: 'Upload and publish', body: 'Create an online edition in Pedebook and confirm the title and description readers should see.' },
        { title: 'Invite readers in', body: 'Share the link with your audience or add the QR code to a campaign, print piece, or presentation.' },
      ]}
      useCases={[
        { title: 'E-books and guides', body: 'Give subscribers and customers an enjoyable way to read educational content, guides, and lead magnets.' },
        { title: 'Digital magazines', body: 'Publish a visual issue that readers can open in a browser instead of downloading a large attachment.' },
        { title: 'Annual and impact reports', body: 'Make organization updates and performance reports easier for partners and stakeholders to access.' },
        { title: 'School publications', body: 'Share student work, graduation books, newsletters, and activity reports with families and communities.' },
      ]}
      faqs={[
        { question: 'Can I publish an e-book from PDF?', answer: 'Yes. A finished PDF can be uploaded and published as an online flipbook.' },
        { question: 'Does a reader need an account?', answer: 'No. A reader can open a publication through the shared link in a browser.' },
        { question: 'Can I use this for a magazine or report?', answer: 'Yes. Pedebook is suitable for e-books, magazines, portfolios, reports, and other multi-page publications.' },
        { question: 'How do I send readers to my e-book?', answer: 'Share its link directly, include it in a website or email, or publish its QR code in print and at events.' },
      ]}
    />
  );
}
