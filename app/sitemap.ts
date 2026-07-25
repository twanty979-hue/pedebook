import type { MetadataRoute } from 'next';
import { SEO_CONFIG } from './src/lib/seo';

export default function sitemap(): MetadataRoute.Sitemap {
  const siteUrl = SEO_CONFIG.siteUrl.replace(/\/$/, '');

  return [
    {
      url: `${siteUrl}/`,
      changeFrequency: 'weekly',
      priority: 1.0,
    },
  ];
}
