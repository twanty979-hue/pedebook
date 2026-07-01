import { DeleteObjectCommand, S3Client } from '@aws-sdk/client-s3';
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
    const { key } = await request.json();

    if (!key) {
      return NextResponse.json({ error: 'ไม่พบไฟล์ที่ต้องการลบ' }, { status: 400 });
    }

    const bucketName = (process.env.R2_BUCKET_NAME || '').trim();

    if (!r2Endpoint || !bucketName) {
      return NextResponse.json(
        { error: 'ตั้งค่า R2_ENDPOINT หรือ R2_BUCKET_NAME ไม่ครบ' },
        { status: 500 },
      );
    }

    await r2Client.send(
      new DeleteObjectCommand({
        Bucket: bucketName,
        Key: key,
      }),
    );

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    console.error('R2 Delete Error:', error);
    const message =
      error instanceof Error ? error.message : 'เกิดข้อผิดพลาดในการลบไฟล์';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
