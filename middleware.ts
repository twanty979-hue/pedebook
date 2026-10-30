import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 1. ข้าม Static files, API routes, Dashboard, และไฟล์ภายในระบบทั้งหมด
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/dashboard') ||
    pathname.startsWith('/login') ||
    pathname.startsWith('/auth') ||
    pathname.startsWith('/admin') ||
    pathname.startsWith('/catalog') ||
    pathname.includes('.') // เช่น favicon.ico, icon.png, sitemap.xml, robots.txt
  ) {
    return NextResponse.next();
  }

  // 2. ถ้าเป็น Search Engine Bot (Googlebot, Bingbot ฯลฯ) ไม่ต้องเปลี่ยนเส้นทาง ให้เก็บหน้าจริงตาม URL
  const userAgent = request.headers.get('user-agent') || '';
  const isBot = /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(userAgent);
  if (isBot) {
    return NextResponse.next();
  }

  // 3. ตรวจสอบการเลือกภาษาที่ผู้ใช้เลือกไว้เอง (Manual Cookie Preference)
  const savedLang = request.cookies.get('pedebook_lang')?.value;

  // 4. กรณีผู้ใช้เข้าสู่หน้าแรก Root `/`
  if (pathname === '/') {
    // ถ้าผู้ใช้เคยเลือกภาษาอังกฤษไว้ ให้พาไปหน้าภาษาอังกฤษ
    if (savedLang === 'en') {
      return NextResponse.redirect(new URL('/en', request.url));
    }

    // ถ้าผู้ใช้ไม่เคยเลือกภาษาไว้ล่วงหน้า (ผู้ใช้ใหม่จากทั่วโลก)
    if (!savedLang) {
      const country = request.headers.get('cf-ipcountry') || '';
      const acceptLang = request.headers.get('accept-language') || '';

      // ถ้าอยู่นอกประเทศไทย หรือเบราว์เซอร์ไม่ได้ตั้งเป็นภาษาไทย ให้เปิดหน้าภาษาอังกฤษให้อัตโนมัติ!
      const isThaiVisitor = country === 'TH' || acceptLang.toLowerCase().includes('th');
      if (!isThaiVisitor) {
        return NextResponse.redirect(new URL('/en', request.url));
      }
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/', '/en', '/en/:path*'],
};
