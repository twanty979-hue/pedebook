'use client';

import React, { useState, useEffect, useMemo, useRef } from 'react';
import dynamic from 'next/dynamic';
import Link from 'next/link';
import { QRCodeCanvas } from 'qrcode.react';
import { supabase, isSupabaseConfigured } from '../src/lib/supabase/client';
import {
  isAdminEmail,
  verifyAdminPin,
  getAllUserProfiles,
  UserProfileRecord,
  syncUserProfile,
} from '../src/lib/user-tracking';

export interface AdminUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

const BookCover = dynamic(() => import('../components/BookCover'), {
  ssr: false,
  loading: () => (
    <div className="flex flex-col items-center justify-center h-full w-full bg-[#243129] text-[#e8dcc7] p-2 text-center select-none">
      <span className="text-[9px] font-bold tracking-widest animate-pulse">โหลดปก...</span>
    </div>
  ),
});

interface CatalogAdminItem {
  id: string;
  slug: string;
  fileName: string;
  pdfUrl?: string;
  r2Key?: string;
  size?: number;
  lastModified?: string;
  updatedAt?: string;
  userId?: string;
  userEmail?: string;
  userName?: string;
  userPhoto?: string;
  displayTitle?: string;
  seoDescription?: string;
  isPublic?: boolean;
  allowIndexing?: boolean;
  bgType?: string;
  bgValue?: string;
  isFloating?: boolean;
  docType?: string;
}

interface UserSummary {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  lastActiveAt?: string;
  createdAt?: string;
  totalUploads: number;
  totalSizeBytes: number;
  customAlias?: string;
}

function formatSize(bytes?: number): string {
  if (!bytes || bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function formatDate(iso?: string): string {
  if (!iso) return '-';
  try {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    return d.toLocaleDateString('th-TH', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return iso;
  }
}

export default function AdminPage() {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [isAuthorized, setIsAuthorized] = useState(false);
  const [pinInput, setPinInput] = useState('');
  const [pinError, setPinError] = useState('');

  // Login form for unauthenticated admins
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [loginLoading, setLoginLoading] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);

  // Data
  const [catalogs, setCatalogs] = useState<CatalogAdminItem[]>([]);
  const [userProfiles, setUserProfiles] = useState<Map<string, UserProfileRecord>>(new Map());
  const [dataLoading, setDataLoading] = useState(false);
  const [dataError, setDataError] = useState<string | null>(null);

  // User custom notes / aliases (saved in localStorage)
  const [userAliases, setUserAliases] = useState<Record<string, string>>(() => {
    if (typeof window !== 'undefined') {
      try {
        const saved = localStorage.getItem('pedebook_admin_user_aliases');
        return saved ? JSON.parse(saved) : {};
      } catch (e) {
        console.error(e);
      }
    }
    return {};
  });
  const [editingAliasUid, setEditingAliasUid] = useState<string | null>(null);
  const [aliasInputValue, setAliasInputValue] = useState('');

  // Active view tab: 'catalogs' | 'users' | 'overview'
  const [activeTab, setActiveTab] = useState<'catalogs' | 'users' | 'overview'>('catalogs');

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUserFilter, setSelectedUserFilter] = useState<string>('all');
  const [visibilityFilter, setVisibilityFilter] = useState<'all' | 'public' | 'private'>('all');
  const [sortBy, setSortBy] = useState<'newest' | 'oldest' | 'size-desc' | 'size-asc'>('newest');

  // Modals & Actions
  const [copiedSlug, setCopiedSlug] = useState<string | null>(null);
  const [qrModal, setQrModal] = useState<{ slug: string; fileName: string } | null>(null);
  const [previewModal, setPreviewModal] = useState<{ slug: string; title: string } | null>(null);
  const [deletingItem, setDeletingItem] = useState<CatalogAdminItem | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [updatingVisibilityId, setUpdatingVisibilityId] = useState<string | null>(null);

  // QR canvas ref for downloading
  const qrCanvasRef = useRef<HTMLDivElement>(null);

  // Save alias helper
  const handleSaveAlias = (uid: string) => {
    const updated = { ...userAliases, [uid]: aliasInputValue.trim() };
    setUserAliases(updated);
    try {
      localStorage.setItem('pedebook_admin_user_aliases', JSON.stringify(updated));
    } catch (e) {
      console.error(e);
    }
    setEditingAliasUid(null);
  };

  // Auth observer
  useEffect(() => {
    let isMounted = true;

    async function checkAuth() {
      if (isSupabaseConfigured()) {
        try {
          const {
            data: { session },
          } = await supabase.auth.getSession();
          if (session?.user && isMounted) {
            const adminUser: AdminUser = {
              uid: session.user.id,
              email: session.user.email || null,
              displayName:
                session.user.user_metadata?.full_name ||
                session.user.email?.split('@')[0] ||
                'Admin',
              photoURL: session.user.user_metadata?.avatar_url || null,
            };
            setUser(adminUser);
            setAuthLoading(false);

            if (isAdminEmail(adminUser.email)) {
              setIsAuthorized(true);
            } else {
              const sessionUnlocked = sessionStorage.getItem('pedebook_admin_unlocked');
              if (sessionUnlocked === 'true') {
                setIsAuthorized(true);
              }
            }
            return;
          }
        } catch (e) {
          console.warn('Supabase session check note:', e);
        }
      }

      if (isMounted) {
        setUser(null);
        setAuthLoading(false);
        const sessionUnlocked = sessionStorage.getItem('pedebook_admin_unlocked');
        if (sessionUnlocked === 'true') {
          setIsAuthorized(true);
        } else {
          setIsAuthorized(false);
        }
      }
    }

    checkAuth();

    let sbSub: { unsubscribe: () => void } | undefined;
    if (isSupabaseConfigured()) {
      const { data } = supabase.auth.onAuthStateChange((_event, session) => {
        if (!isMounted) return;
        if (session?.user) {
          const adminUser: AdminUser = {
            uid: session.user.id,
            email: session.user.email || null,
            displayName:
              session.user.user_metadata?.full_name ||
              session.user.email?.split('@')[0] ||
              'Admin',
            photoURL: session.user.user_metadata?.avatar_url || null,
          };
          setUser(adminUser);
          if (isAdminEmail(adminUser.email)) {
            setIsAuthorized(true);
          }
        } else {
          setUser(null);
          setIsAuthorized(false);
        }
        setAuthLoading(false);
      });
      sbSub = data.subscription;
    }

    return () => {
      isMounted = false;
      if (sbSub) sbSub.unsubscribe();
    };
  }, []);

  // Fetch all catalogs and user profiles from Supabase
  const fetchData = async () => {
    setDataLoading(true);
    setDataError(null);
    try {
      // 1. Fetch catalogs from Supabase REST API
      const res = await fetch('/api/v1/catalogs?all=true');
      const json = await res.json();
      const items: CatalogAdminItem[] = [];

      if (json.success && Array.isArray(json.catalogs)) {
        json.catalogs.forEach((c: any) => {
          items.push({
            id: c.id,
            slug: c.slug,
            fileName: c.file_name,
            pdfUrl: c.pdf_url,
            r2Key: c.storage_key,
            size: Number(c.file_size_bytes || 0),
            lastModified: c.created_at,
            updatedAt: c.updated_at,
            userId: c.user_id,
            displayTitle: c.title,
            seoDescription: c.seo_description,
            isPublic: c.is_public,
            allowIndexing: c.allow_indexing,
            bgType: c.bg_type,
            bgValue: c.bg_value,
            isFloating: c.is_floating,
          });
        });
      }

      setCatalogs(items);

      // 2. Fetch user profiles from Supabase
      const profiles = await getAllUserProfiles();
      setUserProfiles(profiles);
    } catch (err: unknown) {
      console.error('Error fetching admin data:', err);
      const msg = err instanceof Error ? err.message : 'ไม่สามารถดึงข้อมูลได้';
      setDataError(msg);
    } finally {
      setDataLoading(false);
    }
  };

  useEffect(() => {
    if (!isAuthorized) return;
    let active = true;

    Promise.resolve().then(() => {
      if (active) {
        fetchData();
      }
    });

    return () => {
      active = false;
    };
  }, [isAuthorized]);

  // Handle Admin PIN submission
  const handlePinSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (verifyAdminPin(pinInput)) {
      setIsAuthorized(true);
      sessionStorage.setItem('pedebook_admin_unlocked', 'true');
      setPinError('');
    } else {
      setPinError('รหัสผ่านแอดมิน (PIN) ไม่ถูกต้องครับ กรุณาลองใหม่อีกครั้ง');
    }
  };

  // Handle Admin Email Login
  const handleAdminEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginLoading(true);
    setLoginError(null);
    try {
      const { data, error: sbErr } = await supabase.auth.signInWithPassword({
        email: loginEmail.trim(),
        password: loginPassword,
      });
      if (sbErr) throw sbErr;
      if (data.user) {
        syncUserProfile({
          uid: data.user.id,
          email: data.user.email,
          displayName:
            data.user.user_metadata?.full_name || data.user.email?.split('@')[0],
          photoURL: data.user.user_metadata?.avatar_url,
        });
      }
    } catch (err: unknown) {
      console.error(err);
      const msg = err instanceof Error ? err.message : 'เข้าสู่ระบบไม่สำเร็จ';
      setLoginError(msg);
    } finally {
      setLoginLoading(false);
    }
  };

  // Handle Google Admin Login
  const handleAdminGoogleLogin = async () => {
    setLoginLoading(true);
    setLoginError(null);
    try {
      const { error: sbErr } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: typeof window !== 'undefined' ? window.location.href : undefined,
        },
      });
      if (sbErr) throw sbErr;
    } catch (err: unknown) {
      console.error(err);
      setLoginError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
      setLoginLoading(false);
    }
  };

  const handleLogout = async () => {
    sessionStorage.removeItem('pedebook_admin_unlocked');
    await supabase.auth.signOut();
    setUser(null);
    setIsAuthorized(false);
  };

  // Aggregate User Summaries ("ใครมาใช้บ้าง")
  const userSummaries: UserSummary[] = useMemo(() => {
    const map = new Map<string, UserSummary>();

    // 1. Initialize from tracked user profiles
    userProfiles.forEach((profile, uid) => {
      map.set(uid, {
        uid,
        email: profile.email || 'ไม่ระบุอีเมล',
        displayName: profile.displayName || profile.email?.split('@')[0] || 'ผู้ใช้ระบบ',
        photoURL: profile.photoURL || undefined,
        lastActiveAt: profile.lastActiveAt,
        createdAt: profile.createdAt,
        totalUploads: 0,
        totalSizeBytes: 0,
        customAlias: userAliases[uid] || '',
      });
    });

    // 2. Aggregate from catalogs uploads
    catalogs.forEach((item) => {
      const uid = item.userId || 'anonymous';
      let summary = map.get(uid);

      if (!summary) {
        // Create entry from catalog data if not yet in profile list
        summary = {
          uid,
          email: item.userEmail || (uid === 'anonymous' ? 'ไม่ระบุผู้ใช้' : `ผู้ใช้ (${uid.slice(0, 8)}...)`),
          displayName: item.userName || (uid === 'anonymous' ? 'ผู้ใช้นิรนาม' : `UID: ${uid.slice(0, 8)}`),
          photoURL: item.userPhoto,
          lastActiveAt: item.lastModified || item.updatedAt,
          totalUploads: 0,
          totalSizeBytes: 0,
          customAlias: userAliases[uid] || '',
        };
        map.set(uid, summary);
      }

      summary.totalUploads += 1;
      summary.totalSizeBytes += item.size || 0;

      // Update email/name if missing
      if (item.userEmail && (!summary.email || summary.email.startsWith('ผู้ใช้ ('))) {
        summary.email = item.userEmail;
      }
      if (item.userName && (!summary.displayName || summary.displayName.startsWith('UID:'))) {
        summary.displayName = item.userName;
      }

      // Update latest activity timestamp if catalog is newer
      if (item.lastModified && (!summary.lastActiveAt || new Date(item.lastModified) > new Date(summary.lastActiveAt))) {
        summary.lastActiveAt = item.lastModified;
      }
    });

    return Array.from(map.values()).sort((a, b) => {
      // Sort by uploads desc, then last active
      if (b.totalUploads !== a.totalUploads) {
        return b.totalUploads - a.totalUploads;
      }
      return (new Date(b.lastActiveAt || 0).getTime()) - (new Date(a.lastActiveAt || 0).getTime());
    });
  }, [catalogs, userProfiles, userAliases]);

  // Overall Statistics
  const stats = useMemo(() => {
    const totalUsers = userSummaries.length;
    const totalCatalogs = catalogs.length;
    const totalSizeBytes = catalogs.reduce((sum, item) => sum + (item.size || 0), 0);
    const publicCatalogs = catalogs.filter((item) => item.isPublic !== false).length;
    const privateCatalogs = totalCatalogs - publicCatalogs;

    return {
      totalUsers,
      totalCatalogs,
      totalSizeBytes,
      publicCatalogs,
      privateCatalogs,
    };
  }, [catalogs, userSummaries]);

  // Filtered & Sorted Catalogs List ("อัพอะไรไปบ้าง")
  const filteredCatalogs = useMemo(() => {
    return catalogs
      .filter((item) => {
        // User filter
        if (selectedUserFilter !== 'all') {
          if ((item.userId || 'anonymous') !== selectedUserFilter) return false;
        }

        // Visibility filter
        if (visibilityFilter === 'public' && item.isPublic === false) return false;
        if (visibilityFilter === 'private' && item.isPublic !== false) return false;

        // Search query
        if (searchQuery.trim()) {
          const q = searchQuery.toLowerCase();
          const matchName = (item.fileName || '').toLowerCase().includes(q);
          const matchTitle = (item.displayTitle || '').toLowerCase().includes(q);
          const matchSlug = (item.slug || '').toLowerCase().includes(q);
          const matchEmail = (item.userEmail || '').toLowerCase().includes(q);
          const matchUid = (item.userId || '').toLowerCase().includes(q);
          const matchAlias = (userAliases[item.userId || ''] || '').toLowerCase().includes(q);
          if (!matchName && !matchTitle && !matchSlug && !matchEmail && !matchUid && !matchAlias) {
            return false;
          }
        }

        return true;
      })
      .sort((a, b) => {
        if (sortBy === 'newest') {
          return new Date(b.lastModified || b.updatedAt || 0).getTime() - new Date(a.lastModified || a.updatedAt || 0).getTime();
        }
        if (sortBy === 'oldest') {
          return new Date(a.lastModified || a.updatedAt || 0).getTime() - new Date(b.lastModified || b.updatedAt || 0).getTime();
        }
        if (sortBy === 'size-desc') {
          return (b.size || 0) - (a.size || 0);
        }
        if (sortBy === 'size-asc') {
          return (a.size || 0) - (b.size || 0);
        }
        return 0;
      });
  }, [catalogs, selectedUserFilter, visibilityFilter, searchQuery, sortBy, userAliases]);

  // Copy Link Helper
  const copyExampleLink = (slug: string) => {
    const origin = typeof window !== 'undefined' ? window.location.origin : 'https://www.pedebook.com';
    const link = `${origin}/catalog/${slug}`;
    navigator.clipboard.writeText(link);
    setCopiedSlug(slug);
    setTimeout(() => setCopiedSlug(null), 2500);
  };

  // Download QR
  const downloadQrCode = (slug: string) => {
    const canvas = qrCanvasRef.current?.querySelector('canvas') as HTMLCanvasElement | null;
    if (canvas) {
      const url = canvas.toDataURL('image/png');
      const a = document.createElement('a');
      a.href = url;
      a.download = `QR-Pedebook-${slug}.png`;
      a.click();
    }
  };

  // Toggle Public / Private
  const handleToggleVisibility = async (item: CatalogAdminItem) => {
    setUpdatingVisibilityId(item.id);
    const newStatus = item.isPublic === false;
    try {
      await fetch(`/api/v1/catalogs/${item.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isPublic: newStatus }),
      });
      setCatalogs((prev) =>
        prev.map((c) => (c.id === item.id ? { ...c, isPublic: newStatus } : c))
      );
    } catch (err) {
      console.error('Error toggling visibility:', err);
      alert('เปลี่ยนสถานะไม่สำเร็จครับ');
    } finally {
      setUpdatingVisibilityId(null);
    }
  };

  // Delete Catalog (calls /api/v1/catalogs/[id] with DELETE)
  const handleDeleteCatalog = async () => {
    if (!deletingItem) return;
    setIsDeleting(true);
    try {
      await fetch(`/api/v1/catalogs/${deletingItem.id}`, {
        method: 'DELETE',
      });

      setCatalogs((prev) => prev.filter((c) => c.id !== deletingItem.id));
      setDeletingItem(null);
    } catch (err) {
      console.error('Error deleting catalog:', err);
      alert('ลบแค็ตตาล็อกไม่สำเร็จครับ');
    } finally {
      setIsDeleting(false);
    }
  };

  // ────────────────────────────────────────────
  // RENDER 1: Auth Loading Screen
  // ────────────────────────────────────────────
  if (authLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#f6f4ee]">
        <div className="flex flex-col items-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#243129] border-t-transparent" />
          <p className="text-xs font-bold tracking-widest text-[#755a47] uppercase">
            กำลังตรวจสอบสิทธิ์แอดมิน...
          </p>
        </div>
      </div>
    );
  }

  // ────────────────────────────────────────────
  // RENDER 2: Not Logged In Screen
  // ────────────────────────────────────────────
  if (!user) {
    return (
      <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#f6f4ee] p-4 font-sans text-[#17221c]">
        <div className="absolute left-1/2 top-1/2 h-[450px] w-[450px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#d3b894]/25 blur-[90px]" />
        <div className="relative z-10 w-full max-w-md rounded-3xl border border-[#e2dfd5] bg-white/90 p-8 shadow-[0_20px_50px_rgba(36,49,41,0.08)] backdrop-blur-md">
          <div className="mb-6 flex flex-col items-center justify-center gap-2">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#243129] text-[#e8dcc7] shadow-md">
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-[#17221c]">
              Pedebook <span className="font-serif italic text-[#9a7257]">Admin Center</span>
            </h1>
            <p className="text-xs text-[#6e746f] text-center">
              กรุณาเข้าสู่ระบบด้วยบัญชีแอดมินเพื่อตรวจสอบข้อมูลผู้ใช้งานและไฟล์ที่อัปโหลด
            </p>
          </div>

          <button
            type="button"
            onClick={handleAdminGoogleLogin}
            disabled={loginLoading}
            className="mb-4 flex w-full items-center justify-center gap-3 rounded-xl border border-[#d9d7cd] bg-white px-4 py-3 text-sm font-semibold text-[#17221c] shadow-sm transition hover:bg-neutral-50 active:scale-[0.98] disabled:opacity-50 cursor-pointer"
          >
            <svg className="h-5 w-5" viewBox="0 0 24 24">
              <path fill="#EA4335" d="M12 5.04c1.66 0 3.2.57 4.38 1.69l3.27-3.27C17.67 1.47 14.98 1 12 1 7.35 1 3.39 3.65 1.5 7.5l3.92 3.04c.92-2.76 3.51-4.5 6.58-4.5z" />
              <path fill="#4285F4" d="M23.49 12.27c0-.81-.07-1.59-.2-2.34H12v4.58h6.48c-.28 1.48-1.12 2.74-2.38 3.58l3.7 2.87c2.16-2 3.69-4.94 3.69-8.69z" />
              <path fill="#FBBC05" d="M5.42 14.96c-.24-.72-.38-1.49-.38-2.28s.14-1.56.38-2.28L1.5 7.36c-.8 1.6-1.25 3.4-1.25 5.3 0 1.9.45 3.7 1.25 5.3l3.92-3z" />
              <path fill="#34A853" d="M12 23c3.24 0 5.97-1.07 7.96-2.91l-3.7-2.87c-1.03.69-2.35 1.1-4.26 1.1-3.07 0-5.66-1.74-6.58-4.5L1.5 16.86C3.39 20.71 7.35 23 12 23z" />
            </svg>
            <span>เข้าสู่ระบบด้วย Google</span>
          </button>

          <div className="relative my-4 flex items-center justify-center">
            <span className="absolute inset-x-0 border-t border-[#e2dfd5]" />
            <span className="relative bg-white px-3 text-xs font-semibold uppercase tracking-wider text-[#755a47]">
              หรือเข้าด้วยอีเมล
            </span>
          </div>

          <form onSubmit={handleAdminEmailLogin} className="space-y-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#755a47] mb-1">
                อีเมล
              </label>
              <input
                type="email"
                value={loginEmail}
                onChange={(e) => setLoginEmail(e.target.value)}
                placeholder="admin@email.com"
                className="w-full rounded-xl border border-[#d9d7cd] bg-white px-3.5 py-2 text-sm text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257]"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#755a47] mb-1">
                รหัสผ่าน
              </label>
              <input
                type="password"
                value={loginPassword}
                onChange={(e) => setLoginPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full rounded-xl border border-[#d9d7cd] bg-white px-3.5 py-2 text-sm text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257]"
                required
              />
            </div>

            {loginError && (
              <div className="rounded-xl bg-red-50 border border-red-200 p-2.5 text-xs text-red-600">
                ⚠️ {loginError}
              </div>
            )}

            <button
              type="submit"
              disabled={loginLoading}
              className="w-full rounded-xl bg-[#243129] py-2.5 text-sm font-bold text-[#e8dcc7] shadow-sm transition hover:bg-[#314238] active:scale-[0.98] disabled:opacity-50 cursor-pointer"
            >
              {loginLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบแอดมิน'}
            </button>
          </form>

          <div className="mt-6 text-center">
            <Link href="/" className="text-xs font-semibold text-[#755a47] hover:underline">
              ← กลับสู่หน้าหลัก Pedebook
            </Link>
          </div>
        </div>
      </div>
    );
  }

  // ────────────────────────────────────────────
  // RENDER 3: PIN Verification Gate (Fallback)
  // ────────────────────────────────────────────
  if (!isAuthorized) {
    return (
      <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#f6f4ee] p-4 font-sans text-[#17221c]">
        <div className="absolute left-1/2 top-1/2 h-[400px] w-[400px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#d3b894]/25 blur-[90px]" />
        <div className="relative z-10 w-full max-w-sm rounded-3xl border border-[#e2dfd5] bg-white/90 p-8 shadow-[0_20px_50px_rgba(36,49,41,0.08)] backdrop-blur-md">
          <div className="mb-6 flex flex-col items-center justify-center text-center">
            <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-[#243129] text-[#e8dcc7] shadow-md">
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            <h2 className="text-xl font-bold tracking-tight text-[#17221c]">
              ยืนยันรหัสผ่านแอดมิน
            </h2>
            <p className="mt-1 text-xs text-[#6e746f]">
              บัญชี: <span className="font-semibold text-[#17221c]">{user.email}</span>
            </p>
            <p className="mt-0.5 text-[11px] text-[#9a7257]">
              กรุณากรอกรหัส PIN ผู้ดูแลระบบ (ค่าเริ่มต้น: <code className="bg-neutral-100 px-1 py-0.5 rounded">admin1234</code>)
            </p>
          </div>

          <form onSubmit={handlePinSubmit} className="space-y-4">
            <div>
              <input
                type="password"
                value={pinInput}
                onChange={(e) => setPinInput(e.target.value)}
                placeholder="กรอกรหัส PIN แอดมิน..."
                className="w-full rounded-xl border border-[#d9d7cd] bg-white px-4 py-2.5 text-center text-lg font-bold tracking-widest text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257]"
                autoFocus
                required
              />
            </div>

            {pinError && (
              <div className="rounded-xl bg-red-50 border border-red-200 p-2.5 text-center text-xs text-red-600">
                ⚠️ {pinError}
              </div>
            )}

            <button
              type="submit"
              className="w-full rounded-xl bg-[#243129] py-2.5 text-sm font-bold text-[#e8dcc7] shadow-sm transition hover:bg-[#314238] active:scale-[0.98] cursor-pointer"
            >
              ปลดล็อกหน้าแอดมิน
            </button>
          </form>

          <div className="mt-5 flex items-center justify-between text-xs text-[#755a47]">
            <Link href="/dashboard" className="hover:underline">
              ← กลับไปแดชบอร์ด
            </Link>
            <button onClick={handleLogout} className="hover:underline cursor-pointer">
              สลับบัญชี
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ────────────────────────────────────────────
  // RENDER 4: Full Admin Dashboard
  // ────────────────────────────────────────────
  const siteOrigin = typeof window !== 'undefined' ? window.location.origin : 'https://www.pedebook.com';

  return (
    <div className="min-h-screen bg-[#f6f4ee] font-sans text-[#17221c] relative overflow-x-hidden pb-24">
      {/* Background glow effects */}
      <div className="absolute top-[-10%] left-[-10%] w-[600px] h-[600px] rounded-full bg-[#d3b894]/20 blur-[130px] pointer-events-none" />
      <div className="absolute top-[40%] right-[-10%] w-[550px] h-[550px] rounded-full bg-[#243129]/5 blur-[120px] pointer-events-none" />

      {/* ── Top Header Navigation Bar ── */}
      <header className="sticky top-0 z-40 w-full bg-[#f6f4ee]/85 border-b border-[#e2dfd5] px-4 py-3 md:px-8 backdrop-blur-md">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/" className="flex items-center gap-2.5 group">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/pedebook-icon.png"
                alt="Pedebook Logo"
                className="h-9 w-9 rounded-xl object-contain shadow-xs transition-transform group-hover:scale-105"
              />
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5">
                  <span className="font-bold tracking-tight text-base leading-tight text-[#17221c]">
                    Pedebook
                  </span>
                  <span className="rounded-md bg-[#243129] px-1.5 py-0.5 text-[9px] font-bold text-[#e8dcc7] tracking-wider uppercase">
                    Admin
                  </span>
                </div>
                <span className="text-[9px] font-semibold text-[#9a7257] tracking-wide leading-none">
                  ระบบตรวจสอบผู้ใช้งาน & ลิงก์ตัวอย่าง
                </span>
              </div>
            </Link>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="hidden sm:flex items-center gap-1.5 rounded-full border border-[#d9d7cd] bg-white/70 px-3.5 py-1.5 text-xs font-semibold text-[#17221c] hover:bg-white shadow-xs transition"
            >
              <svg className="h-3.5 w-3.5 text-[#755a47]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span>หน้าแดชบอร์ดผู้ใช้</span>
            </Link>

            <button
              onClick={fetchData}
              disabled={dataLoading}
              className="flex items-center gap-1.5 rounded-full border border-[#d9d7cd] bg-white/70 px-3 py-1.5 text-xs font-semibold text-[#17221c] hover:bg-white shadow-xs transition cursor-pointer"
              title="รีเฟรชข้อมูลล่าสุด"
            >
              <svg className={`h-3.5 w-3.5 text-[#243129] ${dataLoading ? 'animate-spin' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              <span className="hidden md:inline">{dataLoading ? 'กำลังโหลด...' : 'รีเฟรช'}</span>
            </button>

            <div className="flex items-center gap-2 pl-2 border-l border-[#e2dfd5]">
              <span className="grid h-7 w-7 place-items-center rounded-full bg-[#243129] text-[11px] font-bold text-[#e8dcc7]">
                {user.email?.charAt(0).toUpperCase()}
              </span>
              <span className="hidden lg:inline text-xs font-medium text-[#6e746f] max-w-[150px] truncate">
                {user.email}
              </span>
              <button
                onClick={handleLogout}
                className="rounded-full border border-[#d9d7cd] px-3 py-1 text-xs font-bold text-[#755a47] hover:bg-[#243129] hover:text-[#e8dcc7] transition cursor-pointer"
              >
                ออกจากระบบ
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8 md:px-8 relative z-10 space-y-8">
        {/* ── Title & Intro ── */}
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-[#243129]/10 text-[#243129]">
                🛡️ ผู้ดูแลระบบ (Admin)
              </span>
              <span className="text-xs text-[#9a7257]">
                อัปเดตล่าสุด: {new Date().toLocaleTimeString('th-TH')}
              </span>
            </div>
            <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-[#17221c]">
              รายงานการใช้งานและ <span className="font-serif italic text-[#9a7257]">ไฟล์แค็ตตาล็อก</span>
            </h1>
            <p className="text-xs md:text-sm text-[#6e746f] mt-1">
              ตรวจสอบว่าใครมาใช้บ้าง อัปโหลดไฟล์อะไรไปบ้าง พร้อมลิงก์ตัวอย่าง Flipbook และไฟล์ต้นฉบับ
            </p>
          </div>

          {/* Tab buttons */}
          <div className="flex rounded-xl bg-white/70 p-1 border border-[#e2dfd5] shadow-xs self-start sm:self-auto">
            <button
              onClick={() => setActiveTab('catalogs')}
              className={`flex items-center gap-1.5 rounded-lg px-3.5 py-1.5 text-xs font-bold transition cursor-pointer ${
                activeTab === 'catalogs'
                  ? 'bg-[#243129] text-[#e8dcc7] shadow-xs'
                  : 'text-[#6e746f] hover:text-[#17221c]'
              }`}
            >
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              <span>ไฟล์ที่อัปโหลด ({catalogs.length})</span>
            </button>
            <button
              onClick={() => setActiveTab('users')}
              className={`flex items-center gap-1.5 rounded-lg px-3.5 py-1.5 text-xs font-bold transition cursor-pointer ${
                activeTab === 'users'
                  ? 'bg-[#243129] text-[#e8dcc7] shadow-xs'
                  : 'text-[#6e746f] hover:text-[#17221c]'
              }`}
            >
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              <span>ผู้ใช้งานในระบบ ({userSummaries.length})</span>
            </button>
          </div>
        </div>

        {/* ── 4 Key Metric Cards ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="rounded-2xl border border-[#e2dfd5] bg-white/70 p-5 shadow-xs backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-[#755a47]">ผู้ใช้งานทั้งหมด</span>
              <div className="rounded-xl bg-[#9a7257]/10 p-2 text-[#9a7257]">
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
            </div>
            <p className="mt-3 text-2xl font-bold tracking-tight text-[#17221c]">
              {stats.totalUsers} <span className="text-xs font-normal text-[#6e746f]">คน</span>
            </p>
            <p className="mt-1 text-[11px] text-[#6e746f]">
              ผู้ใช้งานที่มีประวัติหรืออัปโหลดเอกสาร
            </p>
          </div>

          <div className="rounded-2xl border border-[#e2dfd5] bg-white/70 p-5 shadow-xs backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-[#755a47]">แค็ตตาล็อกทั้งหมด</span>
              <div className="rounded-xl bg-[#243129]/10 p-2 text-[#243129]">
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
            </div>
            <p className="mt-3 text-2xl font-bold tracking-tight text-[#17221c]">
              {stats.totalCatalogs} <span className="text-xs font-normal text-[#6e746f]">เล่ม</span>
            </p>
            <p className="mt-1 text-[11px] text-[#6e746f]">
              สาธารณะ {stats.publicCatalogs} · ส่วนตัว {stats.privateCatalogs}
            </p>
          </div>

          <div className="rounded-2xl border border-[#e2dfd5] bg-white/70 p-5 shadow-xs backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-[#755a47]">พื้นที่จัดเก็บรวม (R2)</span>
              <div className="rounded-xl bg-amber-500/10 p-2 text-amber-700">
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
                </svg>
              </div>
            </div>
            <p className="mt-3 text-2xl font-bold tracking-tight text-[#17221c]">
              {formatSize(stats.totalSizeBytes)}
            </p>
            <p className="mt-1 text-[11px] text-[#6e746f]">
              ขนาดไฟล์ PDF ทั้งหมดที่จัดเก็บบนคลาวด์
            </p>
          </div>

          <div className="rounded-2xl border border-[#e2dfd5] bg-white/70 p-5 shadow-xs backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-[#755a47]">สถานะระบบ</span>
              <div className="rounded-xl bg-emerald-500/10 p-2 text-emerald-700">
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
            <div className="mt-3 flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full bg-emerald-500 animate-pulse" />
              <span className="text-sm font-bold text-emerald-700">ออนไลน์ปกติ</span>
            </div>
            <p className="mt-1 text-[11px] text-[#6e746f]">
              R2 Storage & Firebase เชื่อมต่อสมบูรณ์
            </p>
          </div>
        </div>

        {dataError && (
          <div className="rounded-2xl border border-red-200 bg-red-50/80 p-4 text-xs font-medium text-red-700 flex items-center justify-between">
            <span>⚠️ เกิดข้อผิดพลาดในการโหลดข้อมูล: {dataError}</span>
            <button onClick={fetchData} className="underline font-bold cursor-pointer">ลองใหม่อีกครั้ง</button>
          </div>
        )}

        {/* ── Active User Filter Indicator ── */}
        {selectedUserFilter !== 'all' && (
          <div className="flex items-center justify-between rounded-xl bg-[#243129] px-4 py-2.5 text-xs text-[#e8dcc7]">
            <div className="flex items-center gap-2">
              <span className="font-semibold">กำลังกรองดูเฉพาะผู้ใช้:</span>
              <span className="rounded bg-white/20 px-2 py-0.5 font-mono text-[11px]">
                {userSummaries.find((u) => u.uid === selectedUserFilter)?.displayName || selectedUserFilter}
              </span>
              <span className="text-[#e8dcc7]/70">
                ({filteredCatalogs.length} แค็ตตาล็อก)
              </span>
            </div>
            <button
              onClick={() => setSelectedUserFilter('all')}
              className="rounded-lg bg-white/15 px-2.5 py-1 text-xs font-bold hover:bg-white/25 transition cursor-pointer"
            >
              ✕ ล้างตัวกรอง (ดูทั้งหมด)
            </button>
          </div>
        )}

        {/* ──────────────────────────────────────────────────────────── */}
        {/* TAB 1: CATALOGS LIST & PREVIEWS ("อัพอะไรไปบ้าง + ลิ้งตัวอย่าง") */}
        {/* ──────────────────────────────────────────────────────────── */}
        {activeTab === 'catalogs' && (
          <section className="space-y-4">
            {/* Search & Filter Toolbar */}
            <div className="rounded-2xl border border-[#e2dfd5] bg-white/70 p-4 shadow-xs backdrop-blur-sm">
              <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
                {/* Search Box */}
                <div className="relative">
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="🔍 ค้นหาตามชื่อไฟล์, อีเมล, UID..."
                    className="w-full rounded-xl border border-[#d9d7cd] bg-white px-3.5 py-2 text-xs text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257]"
                  />
                  {searchQuery && (
                    <button
                      onClick={() => setSearchQuery('')}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-neutral-400 hover:text-neutral-700 cursor-pointer"
                    >
                      ✕
                    </button>
                  )}
                </div>

                {/* Filter by User */}
                <div>
                  <select
                    value={selectedUserFilter}
                    onChange={(e) => setSelectedUserFilter(e.target.value)}
                    className="w-full rounded-xl border border-[#d9d7cd] bg-white px-3 py-2 text-xs text-[#17221c] outline-none focus:border-[#9a7257]"
                  >
                    <option value="all">👤 ผู้ใช้งานทั้งหมด ({userSummaries.length})</option>
                    {userSummaries.map((u) => (
                      <option key={u.uid} value={u.uid}>
                        {u.customAlias ? `★ ${u.customAlias} (${u.totalUploads})` : `${u.displayName} (${u.totalUploads})`}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Filter by Visibility */}
                <div>
                  <select
                    value={visibilityFilter}
                    onChange={(e) => setVisibilityFilter(e.target.value as 'all' | 'public' | 'private')}
                    className="w-full rounded-xl border border-[#d9d7cd] bg-white px-3 py-2 text-xs text-[#17221c] outline-none focus:border-[#9a7257]"
                  >
                    <option value="all">🌐 สถานะทั้งหมด</option>
                    <option value="public">🟢 เฉพาะสาธารณะ (Public)</option>
                    <option value="private">⚪ เฉพาะส่วนตัว (Private)</option>
                  </select>
                </div>

                {/* Sort Order */}
                <div>
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as 'newest' | 'oldest' | 'size-desc' | 'size-asc')}
                    className="w-full rounded-xl border border-[#d9d7cd] bg-white px-3 py-2 text-xs text-[#17221c] outline-none focus:border-[#9a7257]"
                  >
                    <option value="newest">🕒 อัปโหลดล่าสุด (ใหม่ → เก่า)</option>
                    <option value="oldest">🕒 อัปโหลดแรกสุด (เก่า → ใหม่)</option>
                    <option value="size-desc">💾 ขนาดไฟล์มากสุด → น้อยสุด</option>
                    <option value="size-asc">💾 ขนาดไฟล์น้อยสุด → มากสุด</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Catalogs Table */}
            <div className="rounded-2xl border border-[#e2dfd5] bg-white shadow-xs overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-[#e2dfd5] bg-[#fbfaf8] text-[#755a47] uppercase tracking-wider font-semibold">
                      <th className="py-3 px-4 w-16 text-center">ปก</th>
                      <th className="py-3 px-4">ชื่อไฟล์ & แค็ตตาล็อก</th>
                      <th className="py-3 px-4">ผู้อัปโหลด</th>
                      <th className="py-3 px-4">วันที่อัปโหลด</th>
                      <th className="py-3 px-4">ขนาดไฟล์</th>
                      <th className="py-3 px-4">สถานะ</th>
                      <th className="py-3 px-4 text-center">ลิงก์ตัวอย่าง & เครื่องมือ</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#e2dfd5]/60">
                    {filteredCatalogs.length === 0 ? (
                      <tr>
                        <td colSpan={7} className="py-12 text-center text-sm text-[#6e746f]">
                          {dataLoading ? 'กำลังโหลดรายการไฟล์...' : 'ไม่พบข้อมูลแค็ตตาล็อกที่ตรงกับเงื่อนไขการค้นหา'}
                        </td>
                      </tr>
                    ) : (
                      filteredCatalogs.map((item) => {
                        const uploaderSummary = userSummaries.find((u) => u.uid === item.userId);
                        const uploaderName =
                          item.userName ||
                          uploaderSummary?.customAlias ||
                          uploaderSummary?.displayName ||
                          (item.userId ? `UID: ${item.userId.slice(0, 8)}` : 'นิรนาม');
                        const uploaderEmail = item.userEmail || uploaderSummary?.email || '';

                        return (
                          <tr
                            key={item.id}
                            className="hover:bg-[#f6f4ee]/40 transition group"
                          >
                            {/* Book Cover Thumbnail */}
                            <td className="py-3 px-4 text-center align-middle">
                              <div className="mx-auto h-16 w-11 rounded-sm overflow-hidden shadow-xs border border-[#d9d7cd] bg-[#243129] relative flex items-center justify-center">
                                <BookCover slug={item.slug} fileName={item.fileName || item.slug} width={60} />
                              </div>
                            </td>

                            {/* File Name & Title */}
                            <td className="py-3 px-4 align-middle">
                              <div className="flex flex-col">
                                <span className="font-bold text-[#17221c] text-sm leading-snug line-clamp-1">
                                  {item.displayTitle || item.fileName}
                                </span>
                                <span className="text-[11px] text-[#6e746f] font-mono line-clamp-1">
                                  {item.fileName}
                                </span>
                                <span className="text-[10px] text-[#9a7257] font-mono mt-0.5">
                                  slug: {item.slug}
                                </span>
                              </div>
                            </td>

                            {/* Uploader Details */}
                            <td className="py-3 px-4 align-middle">
                              <div className="flex flex-col">
                                <button
                                  onClick={() => item.userId && setSelectedUserFilter(item.userId)}
                                  className="text-left font-semibold text-[#17221c] hover:text-[#9a7257] hover:underline cursor-pointer flex items-center gap-1.5"
                                  title="คลิกเพื่อกรองดูเฉพาะงานของคนนี้"
                                >
                                  <span>{uploaderName}</span>
                                  {userAliases[item.userId || ''] && (
                                    <span className="rounded bg-[#9a7257]/15 text-[#9a7257] px-1 py-0.2 text-[9px]">
                                      {userAliases[item.userId || '']}
                                    </span>
                                  )}
                                </button>
                                {uploaderEmail && (
                                  <span className="text-[10px] text-[#6e746f]">
                                    {uploaderEmail}
                                  </span>
                                )}
                                {item.userId && (
                                  <span className="text-[9px] text-neutral-400 font-mono">
                                    UID: {item.userId.slice(0, 10)}...
                                  </span>
                                )}
                              </div>
                            </td>

                            {/* Upload Date */}
                            <td className="py-3 px-4 align-middle text-[#17221c] whitespace-nowrap">
                              {formatDate(item.lastModified || item.updatedAt)}
                            </td>

                            {/* File Size */}
                            <td className="py-3 px-4 align-middle text-[#17221c] font-mono whitespace-nowrap">
                              {formatSize(item.size)}
                            </td>

                            {/* Public / Private Status */}
                            <td className="py-3 px-4 align-middle whitespace-nowrap">
                              <button
                                onClick={() => handleToggleVisibility(item)}
                                disabled={updatingVisibilityId === item.id}
                                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold transition cursor-pointer ${
                                  item.isPublic !== false
                                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100'
                                    : 'bg-neutral-100 text-neutral-600 border border-neutral-200 hover:bg-neutral-200'
                                }`}
                                title="คลิกเพื่อสลับสถานะ สาธารณะ / ส่วนตัว"
                              >
                                <span className={`h-1.5 w-1.5 rounded-full ${item.isPublic !== false ? 'bg-emerald-500' : 'bg-neutral-400'}`} />
                                <span>{item.isPublic !== false ? 'สาธารณะ' : 'ส่วนตัว'}</span>
                              </button>
                            </td>

                            {/* Example Links & Actions ("มี ลิ้ง ตัว อย่างด้วยนะครับ") */}
                            <td className="py-3 px-4 align-middle">
                              <div className="flex items-center justify-center gap-1.5 flex-wrap">
                                {/* 1. Open Flipbook Preview Link */}
                                <a
                                  href={`/catalog/${item.slug}`}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="inline-flex items-center gap-1 rounded-lg bg-[#243129] px-2.5 py-1.5 text-[11px] font-bold text-[#e8dcc7] shadow-xs hover:bg-[#314238] transition cursor-pointer"
                                  title="เปิดดูหน้า Flipbook (ตัวอย่างจริง)"
                                >
                                  <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                  </svg>
                                  <span>เปิด Flipbook</span>
                                </a>

                                {/* 2. Modal Quick Preview */}
                                <button
                                  type="button"
                                  onClick={() => setPreviewModal({ slug: item.slug, title: item.displayTitle || item.fileName })}
                                  className="inline-flex items-center gap-1 rounded-lg border border-[#d9d7cd] bg-white px-2 py-1.5 text-[11px] font-semibold text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
                                  title="พรีวิวสมุดพลิกสดในหน้านี้"
                                >
                                  <svg className="h-3 w-3 text-[#9a7257]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                  </svg>
                                  <span>พรีวิว</span>
                                </button>

                                {/* 3. Copy Link */}
                                <button
                                  type="button"
                                  onClick={() => copyExampleLink(item.slug)}
                                  className="inline-flex items-center gap-1 rounded-lg border border-[#d9d7cd] bg-white px-2 py-1.5 text-[11px] font-semibold text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
                                  title="คัดลอกลิงก์ตัวอย่างไปส่งให้คนอื่น"
                                >
                                  {copiedSlug === item.slug ? (
                                    <span className="text-emerald-600 font-bold">✓ คัดลอกแล้ว</span>
                                  ) : (
                                    <>
                                      <svg className="h-3 w-3 text-[#755a47]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                      </svg>
                                      <span>คัดลอก</span>
                                    </>
                                  )}
                                </button>

                                {/* 4. QR Code Modal */}
                                <button
                                  type="button"
                                  onClick={() => setQrModal({ slug: item.slug, fileName: item.fileName })}
                                  className="inline-flex items-center rounded-lg border border-[#d9d7cd] bg-white p-1.5 text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
                                  title="สแกน QR Code เพื่อเปิดบนมือถือ"
                                >
                                  <svg className="h-3.5 w-3.5 text-[#755a47]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                                  </svg>
                                </button>

                                {/* 5. Open Raw PDF */}
                                {item.pdfUrl && (
                                  <a
                                    href={item.pdfUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center rounded-lg border border-[#d9d7cd] bg-white p-1.5 text-neutral-600 hover:text-red-700 hover:bg-neutral-50 transition cursor-pointer"
                                    title="ดูไฟล์ PDF ต้นฉบับจาก R2"
                                  >
                                    <svg className="h-3.5 w-3.5 text-red-600" fill="currentColor" viewBox="0 0 20 20">
                                      <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 6a1 1 0 011-1h6a1 1 0 110 2H7a1 1 0 01-1-1zm1 3a1 1 0 100 2h6a1 1 0 100-2H7z" clipRule="evenodd" />
                                    </svg>
                                  </a>
                                )}

                                {/* 6. Delete File */}
                                <button
                                  type="button"
                                  onClick={() => setDeletingItem(item)}
                                  className="inline-flex items-center rounded-lg border border-red-200 bg-red-50/70 p-1.5 text-red-600 hover:bg-red-100 transition cursor-pointer"
                                  title="ลบแค็ตตาล็อกนี้ออกจากระบบ"
                                >
                                  <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                  </svg>
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        )}

        {/* ──────────────────────────────────────────────────────────── */}
        {/* TAB 2: USER DIRECTORY & ACTIVITY LOG ("ใครมาใช้บ้าง") */}
        {/* ──────────────────────────────────────────────────────────── */}
        {activeTab === 'users' && (
          <section className="space-y-4">
            <div className="rounded-2xl border border-[#e2dfd5] bg-white shadow-xs overflow-hidden">
              <div className="p-4 border-b border-[#e2dfd5] bg-[#fbfaf8] flex items-center justify-between">
                <div>
                  <h2 className="font-bold text-sm text-[#17221c]">
                    รายชื่อผู้ใช้งานทั้งหมดที่บันทึกในระบบ ({userSummaries.length} บัญชี)
                  </h2>
                  <p className="text-xs text-[#6e746f]">
                    แสดงข้อมูลประวัติการเข้าใช้งาน จำนวนผลงานที่อัปโหลด และสามารถตั้งชื่อเล่น/โน้ตกำกับผู้ใช้ได้
                  </p>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-[#e2dfd5] bg-[#fbfaf8] text-[#755a47] uppercase tracking-wider font-semibold">
                      <th className="py-3 px-4">ผู้ใช้งาน</th>
                      <th className="py-3 px-4">ชื่อเล่น / โน้ตกำกับ (Admin Alias)</th>
                      <th className="py-3 px-4">User ID (UID)</th>
                      <th className="py-3 px-4">ใช้งานล่าสุด</th>
                      <th className="py-3 px-4 text-center">จำนวนที่อัปโหลด</th>
                      <th className="py-3 px-4">ขนาดไฟล์รวม</th>
                      <th className="py-3 px-4 text-center">การจัดการ</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#e2dfd5]/60">
                    {userSummaries.length === 0 ? (
                      <tr>
                        <td colSpan={7} className="py-12 text-center text-sm text-[#6e746f]">
                          ยังไม่พบประวัติผู้ใช้งาน
                        </td>
                      </tr>
                    ) : (
                      userSummaries.map((item) => {
                        const isEditingAlias = editingAliasUid === item.uid;
                        const alias = userAliases[item.uid] || '';

                        return (
                          <tr key={item.uid} className="hover:bg-[#f6f4ee]/40 transition">
                            {/* User Avatar + Display Name + Email */}
                            <td className="py-3.5 px-4 align-middle">
                              <div className="flex items-center gap-3">
                                {item.photoURL ? (
                                  /* eslint-disable-next-line @next/next/no-img-element */
                                  <img
                                    src={item.photoURL}
                                    alt="avatar"
                                    className="h-8 w-8 rounded-full border border-[#d9d7cd] object-cover"
                                    referrerPolicy="no-referrer"
                                  />
                                ) : (
                                  <span className="grid h-8 w-8 place-items-center rounded-full bg-[#243129] text-xs font-bold text-[#e8dcc7]">
                                    {item.email?.charAt(0).toUpperCase() || 'U'}
                                  </span>
                                )}
                                <div className="flex flex-col">
                                  <span className="font-bold text-[#17221c] text-sm leading-tight">
                                    {item.displayName}
                                  </span>
                                  <span className="text-xs text-[#6e746f]">
                                    {item.email}
                                  </span>
                                </div>
                              </div>
                            </td>

                            {/* Admin Custom Alias / Nickname */}
                            <td className="py-3.5 px-4 align-middle">
                              {isEditingAlias ? (
                                <div className="flex items-center gap-1.5">
                                  <input
                                    type="text"
                                    value={aliasInputValue}
                                    onChange={(e) => setAliasInputValue(e.target.value)}
                                    placeholder="เช่น คุณป้อ, ทีมขาย..."
                                    className="rounded-lg border border-[#9a7257] bg-white px-2 py-1 text-xs outline-none"
                                    autoFocus
                                    onKeyDown={(e) => {
                                      if (e.key === 'Enter') handleSaveAlias(item.uid);
                                      if (e.key === 'Escape') setEditingAliasUid(null);
                                    }}
                                  />
                                  <button
                                    onClick={() => handleSaveAlias(item.uid)}
                                    className="rounded bg-[#243129] px-2 py-1 text-[10px] font-bold text-[#e8dcc7] cursor-pointer"
                                  >
                                    บันทึก
                                  </button>
                                  <button
                                    onClick={() => setEditingAliasUid(null)}
                                    className="rounded border border-[#d9d7cd] px-1.5 py-1 text-[10px] cursor-pointer"
                                  >
                                    ✕
                                  </button>
                                </div>
                              ) : (
                                <div className="flex items-center gap-1.5">
                                  {alias ? (
                                    <span className="rounded-md bg-[#9a7257]/10 text-[#9a7257] font-semibold px-2 py-0.5 text-xs">
                                      ★ {alias}
                                    </span>
                                  ) : (
                                    <span className="text-neutral-400 text-xs italic">
                                      - ยังไม่มีโน้ต -
                                    </span>
                                  )}
                                  <button
                                    onClick={() => {
                                      setEditingAliasUid(item.uid);
                                      setAliasInputValue(alias);
                                    }}
                                    className="text-neutral-400 hover:text-[#9a7257] transition cursor-pointer p-0.5"
                                    title="แก้ไขชื่อเล่น/โน้ตกำกับ"
                                  >
                                    <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                                    </svg>
                                  </button>
                                </div>
                              )}
                            </td>

                            {/* UID */}
                            <td className="py-3.5 px-4 align-middle">
                              <div className="flex items-center gap-1">
                                <span className="font-mono text-[11px] text-[#6e746f] bg-[#fbfaf8] px-2 py-0.5 rounded border border-[#e2dfd5]">
                                  {item.uid.slice(0, 16)}...
                                </span>
                                <button
                                  onClick={() => {
                                    navigator.clipboard.writeText(item.uid);
                                    alert('คัดลอก UID เรียบร้อยครับ: ' + item.uid);
                                  }}
                                  className="text-neutral-400 hover:text-[#243129] cursor-pointer p-1"
                                  title="คัดลอก UID เต็ม"
                                >
                                  <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                  </svg>
                                </button>
                              </div>
                            </td>

                            {/* Last Active */}
                            <td className="py-3.5 px-4 align-middle text-[#17221c] whitespace-nowrap">
                              {formatDate(item.lastActiveAt)}
                            </td>

                            {/* Total Uploads */}
                            <td className="py-3.5 px-4 align-middle text-center">
                              <span className="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#243129]/10 text-[#243129]">
                                {item.totalUploads} เล่ม
                              </span>
                            </td>

                            {/* Total Size */}
                            <td className="py-3.5 px-4 align-middle font-mono text-[#17221c]">
                              {formatSize(item.totalSizeBytes)}
                            </td>

                            {/* Action: Filter this user's files */}
                            <td className="py-3.5 px-4 align-middle text-center">
                              <button
                                onClick={() => {
                                  setSelectedUserFilter(item.uid);
                                  setActiveTab('catalogs');
                                }}
                                className="inline-flex items-center gap-1 rounded-lg bg-[#243129] px-2.5 py-1.5 text-xs font-bold text-[#e8dcc7] hover:bg-[#314238] transition cursor-pointer shadow-xs"
                                title="ดูไฟล์ที่คนนี้อัพโหลดทั้งหมด"
                              >
                                <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                </svg>
                                <span>ดูผลงาน ({item.totalUploads})</span>
                              </button>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        )}
      </main>

      {/* ──────────────────────────────────────────────────────────── */}
      {/* MODAL 1: QR Code Modal with Mobile Preview Link */}
      {/* ──────────────────────────────────────────────────────────── */}
      {qrModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
          <div className="relative w-full max-w-sm rounded-3xl border border-[#e2dfd5] bg-white p-6 shadow-2xl text-center">
            <button
              onClick={() => setQrModal(null)}
              className="absolute right-4 top-4 rounded-full p-1 text-neutral-400 hover:bg-neutral-100 hover:text-neutral-700 cursor-pointer"
            >
              ✕
            </button>
            <h3 className="text-base font-bold text-[#17221c]">สแกน QR Code เพื่อเปิดอ่าน</h3>
            <p className="mt-1 text-xs text-[#6e746f] truncate">{qrModal.fileName}</p>

            <div ref={qrCanvasRef} className="my-5 flex justify-center p-4 bg-white rounded-2xl border border-[#e2dfd5] shadow-inner inline-block mx-auto">
              <QRCodeCanvas
                value={`${siteOrigin}/catalog/${qrModal.slug}`}
                size={200}
                level="H"
                includeMargin
              />
            </div>

            <p className="text-[11px] font-mono text-[#9a7257] break-all bg-neutral-50 p-2 rounded-xl border border-neutral-200">
              {siteOrigin}/catalog/{qrModal.slug}
            </p>

            <div className="mt-4 flex gap-2">
              <button
                onClick={() => downloadQrCode(qrModal.slug)}
                className="flex-1 rounded-xl bg-[#243129] py-2 text-xs font-bold text-[#e8dcc7] hover:bg-[#314238] transition cursor-pointer"
              >
                💾 บันทึกรูปภาพ QR
              </button>
              <button
                onClick={() => copyExampleLink(qrModal.slug)}
                className="flex-1 rounded-xl border border-[#d9d7cd] bg-white py-2 text-xs font-bold text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
              >
                📋 คัดลอกลิงก์
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ──────────────────────────────────────────────────────────── */}
      {/* MODAL 2: Live In-Admin Flipbook Preview Modal */}
      {/* ──────────────────────────────────────────────────────────── */}
      {previewModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-2 sm:p-6 backdrop-blur-md">
          <div className="relative w-full max-w-5xl h-[85vh] rounded-3xl bg-[#1c1c1e] border border-neutral-700 shadow-2xl flex flex-col overflow-hidden">
            {/* Modal Bar */}
            <div className="flex items-center justify-between px-4 py-3 bg-[#243129] text-[#e8dcc7] border-b border-neutral-700">
              <div className="flex items-center gap-2 truncate">
                <span className="text-xs font-bold text-[#9a7257]">พรีวิวตัวอย่างสด:</span>
                <span className="text-xs font-semibold truncate">{previewModal.title}</span>
              </div>
              <div className="flex items-center gap-2">
                <a
                  href={`/catalog/${previewModal.slug}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="rounded-lg bg-white/15 px-2.5 py-1 text-[11px] font-bold text-white hover:bg-white/25 transition cursor-pointer"
                >
                  ↗ เปิดแท็บใหม่
                </a>
                <button
                  onClick={() => setPreviewModal(null)}
                  className="rounded-lg bg-white/15 px-2.5 py-1 text-[11px] font-bold text-white hover:bg-white/25 transition cursor-pointer"
                >
                  ✕ ปิดหน้าต่าง
                </button>
              </div>
            </div>

            {/* Embedded Iframe */}
            <iframe
              src={`/catalog/${previewModal.slug}`}
              className="w-full h-full border-0 bg-[#1c1c1e]"
              title="Flipbook Live Preview"
            />
          </div>
        </div>
      )}

      {/* ──────────────────────────────────────────────────────────── */}
      {/* MODAL 3: Delete Confirmation Modal */}
      {/* ──────────────────────────────────────────────────────────── */}
      {deletingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
          <div className="relative w-full max-w-md rounded-3xl border border-red-200 bg-white p-6 shadow-2xl">
            <div className="flex items-center gap-3 text-red-600 mb-3">
              <div className="h-10 w-10 rounded-xl bg-red-100 flex items-center justify-center">
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#17221c]">ยืนยันการลบแค็ตตาล็อก</h3>
                <p className="text-xs text-[#6e746f]">การกระทำนี้ไม่สามารถย้อนกลับได้</p>
              </div>
            </div>

            <p className="text-xs text-[#17221c] bg-neutral-50 p-3 rounded-xl border border-neutral-200">
              คุณต้องการลบไฟล์ <strong>&quot;{deletingItem.fileName}&quot;</strong> และข้อมูลทั้งหมดออกจากระบบใช่หรือไม่?
            </p>

            <div className="mt-5 flex gap-2 justify-end">
              <button
                type="button"
                onClick={() => setDeletingItem(null)}
                disabled={isDeleting}
                className="rounded-xl border border-[#d9d7cd] px-4 py-2 text-xs font-bold text-[#17221c] hover:bg-neutral-50 transition cursor-pointer"
              >
                ยกเลิก
              </button>
              <button
                type="button"
                onClick={handleDeleteCatalog}
                disabled={isDeleting}
                className="rounded-xl bg-red-600 px-4 py-2 text-xs font-bold text-white hover:bg-red-700 transition cursor-pointer disabled:opacity-50"
              >
                {isDeleting ? 'กำลังลบ...' : 'ลบไฟล์ทันที'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
