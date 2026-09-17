import type { Metadata } from 'next';
import { SEO_CONFIG, absoluteUrl } from './seo';

type EnglishMetadataOptions = {
  path: string;
  title: string;
  description: string;
  includeThaiAlternate?: boolean;
};

export function englishMetadata({
  path,
  title,
  description,
  includeThaiAlternate = false,
}: EnglishMetadataOptions): Metadata {
  const canonical = absoluteUrl(path);

  return {
    title,
    description,
    alternates: {
      canonical,
      languages: includeThaiAlternate
        ? {
            th: absoluteUrl('/'),
            en: canonical,
            'x-default': absoluteUrl('/'),
          }
        : { en: canonical },
    },
    robots: {
      index: true,
      follow: true,
      googleBot: {
        index: true,
        follow: true,
        'max-image-preview': 'large',
        'max-snippet': -1,
      },
    },
    openGraph: {
      title,
      description,
      url: canonical,
      type: 'website',
      locale: 'en_US',
      alternateLocale: ['th_TH'],
      siteName: SEO_CONFIG.siteName,
      images: [{ url: absoluteUrl('/en/opengraph-image'), alt: 'Pedebook PDF to flipbook maker' }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [absoluteUrl('/en/opengraph-image')],
    },
  };
}
