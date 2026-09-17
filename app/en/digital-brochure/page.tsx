import type { Metadata } from 'next';
import EnglishSeoPage from '../../components/EnglishSeoPage';
import { englishMetadata } from '../../src/lib/english-seo';

export const metadata: Metadata = englishMetadata({
  path: '/en/digital-brochure',
  title: 'Create a Digital Brochure with QR Code',
  description: 'Turn a PDF brochure into a digital brochure that opens by link or QR code. Make your services, events, and offers easy to share on any device.',
});

export default function DigitalBrochurePage() {
  return (
    <EnglishSeoPage
      eyebrow="Digital brochure maker"
      title="Turn a brochure into an experience people can"
      highlight="share"
      introduction="A digital brochure gives your printed and online marketing a single destination. Publish a PDF with Pedebook, then direct people to it through a link or a QR code wherever they encounter your brand."
      benefits={[
        { title: 'Bridge print and digital', body: 'Add a QR code to posters, packaging, menus, and business cards so people can continue exploring on their phone.' },
        { title: 'Share campaigns in seconds', body: 'Send a brochure link in a chat or email without worrying about attachment size limits.' },
        { title: 'Keep your presentation polished', body: 'Show a complete offer, service list, or company introduction in a controlled visual sequence.' },
        { title: 'Reach readers anywhere', body: 'Let people access the brochure from a browser whether they are at a counter, a trade show, or at home.' },
      ]}
      steps={[
        { title: 'Create your brochure PDF', body: 'Include the key message, visual proof, contact details, and next step you want a reader to take.' },
        { title: 'Make it a digital brochure', body: 'Upload the PDF to Pedebook and receive a dedicated online version.' },
        { title: 'Use the link and QR code', body: 'Add them to the channels and physical touchpoints that bring people to your business.' },
      ]}
      useCases={[
        { title: 'Service businesses', body: 'Explain packages, processes, and contact options in one presentation that staff can send immediately.' },
        { title: 'Restaurants and cafés', body: 'Offer a digital menu or seasonal promotion that guests can open with a table or counter QR code.' },
        { title: 'Events and exhibitions', body: 'Give attendees a lightweight way to access programs, exhibitor details, and sponsorship information.' },
        { title: 'Property and travel', body: 'Package imagery, locations, features, and booking details into a brochure that prospects can browse on mobile.' },
      ]}
      faqs={[
        { question: 'What is a digital brochure?', answer: 'It is an online version of a brochure that readers access through a web link or QR code rather than a physical handout or file download.' },
        { question: 'Can I make a QR code for my brochure?', answer: 'Yes. Pedebook provides a QR code for each published document so readers can scan and open it quickly.' },
        { question: 'Can I still print my brochure?', answer: 'Yes. A digital brochure complements print: add its QR code to the printed version to give readers more convenient access.' },
        { question: 'Does it work for menus and service lists?', answer: 'Yes. PDF menus, service guides, and promotional brochures can all be published as online flipbooks.' },
      ]}
    />
  );
}
