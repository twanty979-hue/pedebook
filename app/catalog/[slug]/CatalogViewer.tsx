'use client';

import dynamic from 'next/dynamic';

const EbookViewer = dynamic(() => import('../../components/EbookViewer'), {
  ssr: false,
  loading: () => (
    <div style={{ color: '#aaa', textAlign: 'center', padding: 80, letterSpacing: 4, textTransform: 'uppercase', fontSize: 13, background: '#1c1c1e', minHeight: '100vh' }}>
      กำลังเตรียมหน้ากระดาษครับนาย...
    </div>
  ),
});

interface CatalogViewerProps {
  slug: string;
  catalogId?: string;
  bgType?: string;
  bgValue?: string;
  isFloating?: boolean;
  adEnabled?: boolean;
  updatedAt?: string;
}

export default function CatalogViewer({
  slug,
  catalogId,
  bgType,
  bgValue,
  isFloating,
  adEnabled,
  updatedAt,
}: CatalogViewerProps) {
  const version = updatedAt ? new Date(updatedAt).getTime() : '1';

  return (
    <EbookViewer
      pdfUrl={`/api/pdf-proxy?slug=${encodeURIComponent(slug)}&v=${version}`}
      bgType={bgType || 'gradient'}
      bgValue={bgValue || 'auto'}
      isFloating={isFloating ?? false}
      slug={slug}
      catalogId={catalogId || slug}
      adEnabled={adEnabled ?? false}
    />
  );
}
