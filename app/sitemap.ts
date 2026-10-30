import type { MetadataRoute } from 'next';
import { SEO_CONFIG } from './src/lib/seo';
import { getIndexableCatalogs, type CatalogRecord } from './src/lib/catalogs';

export const dynamic = 'force-dynamic';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = SEO_CONFIG.siteUrl.replace(/\/$/, '');
  const now = new Date();

  // 1. หน้าหลักและหน้าระดับบนสุด (Top-level Core Landing Pages)
  const corePages: MetadataRoute.Sitemap = [
    {
      url: `${siteUrl}/`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 1.0,
      alternates: {
        languages: {
          th: `${siteUrl}/`,
          en: `${siteUrl}/en`,
          'x-default': `${siteUrl}/`,
        },
      },
    },
    {
      url: `${siteUrl}/en`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 1.0,
      alternates: {
        languages: {
          th: `${siteUrl}/`,
          en: `${siteUrl}/en`,
          'x-default': `${siteUrl}/`,
        },
      },
    },
    {
      url: `${siteUrl}/pricing`,
      lastModified: now,
      changeFrequency: 'weekly',
      priority: 0.85,
      alternates: {
        languages: {
          th: `${siteUrl}/pricing`,
          en: `${siteUrl}/pricing`,
        },
      },
    },
  ];

  // 2. หน้า Landing Pages ภาษาอังกฤษเจาะกลุ่มคีย์เวิร์ดระดับโลก (Global Keyword Landing Pages)
  const englishSubPages: MetadataRoute.Sitemap = [
    'pdf-to-flipbook',
    'online-catalog',
    'ebook-online',
    'digital-brochure',
  ].map((path) => ({
    url: `${siteUrl}/en/${path}`,
    lastModified: now,
    changeFrequency: 'weekly' as const,
    priority: 0.9,
    alternates: {
      languages: {
        en: `${siteUrl}/en/${path}`,
      },
    },
  }));

  // 3. ดึงแค็ตตาล็อกและสมุดดิจิทัลสาธารณะของผู้ใช้เพื่อทำ SEO รายเล่ม (Public Catalogs)
  let catalogs: CatalogRecord[] = [];
  try {
    catalogs = await getIndexableCatalogs();
  } catch (error) {
    console.error('[SEO] Unable to load catalog URLs for sitemap:', error);
  }

  const catalogPages: MetadataRoute.Sitemap = catalogs.map((catalog) => ({
    url: `${siteUrl}/catalog/${catalog.slug}`,
    lastModified: catalog.updatedAt ? new Date(catalog.updatedAt) : (catalog.lastModified ? new Date(catalog.lastModified) : now),
    changeFrequency: 'weekly' as const,
    priority: 0.8,
  }));

  return [...corePages, ...englishSubPages, ...catalogPages];
}
