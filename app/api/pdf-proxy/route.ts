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

    // ถอดรหัส URI ในกรณีที่มี encoding
    try {
      r2Key = decodeURIComponent(r2Key);
    } catch {
      // fallback to original
    }

    const bucketName = (process.env.R2_BUCKET_NAME || '').trim();
    const rangeHeader = req.headers.get('range');

    let s3Response;
    let isRangeResponse = false;

    // 2. ดึงไฟล์จาก Cloudflare R2 (รองรับ HTTP Range Request เพื่อความเร็วสูง)
    if (rangeHeader) {
      try {
        const rangeCommand = new GetObjectCommand({
          Bucket: bucketName,
          Key: r2Key,
          Range: rangeHeader,
        });
        s3Response = await r2Client.send(rangeCommand);
        isRangeResponse = true;
      } catch (rangeErr) {
        console.warn('Range request failed, falling back to full object fetch:', rangeErr);
      }
    }

    if (!s3Response) {
      const fullCommand = new GetObjectCommand({
        Bucket: bucketName,
        Key: r2Key,
      });
      s3Response = await r2Client.send(fullCommand);
      isRangeResponse = false;
    }

    if (!s3Response.Body) {
      return NextResponse.json({ error: 'ไม่พบข้อมูลไฟล์ PDF ในระบบ R2' }, { status: 404 });
    }

    const arrayBytes = await s3Response.Body.transformToByteArray();
    const buffer = Buffer.from(arrayBytes);

    const headers: Record<string, string> = {
      'Content-Type': 'application/pdf',
      'Content-Length': buffer.length.toString(),
      'Accept-Ranges': 'bytes',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'public, max-age=3600',
    };

    if (isRangeResponse && s3Response.ContentRange) {
      headers['Content-Range'] = s3Response.ContentRange;
      return new NextResponse(buffer, {
        status: 206,
        headers,
      });
    }

    return new NextResponse(buffer, {
      status: 200,
      headers,
    });
  } catch (err: any) {
    console.error('PDF Proxy Fetch Error:', err);
    return NextResponse.json({ error: 'เกิดข้อผิดพลาดหลังบ้านในการดึงไฟล์ PDF: ' + err.message }, { status: 500 });
  }
}
