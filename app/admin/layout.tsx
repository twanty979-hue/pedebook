import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'ระบบจัดการผู้ดูแลระบบ (Admin) | Pedebook',
  robots: {
    index: false,
    follow: false,
    noarchive: true,
    nocache: true,
  },
};

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
