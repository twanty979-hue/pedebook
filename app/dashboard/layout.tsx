import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'แผงควบคุม',
  robots: {
    index: false,
    follow: false,
    noarchive: true,
    nocache: true,
  },
};

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
