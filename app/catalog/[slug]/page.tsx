import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import CatalogViewer from './CatalogViewer';
import {
  absoluteUrl,
  generateDigitalDocumentJsonLd,
  JsonLd,
} from '../../src/lib/seo';
import {
  catalogDescription,
  catalogTitle,
  getCatalogBySlug,
} from '../../src/lib/catalogs';

export const dynamic = 'force-dynamic';

type CatalogPageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateMetadata({ params }: CatalogPageProps): Promise<Metadata> {
  const { slug } = await params;
  const catalog = await getCatalogBySlug(slug);

  if (!catalog) {
    return {
      title: 'ไม่พบแค็ตตาล็อก',
      robots: { index: false, follow: false },
    };
  }

  const title = catalogTitle(catalog);
  const description = catalogDescription(catalog);
  const canonical = absoluteUrl(`/catalog/${slug}`);
  const indexable = catalog.isPublic !== false && catalog.allowIndexing === true;
  const image = catalog.coverImage || absoluteUrl('/pedebook-logo-lockup.png');

  return {
    title,
    description,
    alternates: { canonical },
    robots: {
      index: indexable,
      follow: true,
      googleBot: { index: indexable, follow: true, 'max-image-preview': 'large' },
    },
    openGraph: {
      title,
      description,
      url: canonical,
      type: 'article',
      locale: 'th_TH',
      siteName: 'Pedebook',
      images: [{ url: image, alt: title }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [image],
    },
  };
}

export default async function CatalogPage({ params }: CatalogPageProps) {
  const { slug } = await params;
  const catalog = await getCatalogBySlug(slug);

  if (!catalog) notFound();

  const title = catalogTitle(catalog);
  const description = catalogDescription(catalog);
  const canonical = absoluteUrl(`/catalog/${slug}`);

  return (
    <>
      <section className="sr-only" aria-label={title}>
        <h1>{title}</h1>
        <p>{description}</p>
      </section>
      <JsonLd
        data={generateDigitalDocumentJsonLd({
          url: canonical,
          title,
          description,
          image: catalog.coverImage || absoluteUrl('/pedebook-logo-lockup.png'),
          dateModified: catalog.updatedAt || catalog.lastModified,
        })}
      />
      <CatalogViewer
        slug={slug}
        catalogId={catalog.id}
        bgType={catalog.bgType}
        bgValue={catalog.bgValue}
        isFloating={catalog.isFloating}
        adEnabled={Boolean(catalog.adEnabled)}
        updatedAt={catalog.updatedAt || catalog.lastModified}
      />
    </>
  );
}
