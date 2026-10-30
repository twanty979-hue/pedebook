import type { MetadataRoute } from 'next';
import { SEO_CONFIG } from './src/lib/seo';

export default function robots(): MetadataRoute.Robots {
  const siteUrl = SEO_CONFIG.siteUrl.replace(/\/$/, '');
  
  return {
    rules: [
      {
        userAgent: '*',
        allow: [
          '/',
          '/en',
          '/en/*',
          '/catalog/*',
          '/pricing',
        ],
        disallow: [
          '/api/',
          '/dashboard',
          '/dashboard/*',
          '/login',
          '/auth/',
          '/auth/*',
          '/admin',
          '/admin/*',
        ],
      },
      {
        userAgent: 'Googlebot',
        allow: '/',
        disallow: [
          '/api/',
          '/dashboard',
          '/dashboard/*',
          '/login',
          '/auth/',
        ],
      },
    ],
    sitemap: `${siteUrl}/sitemap.xml`,
    host: siteUrl,
  };
}
