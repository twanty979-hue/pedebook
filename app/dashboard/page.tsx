'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import { onAuthStateChanged, signOut, User } from 'firebase/auth';
import {
  collection,
  query,
  where,
  getDocs,
  addDoc,
  deleteDoc,
  updateDoc,
  doc,
  orderBy,
} from 'firebase/firestore';
import { QRCodeCanvas } from 'qrcode.react';
import { auth, db } from '../src/lib/firebase';

const BookCover = dynamic(() => import('../components/BookCover'), {
  ssr: false,
  loading: () => (
    <div className="flex flex-col items-center justify-center h-full w-full bg-[#243129] text-[#e8dcc7] p-2 text-center select-none">
      <span className="text-[9px] font-bold tracking-widest animate-pulse">โหลดปก...</span>
    </div>
  ),
});

interface CatalogItem {
  id: string;
  slug: string;
  fileName: string;
  pdfUrl: string;
  r2Key: string;
  size: number;
  lastModified: string;
  bgType?: string;
  bgValue?: string;
}

function formatSize(bytes: number) {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('th-TH', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);
  const [authLoading, setAuthLoading] = useState(true);

  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState<{ slug: string } | null>(null);
  const [catalogs, setCatalogs] = useState<CatalogItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState<string | null>(null);
  const [replacing, setReplacing] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const [qrModal, setQrModal] = useState<{ slug: string; fileName: string } | null>(null);
  const [uploadModalOpen, setUploadModalOpen] = useState(false);
  const [editModal, setEditModal] = useState<CatalogItem | null>(null);
  const [editName, setEditName] = useState('');
  const [editBgType, setEditBgType] = useState('gradient');
  const [editBgValue, setEditBgValue] = useState('auto');
  const [bgUploading, setBgUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  const replaceInputRef = useRef<{ [key: string]: HTMLInputElement | null }>({});
  const uploadInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  useEffect(() => {
    if (editModal) {
      setEditName(editModal.fileName);
      setEditBgType(editModal.bgType || 'gradient');
      setEditBgValue(editModal.bgValue || 'auto');
    }
  }, [editModal]);

  // 1. ตรวจสอบสิทธิ์และนำทาง
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      if (!currentUser) {
        router.push('/login');
      } else {
        setUser(currentUser);
        setAuthLoading(false);
      }
    });
    return () => unsubscribe();
  }, [router]);

  // 2. ดึงแค็ตตาล็อกแยกตามสิทธิ์ผู้ใช้จาก Firestore
  const fetchCatalogs = async (userId: string) => {
    setLoading(true);
    try {
      const catalogsRef = collection(db, 'catalogs');
      const q = query(
        catalogsRef,
        where('userId', '==', userId),
        orderBy('lastModified', 'desc')
      );
      const snapshot = await getDocs(q);
      const items: CatalogItem[] = snapshot.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<CatalogItem, 'id'>),
      }));
      setCatalogs(items);
    } catch (err) {
      console.error('Error fetching catalogs:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchCatalogs(user.uid);
    }
  }, [user]);

  // คำนวณปริมาณเนื้อหาในแดชบอร์ด
  const totalSize = catalogs.reduce((acc, curr) => acc + curr.size, 0);

  // ระบบอัปโหลดรูปภาพพื้นหลังของตนเองไปยัง R2
  const handleCustomBgUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f || !user) return;
    setBgUploading(true);

    try {
      const formData = new FormData();
      formData.append('file', f);
      formData.append('userId', user.uid);

      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (data.success) {
        setEditBgType('custom');
        setEditBgValue(data.url);
      } else {
        alert('อัปโหลดรูปภาพล้มเหลว: ' + data.error);
      }
    } catch (err) {
      console.error(err);
      alert('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ');
    } finally {
      setBgUploading(false);
    }
  };

  // ระบบบันทึกการตั้งค่าแค็ตตาล็อก (ชื่อ & ธีม)
  const handleSaveSettings = async () => {
    if (!editModal || !user) return;
    setSaving(true);

    try {
      const docRef = doc(db, 'catalogs', editModal.id);
      await updateDoc(docRef, {
        fileName: editName,
        bgType: editBgType,
        bgValue: editBgValue,
        lastModified: new Date().toISOString(),
      });

      setEditModal(null);
      fetchCatalogs(user.uid);
    } catch (err) {
      console.error(err);
      alert('บันทึกการตั้งค่าไม่สำเร็จครับ');
    } finally {
      setSaving(false);
    }
  };

  // 3. ระบบอัปโหลด R2 + บันทึก Firestore
  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file || !user) return;
    setUploading(true);
    setUploadResult(null);

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('userId', user.uid);

      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (!data.success) {
        alert('เกิดข้อผิดพลาดในการอัปโหลด: ' + data.error);
        return;
      }

      const slug = `${user.uid}-${Date.now()}-${file.name
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, '')}`;

      const catalogsRef = collection(db, 'catalogs');
      await addDoc(catalogsRef, {
        userId: user.uid,
        slug,
        fileName: file.name,
        pdfUrl: data.url,
        r2Key: data.key,
        size: file.size,
        lastModified: new Date().toISOString(),
        bgType: 'gradient',
        bgValue: 'auto',
      });

      setUploadResult({ slug });
      setFile(null);
      setUploadModalOpen(false);
      fetchCatalogs(user.uid);
    } catch (err) {
      console.error(err);
      alert('ระบบอัปโหลดมีปัญหาครับ');
    } finally {
      setUploading(false);
    }
  };

  // 4. ระบบเปลี่ยนไฟล์ PDF (ลบ R2 เก่า + อัปโหลดใหม่ + อัปเดต Firestore)
  const handleReplace = async (item: CatalogItem, newFile: File) => {
    if (!user) return;
    setReplacing(item.id);

    try {
      const formData = new FormData();
      formData.append('file', newFile);
      formData.append('userId', user.uid);

      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (!data.success) {
        alert('เปลี่ยนไฟล์ไม่สำเร็จ: ' + data.error);
        return;
      }

      await fetch('/api/delete-file', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: item.r2Key }),
      });

      const docRef = doc(db, 'catalogs', item.id);
      await updateDoc(docRef, {
        fileName: newFile.name,
        pdfUrl: data.url,
        r2Key: data.key,
        size: newFile.size,
        lastModified: new Date().toISOString(),
      });

      fetchCatalogs(user.uid);
    } catch (err) {
      console.error(err);
      alert('ระบบเปลี่ยนไฟล์มีปัญหาครับ');
    } finally {
      setReplacing(null);
    }
  };

  // 5. ระบบลบ Catalog
  const handleDelete = async (item: CatalogItem) => {
    if (!user) return;
    if (!confirm(`ลบแค็ตตาล็อก "${item.fileName.replace(/-/g, ' ')}" ใช่ไหมครับ? ผู้ใช้ภายนอกจะไม่สามารถเปิดอ่านลิงก์นี้ได้อีก`)) return;

    try {
      await deleteDoc(doc(db, 'catalogs', item.id));

      await fetch('/api/delete-file', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: item.r2Key }),
      });

      fetchCatalogs(user.uid);
    } catch (err) {
      console.error(err);
      alert('ลบไม่สำเร็จครับ');
    }
  };

  const copyLink = (slug: string) => {
    const link = `${window.location.origin}/catalog/${slug}`;
    navigator.clipboard.writeText(link);
    setCopied(slug);
    setTimeout(() => setCopied(null), 2000);
  };

  const downloadQR = (slug: string) => {
    const canvas = document.getElementById('qr-canvas') as HTMLCanvasElement;
    if (canvas) {
      const url = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.href = url;
      link.download = `QR-${slug}.png`;
      link.click();
    }
  };

  const handleLogout = async () => {
    if (confirm('คุณต้องการออกจากระบบใช่หรือไม่?')) {
      await signOut(auth);
      router.push('/login');
    }
  };

  const origin = typeof window !== 'undefined' ? window.location.origin : '';

  if (authLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#f6f4ee]">
        <div className="flex flex-col items-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#243129] border-t-transparent"></div>
          <p className="text-xs font-bold text-[#755a47] tracking-widest uppercase">กำลังตรวจสอบสิทธิ์...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f6f4ee] font-sans text-[#17221c] relative overflow-hidden pb-20">
      {/* เอฟเฟกต์แสงไฟเบลอ */}
      <div className="absolute top-[-10%] left-[-15%] w-[600px] h-[600px] rounded-full bg-[#d3b894]/20 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[500px] h-[500px] rounded-full bg-[#243129]/5 blur-[100px] pointer-events-none" />

      {/* ── Sticky Top Bar ── */}
      <nav className="sticky top-0 z-40 w-full bg-[#f6f4ee]/80 border-b border-[#e2dfd5] px-4 py-4 md:px-8 backdrop-blur-md">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <a href="/" className="flex items-center gap-2.5 group">
            <img
              src="/logo.png"
              alt="Pedebook Logo"
              className="h-9 w-9 rounded-xl object-contain shadow-md transition-transform group-hover:scale-105"
            />
            <div className="flex flex-col">
              <span className="font-bold tracking-tight text-base leading-tight text-[#17221c]">
                Pedebook
              </span>
              <span className="text-[9px] font-semibold text-[#9a7257] tracking-wide leading-none">
                Digital Flipbook Platform
              </span>
            </div>
          </a>

          {user && (
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2.5">
                {user.photoURL ? (
                  <img
                    src={user.photoURL}
                    alt="profile"
                    className="h-8 w-8 rounded-full border border-[#e2dfd5] object-cover"
                    referrerPolicy="no-referrer"
                  />
                ) : (
                  <span className="grid h-8 w-8 place-items-center rounded-full bg-[#243129] text-xs font-bold text-[#e8dcc7]">
                    {user.email?.charAt(0).toUpperCase()}
                  </span>
                )}
                <div className="hidden sm:flex flex-col text-left">
                  <span className="text-xs font-bold leading-tight">{user.displayName || 'ผู้ใช้ระบบ'}</span>
                  <span className="text-[10px] text-[#6e746f] leading-none">{user.email}</span>
                </div>
              </div>
              <button
                onClick={handleLogout}
                className="rounded-full border border-[#d9d7cd] px-4 py-1.5 text-xs font-bold text-[#755a47] hover:bg-[#243129] hover:text-[#e8dcc7] hover:border-[#243129] transition-all cursor-pointer"
              >
                ออกจากระบบ
              </button>
            </div>
          )}
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 py-8 md:px-8 relative z-10">
        {/* ── Welcome Heading & Stats ── */}
        <div className="mb-10 flex flex-col sm:flex-row sm:items-end justify-between gap-6">
          <div>
            <h1 className="text-3xl font-medium tracking-tight">
              แผงควบคุมระบบ{" "}
              <span className="font-serif italic text-[#9a7257]">
                แดชบอร์ด
              </span>
            </h1>
            <p className="mt-2 text-sm text-[#6e746f]">
              จัดการสมุดดิจิทัลและเผยแพร่แค็ตตาล็อกของคุณแบบแยกข้อมูลเฉพาะบัญชี
            </p>
          </div>

          <button
            onClick={() => setUploadModalOpen(true)}
            className="flex items-center justify-center h-12 w-12 rounded-2xl bg-[#243129] text-[#e8dcc7] shadow-md hover:bg-[#314238] hover:scale-105 active:scale-95 transition-all cursor-pointer shrink-0"
            title="เพิ่มแค็ตตาล็อกใหม่"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              {/* รูปเล่มสมุดกาง */}
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              {/* วงกลมสัญลักษณ์เครื่องหมายบวกซ้อนทับมุมบนขวา */}
              <circle cx="18" cy="6" r="4.5" fill="#243129" stroke="currentColor" strokeWidth="1.5" />
              <path d="M18 4.5v3M16.5 6h3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          </button>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-10">
          <div className="bg-white/70 border border-[#e2dfd5] rounded-2xl p-5 flex items-center justify-between shadow-sm hover:shadow-md transition">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-[#755a47]">แค็ตตาล็อกทั้งหมด</p>
              <h3 className="text-3xl font-bold mt-1 text-[#17221c]">{catalogs.length} เล่ม</h3>
            </div>
            <div className="text-[#243129] bg-[#243129]/5 p-3 rounded-xl">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
            </div>
          </div>
          <div className="bg-white/70 border border-[#e2dfd5] rounded-2xl p-5 flex items-center justify-between shadow-sm hover:shadow-md transition">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-[#755a47]">พื้นที่จัดเก็บรวม</p>
              <h3 className="text-3xl font-bold mt-1 text-[#17221c]">{formatSize(totalSize)}</h3>
            </div>
            <div className="text-[#9a7257] bg-[#9a7257]/5 p-3 rounded-xl">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
              </svg>
            </div>
          </div>
          <div className="bg-white/70 border border-[#e2dfd5] rounded-2xl p-5 flex items-center justify-between shadow-sm hover:shadow-md transition">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-[#755a47]">สิทธิ์การเข้าถึงระบบ</p>
              <h3 className="text-lg font-bold mt-2.5 text-[#166534] flex items-center gap-1.5">
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
                SaaS Multi-tenant
              </h3>
            </div>
            <div className="text-emerald-600 bg-emerald-50 p-3 rounded-xl">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.57-.598-3.75h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
              </svg>
            </div>
          </div>
        </div>

        {/* ── Catalog Grid (Full Width) ── */}
        <div className="mt-8">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-sm font-bold uppercase tracking-wider text-[#755a47]">
              สมุดภาพและ Catalog ที่มีอยู่
            </h2>
          </div>

          {loading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="bg-white border border-[#e2dfd5] rounded-2xl h-60 animate-pulse" />
              ))}
            </div>
          ) : catalogs.length === 0 ? (
            <div className="bg-white/50 border border-dashed border-[#d9d7cd] rounded-3xl p-12 text-center max-w-xl mx-auto">
              <svg className="w-12 h-12 text-[#d9d7cd] mx-auto mb-3" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 13.5h3.86a2.25 2.25 0 012.008 1.24l.885 1.77a2.25 2.25 0 002.007 1.24h1.98a2.25 2.25 0 002.007-1.24l.885-1.77a2.25 2.25 0 012.007-1.24h3.86m-18 0h18a2.25 2.25 0 012.25 2.25v3.5A2.25 2.25 0 0119.5 21h-15a2.25 2.25 0 01-2.25-2.25v-3.5a2.25 2.25 0 012.25-2.25zm18-9v8.25A2.25 2.25 0 0118 15H6a2.25 2.25 0 01-2.25-2.25V4.5A2.25 2.25 0 016 2.25h12a2.25 2.25 0 012.25 2.25z" />
              </svg>
              <p className="text-sm font-bold text-[#6e746f]">
                ยังไม่มีแค็ตตาล็อกในระบบนี้เลยครับ
              </p>
              <p className="text-xs text-[#6e746f] mt-1">
                คลิกปุ่มเครื่องหมายบวก (+) ด้านบน เพื่อเริ่มต้นอัปโหลดสมุดเล่มแรกของคุณได้เลย!
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              {catalogs.map((item) => (
                <div
                  key={item.id}
                  className="bg-white border border-[#e2dfd5] rounded-3xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between h-[390px]"
                >
                  {/* ส่วนแสดง Book 3D Mockup แบบลอยได้ (85% ของการ์ด) */}
                  <div className="h-[325px] bg-[#fbfaf8] border-b border-[#e2dfd5]/40 flex items-center justify-center p-4 relative overflow-hidden">
                    <div className="absolute inset-0 bg-radial-gradient from-transparent to-black/[0.01]" />
                    
                    {/* ตัวสมุด 3D เด้งลอยเมื่อชี้เมาส์ ขยายใหญ่เต็มๆ ตา */}
                    <div className="relative w-[204px] h-[270px] rounded-r-xl border-l-[4px] border-[#9a7257] bg-white shadow-[-8px_10px_20px_rgba(36,49,41,0.14)] overflow-hidden transition-all duration-300 hover:-translate-y-2.5 hover:shadow-[-12px_18px_28px_rgba(36,49,41,0.22)] hover:scale-[1.03]">
                      <BookCover slug={item.slug} fileName={item.fileName} width={200} />
                    </div>
                  </div>

                  {/* รายละเอียด และปุ่มสั่งการขนาดเล็ก (15% ของการ์ด) */}
                  <div className="h-[65px] px-4 py-2.5 bg-white flex items-center justify-between gap-3">
                    <div className="flex flex-col min-w-0">
                      <h3 className="text-xs font-bold text-[#17221c] truncate max-w-[100px] sm:max-w-[120px] leading-tight" title={item.fileName.replace(/-/g, ' ')}>
                        {item.fileName.replace(/-/g, ' ').replace(/\.pdf$/i, '')}
                      </h3>
                      <p className="text-[9px] text-[#6e746f] mt-0.5 font-mono leading-none">
                        {formatSize(item.size)}
                      </p>
                      <a
                        href={`/catalog/${item.slug}`}
                        target="_blank"
                        rel="noreferrer"
                        className="text-[9px] font-bold text-[#243129] hover:text-[#314238] flex items-center gap-0.5 mt-1 hover:underline cursor-pointer"
                      >
                        <span>เปิดอ่านสมุด</span>
                        <svg className="w-2.5 h-2.5 text-[#6e746f]" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V10.5M10.5 13.5L21 3M21 3h-5.25M21 3v5.25" />
                        </svg>
                      </a>
                    </div>

                    <div className="flex items-center gap-1 shrink-0">
                      {/* ปุ่ม QR Code ขนาดเล็ก */}
                      <button
                        onClick={() => setQrModal({ slug: item.slug, fileName: item.fileName })}
                        className="p-1 rounded-lg border border-[#e2dfd5] bg-white text-[#6e746f] hover:text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
                        title="QR Code"
                      >
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                          <rect x="3" y="3" width="7" height="7" rx="1" />
                          <rect x="14" y="3" width="7" height="7" rx="1" />
                          <rect x="14" y="14" width="7" height="7" rx="1" />
                          <rect x="3" y="14" width="7" height="7" rx="1" />
                        </svg>
                      </button>

                      {/* ปุ่มตั้งค่าธีมพื้นหลัง/ข้อมูล ขนาดเล็ก */}
                      <button
                        onClick={() => setEditModal(item)}
                        className="p-1 rounded-lg border border-[#e2dfd5] bg-white text-[#6e746f] hover:text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
                        title="ตั้งค่าแค็ตตาล็อก"
                      >
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.43l-1.003.828c-.293.241-.438.613-.43.992a7.723 7.723 0 010 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.43l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.28z" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                      </button>

                      {/* ปุ่มคัดลอกลิงก์ขนาดเล็ก */}
                      <button
                        onClick={() => copyLink(item.slug)}
                        className={`p-1 rounded-lg border transition cursor-pointer ${
                          copied === item.slug
                            ? 'border-emerald-200 bg-emerald-50 text-emerald-700'
                            : 'border-[#e2dfd5] bg-white text-[#6e746f] hover:text-[#17221c] hover:bg-neutral-50'
                        }`}
                        title="คัดลอกลิงก์"
                      >
                        {copied === item.slug ? (
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth="3" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                          </svg>
                        ) : (
                          <svg className="w-3 h-3" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
                          </svg>
                        )}
                      </button>

                      {/* ปุ่มอัปเดตไฟล์ขนาดเล็ก */}
                      <button
                        disabled={replacing === item.id}
                        onClick={() => replaceInputRef.current[item.id]?.click()}
                        className="p-1 rounded-lg border border-[#e2dfd5] bg-white text-[#6e746f] hover:text-[#b45309] hover:bg-[#fffbeb] transition cursor-pointer disabled:opacity-50"
                        title="เปลี่ยนไฟล์ PDF"
                      >
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
                        </svg>
                      </button>
                      <input
                        type="file"
                        accept="application/pdf"
                        style={{ display: 'none' }}
                        ref={(el) => {
                          replaceInputRef.current[item.id] = el;
                        }}
                        onChange={(e) => {
                          const f = e.target.files?.[0];
                          if (f) handleReplace(item, f);
                          e.target.value = '';
                        }}
                      />

                      {/* ปุ่มลบขนาดเล็ก */}
                      <button
                        className="p-1 rounded-lg border border-red-100 bg-white text-red-500 hover:text-red-700 hover:bg-red-50 transition cursor-pointer"
                        onClick={() => handleDelete(item)}
                        title="ลบ Catalog"
                      >
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      {/* ── Modal Upload ── */}
      {uploadModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4" onClick={() => setUploadModalOpen(false)}>
          <div className="bg-white rounded-3xl p-6 border border-[#e2dfd5] shadow-2xl relative max-w-md w-full" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setUploadModalOpen(false)}
              className="absolute top-4 right-4 text-[#6e746f] hover:text-[#17221c] transition"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            <h3 className="text-lg font-bold text-[#17221c] mb-1">เพิ่มแค็ตตาล็อก PDF</h3>
            <p className="text-xs text-[#6e746f] mb-4">เลือกไฟล์เอกสาร PDF เพื่อแปลงเป็นสมุดเปิดอ่านดิจิทัล</p>

            <form onSubmit={handleUpload} className="space-y-4">
              <div
                className={`border-2 border-dashed rounded-2xl p-6 text-center cursor-pointer transition-all duration-300 relative ${
                  dragOver ? 'border-[#243129] bg-[#efe7d8]/30' : 'border-[#d9d7cd] bg-[#fbfaf8]'
                }`}
                onDragOver={(e) => {
                  e.preventDefault();
                  setDragOver(true);
                }}
                onDragLeave={() => setDragOver(false)}
                onDrop={(e) => {
                  e.preventDefault();
                  setDragOver(false);
                  const f = e.dataTransfer.files[0];
                  if (f?.type === 'application/pdf') {
                    setFile(f);
                  }
                }}
              >
                <div className="mb-2">
                  {file ? (
                    <svg className="w-8 h-8 text-[#243129] mx-auto" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                    </svg>
                  ) : (
                    <svg className="w-8 h-8 text-[#9a7257] mx-auto" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 16.5V9.75m0 0l3 3m-3-3l-3 3M6.75 19.5a4.5 4.5 0 01-1.41-8.775 5.25 5.25 0 0110.233-2.33 3 3 0 013.758 3.848A3.752 3.752 0 0118 19.5H6.75z" />
                    </svg>
                  )}
                </div>
                <p className="text-xs font-bold text-[#17221c]">
                  {file ? file.name : 'ลากไฟล์ PDF มาวางที่นี่'}
                </p>
                <p className="text-[10px] text-[#6e746f] mt-1">
                  {file ? `${formatSize(file.size)}` : 'หรือคลิกเพื่อเลือกไฟล์ (รองรับ .pdf)'}
                </p>
                <input
                  ref={uploadInputRef}
                  type="file"
                  accept="application/pdf"
                  className="absolute inset-0 opacity-0 cursor-pointer w-full h-full"
                  onChange={(e) => {
                    setFile(e.target.files?.[0] ?? null);
                  }}
                />
              </div>

              <button
                type="submit"
                disabled={!file || uploading}
                className="w-full bg-[#243129] text-[#e8dcc7] py-3 rounded-xl font-bold text-xs uppercase tracking-wider shadow-md hover:bg-[#314238] active:scale-[0.98] transition disabled:opacity-50 disabled:pointer-events-none"
              >
                {uploading ? 'กำลังส่งขึ้นคลาวด์แฟร์...' : 'เริ่มกระบวนการอัปโหลด'}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* ── Floating Success Toast ── */}
      {uploadResult && (
        <div className="fixed bottom-6 right-6 z-50 bg-emerald-50 border border-emerald-200 rounded-2xl p-4 shadow-lg flex items-center gap-3 animate-slide-in">
          <div className="text-emerald-600 bg-emerald-100 p-2 rounded-xl">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75" />
            </svg>
          </div>
          <div>
            <p className="text-xs font-bold text-emerald-950">อัปโหลดสำเร็จแล้ว</p>
            <a href={`/catalog/${uploadResult.slug}`} target="_blank" rel="noreferrer" className="text-[10px] font-bold text-[#243129] underline hover:text-[#314238]">
              เปิดดูสมุดพลิกทันที →
            </a>
          </div>
          <button onClick={() => setUploadResult(null)} className="text-[#6e746f] hover:text-[#17221c] text-sm ml-4 font-bold">×</button>
        </div>
      )}

      {/* ── Modal QR Code (ดีไซน์ใหม่หรูหราสะดุดตา) ── */}
      {qrModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-md p-4 animate-fade-in" onClick={() => setQrModal(null)}>
          <div className="bg-white rounded-[32px] p-8 border border-[#e2dfd5] shadow-2xl relative max-w-sm w-full text-center flex flex-col items-center animate-scale-up" onClick={(e) => e.stopPropagation()}>
            
            {/* ปุ่มปิดมุมบนขวา */}
            <button
              onClick={() => setQrModal(null)}
              className="absolute top-5 right-5 text-[#6e746f] hover:text-[#17221c] hover:scale-105 active:scale-95 transition-all p-1.5 rounded-full hover:bg-neutral-100 cursor-pointer"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            {/* โลโก้แบรนด์สไตล์หรู */}
            <span className="grid h-10 w-10 place-items-center rounded-2xl bg-[#243129] shadow-md mb-3">
              <svg className="w-5 h-5 text-[#e8dcc7]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <rect x="3" y="3" width="7" height="7" rx="1" />
                <rect x="14" y="3" width="7" height="7" rx="1" />
                <rect x="14" y="14" width="7" height="7" rx="1" />
                <rect x="3" y="14" width="7" height="7" rx="1" />
              </svg>
            </span>

            <h3 className="text-base font-bold text-[#17221c]">คิวอาร์โค้ดสำหรับเข้าชม</h3>
            <p className="text-xs text-[#6e746f] mt-1.5 px-4 truncate max-w-full font-mono bg-[#efe7d8]/30 py-1.5 rounded-xl border border-[#efe7d8]">
              {qrModal.fileName.replace(/-/g, ' ').replace(/\.pdf$/i, '')}
            </p>

            {/* กรอบล้อม QR Code ที่ช่วยขับความเด่นชัด */}
            <div className="mt-6 p-5 bg-[#fbfaf8] border border-[#e2dfd5] rounded-3xl shadow-inner flex items-center justify-center relative group">
              <QRCodeCanvas
                value={`${origin}/catalog/${qrModal.slug}`}
                size={180}
                level={'H'}
                includeMargin={true}
                className="rounded-xl overflow-hidden transition-transform group-hover:scale-[1.02] duration-300"
              />
              <div style={{ display: 'none' }}>
                <QRCodeCanvas
                  id="qr-canvas"
                  value={`${origin}/catalog/${qrModal.slug}`}
                  size={1200}
                  level={'H'}
                  includeMargin={true}
                />
              </div>
            </div>

            {/* กลุ่มปุ่มปฏิบัติการ */}
            <div className="mt-6 w-full space-y-2.5">
              <button
                className="w-full py-3 bg-[#243129] hover:bg-[#314238] text-[#e8dcc7] font-bold text-xs rounded-xl flex items-center justify-center gap-2 shadow-md transition-all active:scale-[0.98] cursor-pointer"
                onClick={() => downloadQR(qrModal.slug)}
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
                </svg>
                ดาวน์โหลดภาพ QR Code (1200px คมชัดสูง)
              </button>

              <button
                className="w-full py-3 bg-neutral-100 hover:bg-neutral-200 text-[#17221c] font-bold text-xs rounded-xl flex items-center justify-center gap-2 transition-all active:scale-[0.98] cursor-pointer"
                onClick={() => {
                  const link = `${origin}/catalog/${qrModal.slug}`;
                  navigator.clipboard.writeText(link);
                  alert('คัดลอกลิงก์เรียบร้อยแล้วครับ');
                }}
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
                </svg>
                คัดลอกลิงก์แชร์
              </button>
            </div>
            
            <button
              onClick={() => setQrModal(null)}
              className="mt-5 text-[11px] font-bold text-[#6e746f] hover:text-[#17221c] transition cursor-pointer hover:underline"
            >
              ปิดหน้าต่าง
            </button>

          </div>
        </div>
      )}

      {/* ── Modal ตั้งค่าพื้นหลัง / แก้ไขข้อมูล ── */}
      {editModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in" onClick={() => setEditModal(null)}>
          <div className="bg-white rounded-3xl p-6 border border-[#e2dfd5] shadow-2xl relative max-w-md w-full animate-scale-up" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setEditModal(null)}
              className="absolute top-4 right-4 text-[#6e746f] hover:text-[#17221c] transition cursor-pointer"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            <h3 className="text-lg font-bold text-[#17221c] mb-1">ตั้งค่าธีม & รายละเอียด</h3>
            <p className="text-xs text-[#6e746f] mb-4">แก้ไขชื่อและเลือกธีมพื้นหลังหน้าสมุดเปิดอ่าน</p>

            <div className="space-y-4">
              {/* ชื่อหนังสือ */}
              <div>
                <label className="block text-xs font-bold text-[#17221c] mb-1.5">ชื่อแค็ตตาล็อก</label>
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-[#e2dfd5] focus:outline-none focus:border-[#243129] text-xs font-sans bg-[#fbfaf8]"
                />
              </div>

              {/* เลือกธีมพื้นหลัง */}
              <div>
                <label className="block text-xs font-bold text-[#17221c] mb-1.5">ธีมพื้นหลัง</label>
                <div className="grid grid-cols-3 gap-2">
                  {/* ไล่สีตามปกอัตโนมัติ */}
                  <button
                    onClick={() => {
                      setEditBgType('gradient');
                      setEditBgValue('auto');
                    }}
                    className={`p-2 rounded-xl border text-center transition-all cursor-pointer ${
                      editBgType === 'gradient' && editBgValue === 'auto'
                        ? 'border-[#243129] bg-[#243129]/5 font-bold'
                        : 'border-[#e2dfd5] hover:bg-neutral-50'
                    }`}
                  >
                    <div className="h-6 w-full rounded-md bg-gradient-to-tr from-amber-200 via-rose-200 to-emerald-200 border border-neutral-200 mb-1" />
                    <span className="text-[9px]">ไล่สีตามปก</span>
                  </button>

                  {/* ครีมสตูดิโอ */}
                  <button
                    onClick={() => {
                      setEditBgType('default');
                      setEditBgValue('cream');
                    }}
                    className={`p-2 rounded-xl border text-center transition-all cursor-pointer ${
                      editBgType === 'default' && editBgValue === 'cream'
                        ? 'border-[#243129] bg-[#243129]/5 font-bold'
                        : 'border-[#e2dfd5] hover:bg-neutral-50'
                    }`}
                  >
                    <div className="h-6 w-full rounded-md bg-gradient-to-tr from-[#f6f4ee] to-[#d8d4c7] border border-neutral-200 mb-1" />
                    <span className="text-[9px]">ครีมสตูดิโอ</span>
                  </button>

                  {/* ดินเผา */}
                  <button
                    onClick={() => {
                      setEditBgType('default');
                      setEditBgValue('warm');
                    }}
                    className={`p-2 rounded-xl border text-center transition-all cursor-pointer ${
                      editBgType === 'default' && editBgValue === 'warm'
                        ? 'border-[#243129] bg-[#243129]/5 font-bold'
                        : 'border-[#e2dfd5] hover:bg-neutral-50'
                    }`}
                  >
                    <div className="h-6 w-full rounded-md bg-gradient-to-tr from-[#dfc2ac] to-[#a7836b] border border-neutral-200 mb-1" />
                    <span className="text-[9px]">ดินเผา</span>
                  </button>

                  {/* เขียวป่า */}
                  <button
                    onClick={() => {
                      setEditBgType('default');
                      setEditBgValue('forest');
                    }}
                    className={`p-2 rounded-xl border text-center transition-all cursor-pointer ${
                      editBgType === 'default' && editBgValue === 'forest'
                        ? 'border-[#243129] bg-[#243129]/5 font-bold'
                        : 'border-[#e2dfd5] hover:bg-neutral-50'
                    }`}
                  >
                    <div className="h-6 w-full rounded-md bg-gradient-to-tr from-[#243129] to-[#121915] border border-neutral-200 mb-1" />
                    <span className="text-[9px]">เขียวป่า</span>
                  </button>

                  {/* หินชนวนดำ */}
                  <button
                    onClick={() => {
                      setEditBgType('default');
                      setEditBgValue('slate');
                    }}
                    className={`p-2 rounded-xl border text-center transition-all cursor-pointer ${
                      editBgType === 'default' && editBgValue === 'slate'
                        ? 'border-[#243129] bg-[#243129]/5 font-bold'
                        : 'border-[#e2dfd5] hover:bg-neutral-50'
                    }`}
                  >
                    <div className="h-6 w-full rounded-md bg-gradient-to-tr from-[#1e2022] to-[#111215] border border-neutral-200 mb-1" />
                    <span className="text-[9px]">หินชนวนดำ</span>
                  </button>

                  {/* ผ้าลินิน */}
                  <button
                    onClick={() => {
                      setEditBgType('default');
                      setEditBgValue('linen');
                    }}
                    className={`p-2 rounded-xl border text-center transition-all cursor-pointer ${
                      editBgType === 'default' && editBgValue === 'linen'
                        ? 'border-[#243129] bg-[#243129]/5 font-bold'
                        : 'border-[#e2dfd5] hover:bg-neutral-50'
                    }`}
                  >
                    <div className="h-6 w-full rounded-md bg-[#e2dfd5] border border-neutral-200 mb-1 flex items-center justify-center text-[7px] text-[#6e746f]">Pattern</div>
                    <span className="text-[9px]">ผ้าลินิน</span>
                  </button>
                </div>
              </div>

              {/* อัปโหลดรูปภาพพื้นหลังของตนเอง */}
              <div>
                <label className="block text-xs font-bold text-[#17221c] mb-1.5">หรือ อัปโหลดรูปพื้นหลังเอง (.jpg / .png)</label>
                <div className="flex items-center gap-3">
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleCustomBgUpload}
                    className="text-xs text-[#6e746f] file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-[#243129]/10 file:text-[#243129] hover:file:bg-[#243129]/20 file:cursor-pointer"
                  />
                  {bgUploading && <span className="text-[10px] text-[#6e746f] animate-pulse">กำลังอัปโหลด...</span>}
                </div>
                {editBgType === 'custom' && editBgValue && (
                  <p className="text-[10px] text-emerald-600 font-bold mt-1.5 truncate">
                    ✓ เลือกใช้รูปภาพสำเร็จ: {editBgValue}
                  </p>
                )}
              </div>

              {/* ปุ่มบันทึก */}
              <div className="pt-2">
                <button
                  onClick={handleSaveSettings}
                  disabled={bgUploading || saving}
                  className="w-full py-3 bg-[#243129] hover:bg-[#314238] disabled:opacity-50 text-[#e8dcc7] font-bold text-xs rounded-xl transition cursor-pointer flex items-center justify-center gap-2"
                >
                  {saving ? (
                    <>
                      <svg className="animate-spin h-4 w-4 text-[#e8dcc7]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      กำลังบันทึก...
                    </>
                  ) : (
                    'บันทึกการตั้งค่า'
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
