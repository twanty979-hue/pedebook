import { ImageResponse } from 'next/og';

export const alt = 'Pedebook - แปลง PDF เป็น Flipbook ออนไลน์';
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = 'image/png';

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          background: 'linear-gradient(135deg, #17221c 0%, #243129 100%)',
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'white',
          padding: '60px',
          fontFamily: 'sans-serif',
          position: 'relative',
        }}
      >
        {/* Decorative background lights */}
        <div
          style={{
            position: 'absolute',
            top: '-10%',
            left: '-15%',
            width: '600px',
            height: '600px',
            borderRadius: '50%',
            backgroundColor: 'rgba(211, 184, 148, 0.08)',
          }}
        />
        <div
          style={{
            position: 'absolute',
            bottom: '-10%',
            right: '-10%',
            width: '500px',
            height: '500px',
            borderRadius: '50%',
            backgroundColor: 'rgba(36, 49, 41, 0.2)',
          }}
        />

        {/* Outer border decoration */}
        <div
          style={{
            position: 'absolute',
            inset: '30px',
            border: '2px solid rgba(226, 223, 213, 0.15)',
            borderRadius: '24px',
            pointerEvents: 'none',
          }}
        />

        {/* Content container */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            textAlign: 'center',
          }}
        >
          {/* Logo icon representation */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: '#243129',
              borderRadius: '24px',
              padding: '20px',
              border: '2px solid rgba(196, 167, 125, 0.3)',
              marginBottom: '24px',
            }}
          >
            {/* SVG Book icon */}
            <svg
              width="64"
              height="64"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#c4a77d"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>

          {/* Brand label */}
          <div
            style={{
              fontSize: '28px',
              fontWeight: 'bold',
              letterSpacing: '0.15em',
              color: '#c4a77d',
              textTransform: 'uppercase',
              marginBottom: '16px',
            }}
          >
            Pedebook
          </div>

          {/* Main Title */}
          <div
            style={{
              fontSize: '56px',
              fontWeight: 800,
              letterSpacing: '-0.02em',
              lineHeight: 1.1,
              color: '#ffffff',
              marginBottom: '20px',
              maxWidth: '800px',
            }}
          >
            แปลง PDF เป็น Flipbook ออนไลน์
          </div>

          {/* Description */}
          <div
            style={{
              fontSize: '24px',
              color: '#efe7d8',
              maxWidth: '700px',
              lineHeight: 1.5,
              fontWeight: 400,
            }}
          >
            สร้างแคตตาล็อก E-Book และโบรชัวร์ออนไลน์ เปิดอ่านได้แบบ 3D พลิกหน้าสมจริง แชร์ลิงก์และ QR Code ได้ทันที
          </div>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
