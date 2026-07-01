import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
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
    const formData = await request.formData();
    const file = formData.get('file');

    if (!(file instanceof File)) {
      return NextResponse.json({ error: 'ไม่พบไฟล์ PDF' }, { status: 400 });
    }

    const bucketName = (process.env.R2_BUCKET_NAME || '').trim();

    if (!r2Endpoint || !bucketName) {
      return NextResponse.json(
        { error: 'ตั้งค่า R2_ENDPOINT หรือ R2_BUCKET_NAME ไม่ครบ' },
        { status: 500 },
      );
    }

    const userId = (formData.get('userId') as string || 'anonymous').trim();
    const buffer = Buffer.from(await file.arrayBuffer());
    const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
    const fileName = `${Date.now()}-${safeName}`;
    const r2Key = `ebook/${userId}/${fileName}`;

    await r2Client.send(
      new PutObjectCommand({
        Bucket: bucketName,
        Key: r2Key,
        Body: buffer,
        ContentType: file.type || 'application/octet-stream',
      }),
    );

    const publicDomain = (process.env.R2_PUBLIC_DOMAIN || '')
      .trim()
      .replace(/\/+$/, '');

    return NextResponse.json({
      success: true,
      url: `${publicDomain}/${r2Key}`,
      key: r2Key,
      fileName: file.name,
    });
  } catch (error: unknown) {
    console.error('R2 Upload Error:', error);
    const message =
      error instanceof Error ? error.message : 'เกิดข้อผิดพลาดหลังบ้าน';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
