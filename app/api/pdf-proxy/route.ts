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

export function clearPdfMemoryCache(key?: string) {
  if (key) {
    pdfMemoryCache.delete(key);
  } else {
    pdfMemoryCache.clear();
  }
}

export async function GET(req: NextRequest) {
  const slug = req.nextUrl.searchParams.get('slug');
  const directKey = req.nextUrl.searchParams.get('key');

  let r2Key = directKey || '';

  if (!r2Key && !slug) {
    return NextResponse.json({ error: 'ไม่พบค่า slug หรือ key' }, { status: 400 });
  }

  try {
    // 1. ค้นหาเอกสารจาก Supabase ด้วย slug
    if (!r2Key && slug) {
      const catalog = await getCatalogBySlug(slug);

      if (!catalog) {
        return NextResponse.json(
          { error: 'ไม่พบแค็ตตาล็อกนี้ในระบบ (อาจถูกลบไปแล้ว)' },
          {
            status: 404,
            headers: {
              'Cache-Control': 'no-store, no-cache, must-revalidate',
            },
          }
        );
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

    // แคชถาวรระดับ Edge CDN และเบราว์เซอร์ 1 ปีเต็ม (31,536,000 วินาที) เร็วระดับ 0-20ms
    const baseHeaders: Record<string, string> = {
      'Content-Type': 'application/pdf',
      'Accept-Ranges': 'bytes',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Expose-Headers': 'Accept-Ranges, Content-Range, Content-Length, ETag',
      'Cache-Control': 'public, max-age=31536000, s-maxage=31536000, immutable',
      'CDN-Cache-Control': 'max-age=31536000',
      'Cloudflare-CDN-Cache-Control': 'max-age=31536000',
    };

    const rangeHeader = req.headers.get('range');
    const bucketName = (process.env.R2_BUCKET_NAME || '').trim();

    // 2. จัดการ HTTP Range Requests แบบสตรีมตรงจาก Cloudflare R2
    if (rangeHeader) {
      // 2.1 ตรวจสอบ RAM Cache ก่อน ถ้ามีส่งตรง 0ms
      const cachedBuf = getCachedPdf(r2Key);
      if (cachedBuf) {
        const totalLength = cachedBuf.length;
        const match = rangeHeader.match(/bytes=(\d*)-(\d*)/);
        if (match) {
          let start = match[1] ? parseInt(match[1], 10) : 0;
          let end = match[2] ? parseInt(match[2], 10) : totalLength - 1;
          if (isNaN(start)) start = 0;
          if (isNaN(end) || end >= totalLength) end = totalLength - 1;
          if (start > end) start = 0;

          const chunk = cachedBuf.subarray(start, end + 1);
          return new NextResponse(Buffer.from(chunk), {
            status: 206,
            headers: {
              ...baseHeaders,
              'Content-Length': chunk.length.toString(),
              'Content-Range': `bytes ${start}-${end}/${totalLength}`,
            },
          });
        }
      }

      // 2.2 ส่งคำขอ Range ตรงไปยัง R2 (รับเฉพาะชิ้นส่วนที่ขอใน 200ms โดยไม่ต้องโหลดทั้งเล่ม 150MB)
      try {
        const rangeCmd = new GetObjectCommand({
          Bucket: bucketName,
          Key: r2Key,
          Range: rangeHeader,
        });

        const s3Response = await r2Client.send(rangeCmd);
        if (!s3Response.Body) {
          return NextResponse.json({ error: 'ไม่พบข้อมูลไฟล์ PDF ในระบบ R2' }, { status: 404 });
        }

        const chunkBytes = await s3Response.Body.transformToByteArray();
        const contentRange = s3Response.ContentRange || '';
        const contentLength = (s3Response.ContentLength ?? chunkBytes.length).toString();

        return new NextResponse(Buffer.from(chunkBytes), {
          status: 206,
          headers: {
            ...baseHeaders,
            'Content-Length': contentLength,
            'Content-Range': contentRange,
            ETag: s3Response.ETag || `"${r2Key}"`,
          },
        });
      } catch (rangeErr: any) {
        console.warn('R2 direct range warning, fallback to full fetch:', rangeErr?.message);
      }
    }

    // 3. จัดการดาวน์โหลดทั้งเล่มแบบเต็ม (HTTP 200)
    let pdfBuffer = getCachedPdf(r2Key);

    if (!pdfBuffer) {
      const fullCommand = new GetObjectCommand({
        Bucket: bucketName,
        Key: r2Key,
      });

      const s3Response = await r2Client.send(fullCommand);
      if (!s3Response.Body) {
        return NextResponse.json({ error: 'ไม่พบข้อมูลไฟล์ PDF ในระบบ R2' }, { status: 404 });
      }

      // ถ้าไฟล์มีขนาดใหญ่กว่า 15MB ให้สตรีมเป็น WebStream ทันทีโดยไม่ต้องพักใน RAM ป้องกันเมมโมรี่เต็ม
      const s3Length = Number(s3Response.ContentLength || 0);
      if (s3Length > 15 * 1024 * 1024) {
        return new NextResponse(s3Response.Body.transformToWebStream() as any, {
          status: 200,
          headers: {
            ...baseHeaders,
            'Content-Length': s3Length.toString(),
            ETag: s3Response.ETag || `"${r2Key}"`,
          },
        });
      }

      const arrayBytes = await s3Response.Body.transformToByteArray();
      pdfBuffer = Buffer.from(arrayBytes);
      setCachedPdf(r2Key, pdfBuffer);
    }

    const totalLength = pdfBuffer.length;
    return new NextResponse(Buffer.from(pdfBuffer), {
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
