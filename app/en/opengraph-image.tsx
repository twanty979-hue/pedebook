import { ImageResponse } from 'next/og';

export const alt = 'Pedebook — Turn PDFs into interactive flipbooks';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          background: 'linear-gradient(135deg, #17221c 0%, #314238 100%)',
          color: '#ffffff',
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          padding: '64px',
          fontFamily: 'sans-serif',
        }}
      >
        <div style={{ color: '#d3b894', fontSize: 32, fontWeight: 700, letterSpacing: '0.15em', textTransform: 'uppercase' }}>
          Pedebook
        </div>
        <div style={{ marginTop: 30, maxWidth: 920, fontSize: 70, lineHeight: 1.05, fontWeight: 800 }}>
          Turn PDFs into interactive flipbooks
        </div>
        <div style={{ marginTop: 28, maxWidth: 760, color: '#e8dcc7', fontSize: 30, lineHeight: 1.35 }}>
          Create online catalogs, brochures, and e-books that are ready to share.
        </div>
      </div>
    ),
    size,
  );
}
