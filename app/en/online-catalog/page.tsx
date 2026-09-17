import type { Metadata } from 'next';
import EnglishSeoPage from '../../components/EnglishSeoPage';
import { englishMetadata } from '../../src/lib/english-seo';

export const metadata: Metadata = englishMetadata({
  path: '/en/online-catalog',
  title: 'Online Catalog Maker for Products and Collections',
  description: 'Create a mobile-friendly online catalog from your PDF. Share products, collections, and price lists with one link or a QR code.',
});

export default function OnlineCatalogPage() {
  return (
    <EnglishSeoPage
      eyebrow="Online catalog maker"
      title="Make your product catalog easier to"
      highlight="explore"
      introduction="Give every collection a destination that customers can open immediately. Pedebook lets you publish a product catalog online and share it through sales conversations, social posts, and QR codes."
      benefits={[
        { title: 'One link for the whole collection', body: 'Keep product photography, specifications, and ordering information together in one easy-to-share publication.' },
        { title: 'Ready for messaging and social', body: 'Customers can open the catalog directly from a link sent in a chat or added to a profile and post.' },
        { title: 'Better for in-person sales', body: 'Place a QR code at a counter, showroom, booth, or product display so visitors can browse independently.' },
        { title: 'Useful beyond e-commerce', body: 'Online catalogs also work for wholesale lines, real estate listings, interior collections, and service packages.' },
      ]}
      steps={[
        { title: 'Design your catalog PDF', body: 'Organize products into a clear sequence with strong images, prices, details, and contact information.' },
        { title: 'Publish it online', body: 'Upload the PDF to turn it into a browser-based catalog with its own shareable URL.' },
        { title: 'Put it where buyers are', body: 'Use the link in customer chats, social media, email signatures, and printed QR displays.' },
      ]}
      useCases={[
        { title: 'Retail and wholesale collections', body: 'Share a current collection with customers and stockists without repeatedly attaching a new PDF.' },
        { title: 'Furniture and interiors', body: 'Help buyers browse visual collections, finishes, and product specifications at their own pace.' },
        { title: 'Fashion and accessories', body: 'Turn a seasonal lookbook into a mobile-ready catalog for retailers, stylists, and customers.' },
        { title: 'B2B sales kits', body: 'Provide sales teams with one current catalog link that is simple to forward to a decision-maker.' },
      ]}
      faqs={[
        { question: 'Can I make a catalog from a PDF?', answer: 'Yes. Upload a finished PDF catalog and publish it as an online flipbook.' },
        { question: 'Can customers browse without downloading a file?', answer: 'Yes. The catalog opens in a browser from its shared link or QR code.' },
        { question: 'Can I use an online catalog for wholesale?', answer: 'Yes. It is useful for showing a complete product range to stockists and sales prospects.' },
        { question: 'Where should I share my catalog link?', answer: 'Use it in customer messages, social profiles, email campaigns, websites, and physical QR displays.' },
      ]}
    />
  );
}
