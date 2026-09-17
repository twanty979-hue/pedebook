import type { MetadataRoute } from 'next';
import { SEO_CONFIG } from './src/lib/seo';
import { getIndexableCatalogs, type CatalogRecord } from './src/lib/catalogs';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = SEO_CONFIG.siteUrl.replace(/\/$/, '');
  let catalogs: CatalogRecord[] = [];
  const publicPages: MetadataRoute.Sitemap = [
    {
      url: `${siteUrl}/`,
      changeFrequency: 'weekly',
      priority: 1.0,
      alternates: {
        languages: {
          th: `${siteUrl}/`,
          en: `${siteUrl}/en`,
        },
      },
    },
    {
      url: `${siteUrl}/en`,
      changeFrequency: 'weekly',
      priority: 1.0,
      alternates: {
        languages: {
          th: `${siteUrl}/`,
          en: `${siteUrl}/en`,
        },
      },
    },
    ...['pdf-to-flipbook', 'online-catalog', 'ebook-online', 'digital-brochure'].map((path) => ({
      url: `${siteUrl}/en/${path}`,
      changeFrequency: 'monthly' as const,
      priority: 0.8,
      alternates: { languages: { en: `${siteUrl}/en/${path}` } },
    })),
  ];

  try {
    catalogs = await getIndexableCatalogs();
  } catch (error) {
    console.error('[SEO] Unable to load catalog URLs for sitemap:', error);
  }

  return [
    ...publicPages,
    ...catalogs.map((catalog) => ({
      url: `${siteUrl}/catalog/${catalog.slug}`,
      lastModified: catalog.updatedAt || catalog.lastModified,
      changeFrequency: 'monthly' as const,
      priority: 0.7,
    })),
  ];
}
