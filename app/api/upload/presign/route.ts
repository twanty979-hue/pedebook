import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { NextRequest, NextResponse } from 'next/server';

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

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { fileName, fileSize, contentType, userId } = body;

    if (!fileName) {
      return NextResponse.json({ error: 'ไม่พบชื่อไฟล์' }, { status: 400 });
    }

    const bucketName = (process.env.R2_BUCKET_NAME || '').trim();
    if (!r2Endpoint || !bucketName) {
      return NextResponse.json(
        { error: 'ยังไม่ได้ตั้งค่า R2_ENDPOINT หรือ R2_BUCKET_NAME ในระบบ' },
        { status: 500 }
      );
    }

    const safeUserId = (userId || 'anonymous').toString().trim();
    const safeName = fileName.replace(/[^a-zA-Z0-9.]/g, '_');
    const uniqueFileName = `${Date.now()}-${safeName}`;
    const r2Key = `ebook/${safeUserId}/${uniqueFileName}`;
    const fileContentType = contentType || 'application/pdf';

    // สร้าง Presigned URL สำหรับคำสั่ง PUT โดยตรงไปยัง Cloudflare R2
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: r2Key,
      ContentType: fileContentType,
    });

    // หมดอายุใน 1 ชั่วโมง (3600 วินาที)
    const presignedUrl = await getSignedUrl(r2Client, command, { expiresIn: 3600 });

    const publicDomain = (process.env.R2_PUBLIC_DOMAIN || '')
      .trim()
      .replace(/\/+$/, '');

    return NextResponse.json({
      success: true,
      presignedUrl,
      publicUrl: `${publicDomain}/${r2Key}`,
      key: r2Key,
      fileName,
    });
  } catch (error: unknown) {
    console.error('Presigned URL Error:', error);
    const message = error instanceof Error ? error.message : 'เกิดข้อผิดพลาดในการสร้างลิงก์อัปโหลด';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
