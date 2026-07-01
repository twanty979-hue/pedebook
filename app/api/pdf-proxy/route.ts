import { NextRequest, NextResponse } from 'next/server';
import { getFirestore, collection, query, where, getDocs } from 'firebase/firestore';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { app } from '../../src/lib/firebase';

const db = getFirestore(app);

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

  if (!slug) {
    return NextResponse.json({ error: 'ไม่พบค่า slug' }, { status: 400 });
  }

  try {
    // 1. ค้นหาเอกสารจาก Firestore ด้วย slug เพื่อเอา r2Key
    const catalogsRef = collection(db, "catalogs");
    const q = query(catalogsRef, where("slug", "==", slug));
    const querySnapshot = await getDocs(q);

    if (querySnapshot.empty) {
      return NextResponse.json({ error: 'ไม่พบแค็ตตาล็อกนี้ในระบบ' }, { status: 404 });
    }

    const docData = querySnapshot.docs[0].data();
    let r2Key = docData.r2Key;

    // หากไม่มี r2Key บันทึกไว้ (เช่น เอกสารเก่า) ให้ถอดรหัสจาก pdfUrl แทน
    if (!r2Key && docData.pdfUrl) {
      const publicDomain = (process.env.R2_PUBLIC_DOMAIN || '').trim().replace(/\/+$/, '');
      r2Key = docData.pdfUrl.replace(`${publicDomain}/`, '');
    }

    if (!r2Key) {
      return NextResponse.json({ error: 'ไม่พบรหัสอ้างอิงไฟล์ PDF ในฐานข้อมูล' }, { status: 400 });
    }

    // 2. ดึงไฟล์ PDF จาก Cloudflare R2 โดยตรงผ่าน R2 Client (ใช้สิทธิ์ API Key ของหลังบ้าน)
    const bucketName = (process.env.R2_BUCKET_NAME || '').trim();
    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: r2Key,
    });

    const s3Response = await r2Client.send(command);

    if (!s3Response.Body) {
      return NextResponse.json({ error: 'ไม่พบข้อมูลไฟล์ PDF ในระบบ R2' }, { status: 404 });
    }

    // แปลงไฟล์เป็น Buffer เพื่อส่งข้อมูลแบบไบนารีสตรีม
    const arrayBytes = await s3Response.Body.transformToByteArray();
    const buffer = Buffer.from(arrayBytes);

    return new NextResponse(buffer, {
      headers: {
        'Content-Type': 'application/pdf',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
      },
    });
  } catch (err: any) {
    console.error('PDF Proxy Fetch Error:', err);
    return NextResponse.json({ error: 'เกิดข้อผิดพลาดหลังบ้านในการดึงไฟล์ PDF: ' + err.message }, { status: 500 });
  }
}
