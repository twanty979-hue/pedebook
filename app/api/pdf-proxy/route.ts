import { NextRequest, NextResponse } from 'next/server';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { getCatalogBySlug } from '../../src/lib/catalogs';

export const dynamic = 'force-dynamic';
export const maxDuration = 120;

const r2Endpoint = (process.env.R2_ENDPOINT || '').trim().replace(/\/+$/, '');
const r2Client = new S3Client({
  region: 'auto',
  endpoint: r2Endpoint,
  credentials: {
    accessKeyId: (process.env.R2_ACCESS_KEY_ID || '').trim(),
    secretAccessKey: (process.env.R2_SECRET_ACCESS_KEY || '').trim(),
  },
  forcePathStyle: true,
});

// ระบบ RAM Cache ความเร็วสูงในหน่วยความจำเซิร์ฟเวอร์ (ตอบกลับ 0ms)
interface CachedPdf {
  buffer: Buffer;
  cachedAt: number;
}
const pdfMemoryCache = new Map<string, CachedPdf>();
const MAX_CACHE_ITEMS = 8;
const CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes

function getCachedPdf(key: string): Buffer | null {
  const item = pdfMemoryCache.get(key);
  if (!item) return null;
  if (Date.now() - item.cachedAt > CACHE_TTL_MS) {
    pdfMemoryCache.delete(key);
    return null;
  }
  return item.buffer;
}

function setCachedPdf(key: string, buffer: Buffer) {
  if (pdfMemoryCache.size >= MAX_CACHE_ITEMS) {
    const oldestKey = pdfMemoryCache.keys().next().value;
    if (oldestKey) pdfMemoryCache.delete(oldestKey);
  }
  pdfMemoryCache.set(key, { buffer, cachedAt: Date.now() });
}

export async function GET(req: NextRequest) {
  const slug = req.nextUrl.searchParams.get('slug');
  const directKey = req.nextUrl.searchParams.get('key');

  let r2Key = directKey || '';

  if (!r2Key && !slug) {
    return NextResponse.json({ error: 'ไม่พบค่า slug หรือ key' }, { status: 400 });
  }

  try {
    // 1. ค้นหาเอกสารจาก Supabase / Firestore ด้วย slug
    if (!r2Key && slug) {
      const catalog = await getCatalogBySlug(slug);

      if (!catalog) {
        return NextResponse.json({ error: 'ไม่พบแค็ตตาล็อกนี้ในระบบ' }, { status: 404 });
      }

      r2Key = catalog.r2Key || '';

      // หากไม่มี r2Key โดยตรง ให้ถอดรหัสจาก pdfUrl
      if (!r2Key && catalog.pdfUrl) {
        const publicDomain = (process.env.R2_PUBLIC_DOMAIN || '').trim().replace(/\/+$/, '');
        if (publicDomain && catalog.pdfUrl.includes(publicDomain)) {
          r2Key = catalog.pdfUrl.replace(`${publicDomain}/`, '').replace(/^\/+/, '');
        } else {
          try {
            const parsed = new URL(catalog.pdfUrl);
            r2Key = parsed.pathname.replace(/^\/+/, '');
          } catch {
            r2Key = catalog.pdfUrl.replace(/^\/+/, '');
          }
        }
      }
    }

    if (!r2Key) {
      return NextResponse.json({ error: 'ไม่พบรหัสอ้างอิงไฟล์ PDF ในฐานข้อมูล' }, { status: 400 });
    }

    try {
      r2Key = decodeURIComponent(r2Key);
    } catch {
      // fallback
    }

    // 2. ดึงไฟล์จาก RAM Cache หรือโหลดตรงจาก Cloudflare R2
    let pdfBuffer = getCachedPdf(r2Key);

    if (!pdfBuffer) {
      const bucketName = (process.env.R2_BUCKET_NAME || '').trim();
      const fullCommand = new GetObjectCommand({
        Bucket: bucketName,
        Key: r2Key,
      });

      const s3Response = await r2Client.send(fullCommand);
      if (!s3Response.Body) {
        return NextResponse.json({ error: 'ไม่พบข้อมูลไฟล์ PDF ในระบบ R2' }, { status: 404 });
      }

      const arrayBytes = await s3Response.Body.transformToByteArray();
      pdfBuffer = Buffer.from(arrayBytes);
      setCachedPdf(r2Key, pdfBuffer);
    }

    const totalLength = pdfBuffer.length;
    const rangeHeader = req.headers.get('range');

    const baseHeaders: Record<string, string> = {
      'Content-Type': 'application/pdf',
      'Accept-Ranges': 'bytes',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Expose-Headers': 'Accept-Ranges, Content-Range, Content-Length',
      'Cache-Control': 'public, max-age=86400, stale-while-revalidate=604800',
    };

    // 3. จัดการ HTTP Range Requests (ส่งเฉพาะชิ้นส่วนไบต์ที่ต้องการ ความเร็วสูงสุด)
    if (rangeHeader) {
      const match = rangeHeader.match(/bytes=(\d*)-(\d*)/);
      if (match) {
        let start = match[1] ? parseInt(match[1], 10) : 0;
        let end = match[2] ? parseInt(match[2], 10) : totalLength - 1;

        if (isNaN(start)) start = 0;
        if (isNaN(end) || end >= totalLength) end = totalLength - 1;
        if (start > end) start = 0;

        const chunk = pdfBuffer.subarray(start, end + 1);

        return new NextResponse(new Uint8Array(chunk), {
          status: 206,
          headers: {
            ...baseHeaders,
            'Content-Length': chunk.length.toString(),
            'Content-Range': `bytes ${start}-${end}/${totalLength}`,
          },
        });
      }
    }

    // 4. ส่งเอกสารแบบเต็ม (HTTP 200)
    return new NextResponse(new Uint8Array(pdfBuffer), {
      status: 200,
      headers: {
        ...baseHeaders,
        'Content-Length': totalLength.toString(),
      },
    });
  } catch (err: any) {
    console.error('PDF Proxy Fetch Error:', err);
    return NextResponse.json({ error: 'เกิดข้อผิดพลาดหลังบ้านในการดึงไฟล์ PDF: ' + err.message }, { status: 500 });
  }
}
