import { cache } from 'react';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from './firebase';

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
  const snapshot = await getDocs(
    query(collection(db, 'catalogs'), where('slug', '==', slug)),
  );

  if (snapshot.empty) return null;

  const document = snapshot.docs[0];
  return {
    id: document.id,
    ...(document.data() as Omit<CatalogRecord, 'id'>),
  };
});

export const getIndexableCatalogs = cache(async (): Promise<CatalogRecord[]> => {
  const snapshot = await getDocs(
    query(collection(db, 'catalogs'), where('allowIndexing', '==', true)),
  );

  return snapshot.docs
    .map((document) => ({
      id: document.id,
      ...(document.data() as Omit<CatalogRecord, 'id'>),
    }))
    .filter((catalog) => catalog.isPublic !== false && catalog.allowIndexing === true);
});

export function catalogTitle(catalog: CatalogRecord): string {
  return catalog.displayTitle?.trim() || catalog.fileName?.replace(/\.pdf$/i, '').trim() || 'แค็ตตาล็อกออนไลน์';
}

export function catalogDescription(catalog: CatalogRecord): string {
  return catalog.seoDescription?.trim() || `อ่าน ${catalogTitle(catalog)} ออนไลน์แบบ Flipbook แชร์ลิงก์และ QR Code ได้ทันที`;
}
