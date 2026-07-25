import type { MetadataRoute } from 'next';
import { SEO_CONFIG } from './src/lib/seo';

export default function robots(): MetadataRoute.Robots {
  const siteUrl = SEO_CONFIG.siteUrl.replace(/\/$/, '');
  
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: [
        '/api/',
        '/dashboard/',
        '/login/',
      ],
    },
    sitemap: `${siteUrl}/sitemap.xml`,
    host: siteUrl,
  };
}
