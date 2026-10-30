import { cache } from 'react';
import { supabaseAdmin } from './supabase/server';
import { isSupabaseConfigured } from './supabase/client';

export interface CatalogRecord {
  id: string;
  slug: string;
  fileName?: string;
  pdfUrl?: string;
  r2Key?: string;
  size?: number;
  lastModified?: string;
  updatedAt?: string;
  displayTitle?: string;
  seoDescription?: string;
  coverImage?: string;
  isPublic?: boolean;
  allowIndexing?: boolean;
  bgType?: string;
  bgValue?: string;
  isFloating?: boolean;
  adEnabled?: boolean;
}

export const getCatalogBySlug = cache(async (slug: string): Promise<CatalogRecord | null> => {
  if (isSupabaseConfigured()) {
    try {
      const { data, error } = await supabaseAdmin
        .from('catalogs')
        .select('*')
        .eq('slug', slug)
        .maybeSingle();

      if (data && !error) {
        return {
          id: data.id,
          slug: data.slug,
          fileName: data.file_name,
          pdfUrl: data.pdf_url,
          r2Key: data.storage_key,
          size: Number(data.file_size_bytes || 0),
          lastModified: data.created_at,
          updatedAt: data.updated_at,
          displayTitle: data.title,
          seoDescription: data.seo_description,
          coverImage: data.cover_image,
          bgType: data.bg_type,
          bgValue: data.bg_value,
          isFloating: data.is_floating,
          isPublic: data.is_public,
          allowIndexing: data.allow_indexing,
          adEnabled: data.ad_enabled,
        };
      }
    } catch (err) {
      console.warn('Supabase getCatalogBySlug error:', err);
    }
  }

  return null;
});

export const getIndexableCatalogs = cache(async (): Promise<CatalogRecord[]> => {
  const catalogs: CatalogRecord[] = [];

  if (isSupabaseConfigured()) {
    try {
      const { data, error } = await supabaseAdmin
        .from('catalogs')
        .select('*')
        .eq('is_public', true)
        .eq('allow_indexing', true);

      if (data && !error) {
        catalogs.push(
          ...data.map((d) => ({
            id: d.id,
            slug: d.slug,
            fileName: d.file_name,
            pdfUrl: d.pdf_url,
            r2Key: d.storage_key,
            size: Number(d.file_size_bytes || 0),
            lastModified: d.created_at,
            updatedAt: d.updated_at,
            displayTitle: d.title,
            seoDescription: d.seo_description,
            coverImage: d.cover_image,
            bgType: d.bg_type,
            bgValue: d.bg_value,
            isFloating: d.is_floating,
            isPublic: d.is_public,
            allowIndexing: d.allow_indexing,
            adEnabled: d.ad_enabled,
          }))
        );
      }
    } catch (err) {
      console.warn('Supabase getIndexableCatalogs error:', err);
    }
  }

  return catalogs;
});

export function catalogTitle(catalog: CatalogRecord): string {
  return catalog.displayTitle || catalog.fileName?.replace(/\.pdf$/i, '') || 'สมุดภาพและแค็ตตาล็อก';
}

export function catalogDescription(catalog: CatalogRecord): string {
  return (
    catalog.seoDescription ||
    `อ่าน ${catalogTitle(catalog)} ออนไลน์แบบ Flipbook 3 มิติ แชร์ลิงก์และ QR Code ได้ทันที`
  );
}
