import type { Metadata } from 'next';
import EnglishSeoPage from '../../components/EnglishSeoPage';
import { englishMetadata } from '../../src/lib/english-seo';

export const metadata: Metadata = englishMetadata({
  path: '/en/pdf-to-flipbook',
  title: 'Convert PDF to Flipbook Online for Free',
  description: 'Convert a PDF into a shareable online flipbook. Give brochures, catalogs, and documents a page-turning reading experience on any device.',
});

export default function PdfToFlipbookPage() {
  return (
    <EnglishSeoPage
      eyebrow="PDF to flipbook converter"
      title="Convert your PDF into a polished online"
      highlight="flipbook"
      introduction="A PDF is practical, but it is not always enjoyable to read or easy to share. Pedebook turns your finished PDF into an interactive publication with a dedicated browser link and QR code."
      benefits={[
        { title: 'Keep your original document', body: 'Start with the PDF you already designed and publish it in a reader-friendly format without rebuilding every page.' },
        { title: 'Make documents easier to open', body: 'Replace large file attachments with a single link that opens directly in a browser.' },
        { title: 'Create a premium first impression', body: 'A page-flip format makes a catalog, portfolio, or proposal feel more intentional when a recipient opens it.' },
        { title: 'Use it in your existing channels', body: 'Add the link to a website, email, social post, or message, and use the QR code in printed materials.' },
      ]}
      steps={[
        { title: 'Prepare your PDF', body: 'Use a clear cover, readable type, and complete information before publishing your document.' },
        { title: 'Upload to Pedebook', body: 'Add the PDF to your account and let Pedebook prepare the online reader.' },
        { title: 'Copy the publication link', body: 'Share the unique URL or QR code wherever your audience is most likely to see it.' },
      ]}
      useCases={[
        { title: 'Product brochures', body: 'Give each campaign brochure its own shareable destination instead of asking customers to download a file.' },
        { title: 'Company profiles', body: 'Send a business introduction that feels complete and is easy for prospects to open from a phone.' },
        { title: 'Creative portfolios', body: 'Present work in a sequence that is more immersive than a folder of image files.' },
        { title: 'Event materials', body: 'Publish schedules, programs, and sponsor materials for guests to access by scanning a QR code.' },
      ]}
      faqs={[
        { question: 'Can I convert an existing PDF?', answer: 'Yes. Pedebook is designed for documents that have already been prepared as PDFs.' },
        { question: 'Will the flipbook have its own link?', answer: 'Yes. Each published document has a dedicated link that you can share directly.' },
        { question: 'Can I add the QR code to printed material?', answer: 'Yes. The QR code can be placed on posters, packaging, business cards, or any offline material.' },
        { question: 'Is a PDF flipbook suitable for mobile readers?', answer: 'Yes. Readers can open the publication in a browser on a phone, tablet, or computer.' },
      ]}
    />
  );
}
