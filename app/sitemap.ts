import type { MetadataRoute } from 'next';
import { SEO_CONFIG } from './src/lib/seo';
import { getIndexableCatalogs, type CatalogRecord } from './src/lib/catalogs';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = SEO_CONFIG.siteUrl.replace(/\/$/, '');
  let catalogs: CatalogRecord[] = [];

  try {
    catalogs = await getIndexableCatalogs();
  } catch (error) {
    console.error('[SEO] Unable to load catalog URLs for sitemap:', error);
  }

  return [
    {
      url: `${siteUrl}/`,
      changeFrequency: 'weekly',
      priority: 1.0,
    },
    ...catalogs.map((catalog) => ({
      url: `${siteUrl}/catalog/${catalog.slug}`,
      lastModified: catalog.updatedAt || catalog.lastModified,
      changeFrequency: 'monthly' as const,
      priority: 0.7,
    })),
  ];
}
