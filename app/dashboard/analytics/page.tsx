'use client';

import React, { useState, useEffect, useMemo, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { supabase, isSupabaseConfigured } from '../../src/lib/supabase/client';

export interface PageStatItem {
  id: string;
  catalog_id: string;
  page_number: number;
  view_count: number;
  total_duration_seconds: number;
  avg_duration_seconds: number;
  updated_at: string;
}

export interface CatalogSummaryItem {
  id: string;
  slug: string;
  fileName: string;
  displayTitle: string;
  coverImage?: string;
  size?: number;
  createdAt?: string;
  totalViews: number;
  totalDurationSeconds: number;
  avgDurationSeconds: number;
  pageCount: number;
  topPage: number;
  uniqueReaders?: number;
  returningCount?: number;
  newCount?: number;
  returnRate?: number;
}

export interface ReaderMetrics {
  totalUniqueReaders: number;
  returningReaders: number;
  newReaders: number;
  returnRatePercent: number;
}

function formatSize(bytes?: number): string {
  if (!bytes || bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds.toFixed(1)} วินาที`;
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  return `${m} นาที ${s > 0 ? `${s} วินาที` : ''}`;
}

function AnalyticsDashboardContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialId = searchParams.get('id') || searchParams.get('catalogId') || 'all';

  const [catalogs, setCatalogs] = useState<CatalogSummaryItem[]>([]);
  const [selectedId, setSelectedId] = useState<string>(initialId);
  const [pageStats, setPageStats] = useState<PageStatItem[]>([]);
  const [globalReaderMetrics, setGlobalReaderMetrics] = useState<ReaderMetrics>({
    totalUniqueReaders: 0,
    returningReaders: 0,
    newReaders: 0,
    returnRatePercent: 0,
  });
  const [singleBookReaders, setSingleBookReaders] = useState<ReaderMetrics>({
    totalUniqueReaders: 0,
    returningReaders: 0,
    newReaders: 0,
    returnRatePercent: 0,
  });

  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(false);
  const [sortBy, setSortBy] = useState<'page' | 'duration' | 'views'>('page');
  const [searchPage, setSearchPage] = useState('');

  // 1. Fetch user catalogs & overview
  useEffect(() => {
    let isMounted = true;
    async function loadCatalogsAndOverview() {
      setLoading(true);
      try {
        if (!isSupabaseConfigured()) {
          setLoading(false);
          return;
        }

        const { data: { session } } = await supabase.auth.getSession();
        if (!session?.user) {
          router.replace('/login');
          return;
        }

        // ดึงสถิติภาพรวมทุกเล่ม
        const res = await fetch(`/api/v1/analytics/stats?userId=${session.user.id}`);
        const data = await res.json();

        if (data.success && data.overview && Array.isArray(data.overview.catalogs) && isMounted) {
          setCatalogs(data.overview.catalogs);
          setGlobalReaderMetrics({
            totalUniqueReaders: data.overview.totalUniqueReaders || 0,
            returningReaders: data.overview.totalReturningReaders || 0,
            newReaders: data.overview.totalNewReaders || 0,
            returnRatePercent: data.overview.returnRatePercent || 0,
          });

          // ถ้ามีการระบุ id ใน URL ให้เลือกเล่มนั้น ถ้าไม่มีให้คงเดิม
          if (initialId && initialId !== 'all') {
            const exists = data.overview.catalogs.find((c: CatalogSummaryItem) => c.id === initialId || c.slug === initialId);
            if (exists) {
              setSelectedId(exists.id);
            }
          }
        }
      } catch (err) {
        console.error('Failed to load analytics overview:', err);
      } finally {
        if (isMounted) setLoading(false);
      }
    }

    loadCatalogsAndOverview();
    return () => {
      isMounted = false;
    };
  }, [initialId, router]);

  // 2. Fetch single catalog page stats when selectedId is a specific catalog
  useEffect(() => {
    if (!selectedId || selectedId === 'all') {
      setPageStats([]);
      return;
    }

    let isMounted = true;
    async function fetchBookStats() {
      setStatsLoading(true);
      try {
        const res = await fetch(`/api/v1/analytics/stats?catalogId=${selectedId}`);
        const data = await res.json();
        if (data.success && isMounted) {
          if (Array.isArray(data.stats)) {
            setPageStats(data.stats);
          }
          if (data.readers) {
            setSingleBookReaders({
              totalUniqueReaders: data.readers.totalUniqueReaders || 0,
              returningReaders: data.readers.returningReaders || 0,
              newReaders: data.readers.newReaders || 0,
              returnRatePercent: data.readers.returnRatePercent || 0,
            });
          }
        }
      } catch (err) {
        console.error('Failed to load page stats for book:', err);
      } finally {
        if (isMounted) setStatsLoading(false);
      }
    }

    fetchBookStats();
    return () => {
      isMounted = false;
    };
  }, [selectedId]);

  // Computed data for current selected catalog
  const currentCatalog = useMemo(() => {
    if (selectedId === 'all') return null;
    return catalogs.find((c) => c.id === selectedId || c.slug === selectedId) || null;
  }, [selectedId, catalogs]);

  // Global KPIs (Overview mode)
  const totalGlobalViews = useMemo(() => catalogs.reduce((s, c) => s + c.totalViews, 0), [catalogs]);
  const totalGlobalDuration = useMemo(() => catalogs.reduce((s, c) => s + c.totalDurationSeconds, 0), [catalogs]);
  const topCatalog = useMemo(() => {
    if (catalogs.length === 0) return null;
    return [...catalogs].sort((a, b) => b.totalViews - a.totalViews)[0];
  }, [catalogs]);

  // Single Book KPIs
  const maxAvgDuration = useMemo(() => Math.max(...pageStats.map((s) => s.avg_duration_seconds), 1), [pageStats]);
  const hotPage = useMemo(() => {
    if (pageStats.length === 0) return null;
    return [...pageStats].sort((a, b) => b.avg_duration_seconds - a.avg_duration_seconds)[0];
  }, [pageStats]);

  const mostViewedPage = useMemo(() => {
    if (pageStats.length === 0) return null;
    return [...pageStats].sort((a, b) => b.view_count - a.view_count)[0];
  }, [pageStats]);

  const totalBookViews = useMemo(() => pageStats.reduce((s, p) => s + p.view_count, 0), [pageStats]);
  const totalBookDuration = useMemo(() => pageStats.reduce((s, p) => s + p.total_duration_seconds, 0), [pageStats]);
  const avgBookDurationPerReader = totalBookViews > 0 ? totalBookDuration / totalBookViews : 0;

  // Filtered & Sorted Page Stats for Table
  const filteredSortedStats = useMemo(() => {
    let list = [...pageStats];
    if (searchPage.trim()) {
      list = list.filter((p) => p.page_number.toString().includes(searchPage.trim()));
    }
    return list.sort((a, b) => {
      if (sortBy === 'duration') return b.avg_duration_seconds - a.avg_duration_seconds;
      if (sortBy === 'views') return b.view_count - a.view_count;
      return a.page_number - b.page_number;
    });
  }, [pageStats, searchPage, sortBy]);

  return (
    <div className="min-h-screen bg-[#f6f4ee] font-sans text-[#17221c] pb-24">
      {/* ── Top Header Navigation Bar ── */}
      <header className="sticky top-0 z-40 w-full bg-[#f6f4ee]/90 border-b border-[#e2dfd5] px-4 py-3 md:px-8 backdrop-blur-md">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border border-[#d9d7cd] bg-white hover:bg-neutral-50 text-xs font-bold text-[#755a47] shadow-xs transition cursor-pointer"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
              </svg>
              <span>กลับแดชบอร์ด</span>
            </Link>

            <div className="h-5 w-px bg-[#e2dfd5] hidden sm:block" />

            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-xl bg-[#243129] flex items-center justify-center text-[#e8dcc7] shadow-xs">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
                </svg>
              </div>
              <div>
                <h1 className="text-base font-bold text-[#17221c] leading-tight">
                  ศูนย์วิเคราะห์สถิติผู้อ่าน
                </h1>
                <span className="text-[10px] text-[#9a7257] font-semibold">
                  Pedebook Reader Insights Studio
                </span>
              </div>
            </div>
          </div>

          {/* Book Switcher Dropdown */}
          <div className="flex items-center gap-2">
            <label className="text-xs font-bold text-[#755a47] shrink-0 hidden md:inline">
              เลือกดูสถิติ:
            </label>
            <div className="relative w-full sm:w-auto">
              <select
                value={selectedId}
                onChange={(e) => {
                  setSelectedId(e.target.value);
                  const newUrl = e.target.value === 'all' ? '/dashboard/analytics' : `/dashboard/analytics?id=${e.target.value}`;
                  window.history.pushState({}, '', newUrl);
                }}
                className="w-full sm:w-72 appearance-none rounded-xl border border-[#d9d7cd] bg-white px-3.5 py-2 pr-9 text-xs font-bold text-[#17221c] shadow-xs outline-none focus:border-[#243129] cursor-pointer"
              >
                <option value="all">🌐 ภาพรวมทุกเล่ม (Overview All Books)</option>
                <optgroup label="── เลือกเฉพาะเล่ม ──">
                  {catalogs.map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      📖 {cat.displayTitle} ({cat.uniqueReaders || cat.totalViews} คน)
                    </option>
                  ))}
                </optgroup>
              </select>
              <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2.5 text-[#6e746f]">
                <svg className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* ── Main Container ── */}
      <main className="max-w-7xl mx-auto px-4 py-8 md:px-8">
        {loading ? (
          <div className="py-24 text-center">
            <div className="w-10 h-10 border-3 border-[#243129] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-sm font-bold text-[#755a47]">กำลังรวบรวมข้อมูลสถิติ...</p>
          </div>
        ) : selectedId === 'all' ? (
          /* ══════════════════════════════════════════════ */
          /*  MODE 1: OVERVIEW ALL BOOKS (ภาพรวมทุกเล่ม)   */
          /* ══════════════════════════════════════════════ */
          <div className="space-y-8 animate-fadeIn">
            {/* Header Description */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#e2dfd5]">
              <div>
                <h2 className="text-2xl font-bold tracking-tight text-[#17221c]">
                  ภาพรวมพฤติกรรมผู้อ่านทุกเล่ม
                </h2>
                <p className="text-xs sm:text-sm text-[#6e746f] mt-1">
                  ติดตามผลตอบรับ คนอ่านจริง และสัดส่วนผู้อ่านเดิมที่กลับมาเปิดอ่านซ้ำ
                </p>
              </div>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 text-emerald-800 text-xs font-bold border border-emerald-200 shrink-0">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>จำแนกคนอ่านจริงรายอุปกรณ์</span>
              </span>
            </div>

            {/* 4 Executive KPI Cards with Reader Loyalty */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Card 1: Unique Readers (คนอ่านจริงทั้งหมด) */}
              <div className="bg-white border border-[#e2dfd5] rounded-3xl p-5 shadow-xs">
                <div className="flex items-center justify-between text-[#755a47] mb-2">
                  <span className="text-xs font-bold uppercase tracking-wider">คนอ่านจริงทั้งหมด (Unique)</span>
                  <div className="p-2 rounded-xl bg-emerald-50 text-emerald-700">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                    </svg>
                  </div>
                </div>
                <h3 className="text-3xl font-extrabold text-[#17221c]">
                  {(globalReaderMetrics.totalUniqueReaders || totalGlobalViews).toLocaleString()} คน
                </h3>
                <p className="text-[11px] text-emerald-700 font-semibold mt-1">
                  นับรายคน/รายเครื่อง ไม่นับซ้ำ
                </p>
              </div>

              {/* Card 2: Returning Readers & Loyalty Ratio */}
              <div className="bg-white border border-[#e2dfd5] rounded-3xl p-5 shadow-xs">
                <div className="flex items-center justify-between text-[#755a47] mb-2">
                  <span className="text-xs font-bold uppercase tracking-wider">คนเดิมกลับมาอ่านซ้ำ (Returning)</span>
                  <div className="p-2 rounded-xl bg-amber-50 text-amber-700">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
                    </svg>
                  </div>
                </div>
                <h3 className="text-3xl font-extrabold text-amber-950">
                  {globalReaderMetrics.returningReaders.toLocaleString()} คน
                </h3>
                <div className="flex items-center gap-1.5 mt-1 text-[11px] text-[#6e746f]">
                  <span className="font-bold text-amber-800">
                    {globalReaderMetrics.returnRatePercent}%
                  </span>
                  <span>ผู้อ่านประจำที่เปิดดูซ้ำ</span>
                </div>
              </div>

              {/* Card 3: Total Reading Time */}
              <div className="bg-white border border-[#e2dfd5] rounded-3xl p-5 shadow-xs">
                <div className="flex items-center justify-between text-[#755a47] mb-2">
                  <span className="text-xs font-bold uppercase tracking-wider">เวลาอ่านสะสมรวมทุกเล่ม</span>
                  <div className="p-2 rounded-xl bg-purple-50 text-purple-700">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                </div>
                <h3 className="text-3xl font-extrabold text-[#17221c]">{formatDuration(totalGlobalDuration)}</h3>
                <p className="text-[11px] text-[#6e746f] mt-1">เวลาที่ผู้อ่านใช้กับแบรนด์คุณ</p>
              </div>

              {/* Card 4: Top Performing Book */}
              <div className="bg-white border border-[#e2dfd5] rounded-3xl p-5 shadow-xs">
                <div className="flex items-center justify-between text-[#755a47] mb-2">
                  <span className="text-xs font-bold uppercase tracking-wider">เล่มยอดนิยมอันดับ 1</span>
                  <div className="p-2 rounded-xl bg-[#243129]/5 text-[#243129]">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.004 0V5.625c0-.621-.504-1.125-1.125-1.125h-3.75c-.621 0-1.125.504-1.125 1.125v8.625" />
                    </svg>
                  </div>
                </div>
                <h3 className="text-base font-extrabold text-[#17221c] truncate" title={topCatalog?.displayTitle}>
                  {topCatalog ? topCatalog.displayTitle : '-'}
                </h3>
                <p className="text-[11px] text-[#243129] font-bold mt-1">
                  {topCatalog ? `${topCatalog.uniqueReaders || topCatalog.totalViews} คนอ่าน (${formatDuration(topCatalog.totalDurationSeconds)})` : 'ยังไม่มีสถิติ'}
                </p>
              </div>
            </div>

            {/* Book Leaderboard Table */}
            <div className="bg-white border border-[#e2dfd5] rounded-3xl overflow-hidden shadow-xs">
              <div className="p-6 border-b border-[#e2dfd5] flex items-center justify-between">
                <div>
                  <h3 className="text-base font-bold text-[#17221c]">ตารางสรุปสถิติเปรียบเทียบรายเล่ม</h3>
                  <p className="text-xs text-[#6e746f] mt-0.5">วิเคราะห์จำนวนคนอ่านจริง (Unique) และคนเดิมที่กลับมาอ่านซ้ำในแต่ละเล่ม</p>
                </div>
              </div>

              {catalogs.length === 0 ? (
                <div className="p-12 text-center text-xs text-[#6e746f]">
                  ยังไม่มีแค็ตตาล็อกในระบบ
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-[#fbfaf8] border-b border-[#e2dfd5] text-[#755a47] font-bold uppercase tracking-wider text-[11px]">
                      <tr>
                        <th className="py-3.5 px-6">ชื่อแค็ตตาล็อก</th>
                        <th className="py-3.5 px-4 text-center">คนอ่านจริง (Unique)</th>
                        <th className="py-3.5 px-4 text-center">คนเดิมกลับมาซ้ำ</th>
                        <th className="py-3.5 px-4 text-center">ยอดเปิดรวม (Views)</th>
                        <th className="py-3.5 px-4 text-center">เวลาอ่านสะสม</th>
                        <th className="py-3.5 px-4 text-center">หน้า Hot Page</th>
                        <th className="py-3.5 px-6 text-right">การจัดการ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#e2dfd5]">
                      {catalogs.map((cat, idx) => (
                        <tr key={cat.id} className="hover:bg-[#faf8f5] transition-colors">
                          <td className="py-4 px-6">
                            <div className="flex items-center gap-3">
                              <span className="font-mono text-xs text-[#9a7257] font-bold w-4">
                                #{idx + 1}
                              </span>
                              <div>
                                <h4 className="font-bold text-sm text-[#17221c] truncate max-w-xs sm:max-w-md">
                                  {cat.displayTitle}
                                </h4>
                                <a
                                  href={`/catalog/${cat.slug}`}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="text-[11px] text-[#9a7257] hover:underline flex items-center gap-1 mt-0.5"
                                >
                                  <span>/catalog/{cat.slug}</span>
                                  <svg className="w-3 h-3" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V10.5M10.5 13.5L21 3M21 3h-5.25M21 3v5.25" />
                                  </svg>
                                </a>
                              </div>
                            </div>
                          </td>
                          <td className="py-4 px-4 text-center font-bold text-sm text-emerald-800">
                            {(cat.uniqueReaders || cat.totalViews).toLocaleString()} คน
                          </td>
                          <td className="py-4 px-4 text-center">
                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-amber-50 text-amber-900 text-[11px] font-bold border border-amber-200">
                              🔄 {cat.returningCount || 0} คน ({cat.returnRate || 0}%)
                            </span>
                          </td>
                          <td className="py-4 px-4 text-center font-mono text-[#6e746f]">
                            {cat.totalViews.toLocaleString()} ครั้ง
                          </td>
                          <td className="py-4 px-4 text-center font-medium text-[#17221c]">
                            {formatDuration(cat.totalDurationSeconds)}
                          </td>
                          <td className="py-4 px-4 text-center">
                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-orange-50 text-orange-900 text-[11px] font-bold border border-orange-200">
                              🔥 หน้า {cat.topPage}
                            </span>
                          </td>
                          <td className="py-4 px-6 text-right">
                            <button
                              onClick={() => {
                                setSelectedId(cat.id);
                                window.history.pushState({}, '', `/dashboard/analytics?id=${cat.id}`);
                              }}
                              className="inline-flex items-center gap-1 px-3.5 py-1.5 rounded-xl bg-[#243129] text-[#f7f5f0] hover:bg-[#314238] font-bold text-xs shadow-xs transition active:scale-95 cursor-pointer"
                            >
                              <span>เจาะลึกสถิติเล่มนี้</span>
                              <svg className="w-3.5 h-3.5 text-emerald-400" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
                              </svg>
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        ) : (
          /* ══════════════════════════════════════════════ */
          /*  MODE 2: SINGLE BOOK DEEP-DIVE (สถิติเจาะลึก)   */
          /* ══════════════════════════════════════════════ */
          <div className="space-y-8 animate-fadeIn">
            {/* Book Info Header Banner */}
            <div className="bg-white border border-[#e2dfd5] rounded-3xl p-6 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="flex items-center gap-4">
                <div className="w-12 h-16 rounded-lg bg-[#243129] border-l-3 border-[#9a7257] shadow-md flex items-center justify-center text-[#e8dcc7] shrink-0">
                  <svg className="w-6 h-6 text-emerald-300" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 text-[10px] font-bold border border-emerald-200">
                      เจาะลึกสถิติรายหน้า &amp; คนอ่านจริง
                    </span>
                    <span className="text-xs text-[#6e746f] font-mono">
                      ขนาด: {formatSize(currentCatalog?.size)}
                    </span>
                  </div>
                  <h2 className="text-xl sm:text-2xl font-black text-[#17221c] mt-1">
                    {currentCatalog?.displayTitle}
                  </h2>
                </div>
              </div>

              <div className="flex items-center gap-2.5 shrink-0">
                <button
                  onClick={() => {
                    setSelectedId('all');
                    window.history.pushState({}, '', '/dashboard/analytics');
                  }}
                  className="px-4 py-2 rounded-xl border border-[#d9d7cd] bg-[#fbfaf8] hover:bg-neutral-100 text-xs font-bold text-[#755a47] transition cursor-pointer"
                >
                  ← กลับดูภาพรวมทุกเล่ม
                </button>
                {currentCatalog && (
                  <a
                    href={`/catalog/${currentCatalog.slug}`}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#243129] text-[#f7f5f0] hover:bg-[#314238] text-xs font-bold shadow-xs transition"
                  >
                    <span>เปิดอ่านสมุดจริง</span>
                    <svg className="w-3.5 h-3.5 text-emerald-400" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V10.5M10.5 13.5L21 3M21 3h-5.25M21 3v5.25" />
                    </svg>
                  </a>
                )}
              </div>
            </div>

            {statsLoading ? (
              <div className="py-20 text-center">
                <div className="w-8 h-8 border-3 border-[#243129] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
                <p className="text-xs font-bold text-[#755a47]">กำลังวิเคราะห์ข้อมูลรายหน้าและคนอ่านจริงของเล่มนี้...</p>
              </div>
            ) : pageStats.length === 0 ? (
              <div className="bg-white border border-dashed border-[#d9d7cd] rounded-3xl p-16 text-center max-w-lg mx-auto">
                <svg className="w-12 h-12 text-[#d9d7cd] mx-auto mb-3" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <h3 className="text-base font-bold text-[#17221c]">ยังไม่มีข้อมูลการเปิดอ่านสำหรับเล่มนี้</h3>
                <p className="text-xs text-[#6e746f] mt-1.5 leading-relaxed">
                  เมื่อคุณแชร์ลิงก์ให้ผู้อ่านเปิดดู ระบบจะเริ่มตรวจจับคนอ่านจริง (Unique Readers) และเวลาที่คนเปิดค้างไว้ในแต่ละหน้าทันที
                </p>
              </div>
            ) : (
              <>
                {/* 4 Single Book KPI Cards (Featuring Unique & Returning Readers!) */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  {/* Card 1: Unique Readers */}
                  <div className="bg-gradient-to-br from-emerald-500/10 via-emerald-500/5 to-transparent border border-emerald-300 rounded-3xl p-5 shadow-xs">
                    <div className="flex items-center justify-between text-emerald-900 mb-2">
                      <span className="text-xs font-extrabold uppercase tracking-wider flex items-center gap-1">
                        <span>👥</span> คนอ่านจริง (Unique Readers)
                      </span>
                    </div>
                    <h3 className="text-3xl font-extrabold text-emerald-950">
                      {(singleBookReaders.totalUniqueReaders || totalBookViews).toLocaleString()} คน
                    </h3>
                    <p className="text-xs text-emerald-800 font-semibold mt-1">
                      นับรายคนจริง ไม่นับซ้ำยอดรีเฟรช
                    </p>
                  </div>

                  {/* Card 2: Returning vs New Reader Ratio */}
                  <div className="bg-gradient-to-br from-amber-500/10 via-amber-500/5 to-transparent border border-amber-300 rounded-3xl p-5 shadow-xs">
                    <div className="flex items-center justify-between text-amber-900 mb-2">
                      <span className="text-xs font-extrabold uppercase tracking-wider flex items-center gap-1">
                        <span>🔄</span> คนเดิมกลับมาอ่านซ้ำ
                      </span>
                    </div>
                    <h3 className="text-3xl font-extrabold text-amber-950">
                      {singleBookReaders.returningReaders.toLocaleString()} คน
                    </h3>
                    <div className="mt-1 flex items-center justify-between text-xs font-semibold text-amber-900">
                      <span>คนเดิม: {singleBookReaders.returnRatePercent}%</span>
                      <span>คนใหม่: {100 - singleBookReaders.returnRatePercent}%</span>
                    </div>
                    {/* Visual Ratio Progress Bar */}
                    <div className="mt-1.5 w-full bg-amber-200/60 rounded-full h-1.5 overflow-hidden flex">
                      <div
                        style={{ width: `${singleBookReaders.returnRatePercent}%` }}
                        className="bg-amber-600 h-full"
                        title="คนเดิมที่กลับมาอ่านซ้ำ"
                      />
                      <div
                        style={{ width: `${100 - singleBookReaders.returnRatePercent}%` }}
                        className="bg-emerald-500 h-full"
                        title="ผู้อ่านใหม่"
                      />
                    </div>
                  </div>

                  {/* Card 3: Hot Page */}
                  <div className="bg-gradient-to-br from-orange-500/10 via-orange-500/5 to-transparent border border-orange-300 rounded-3xl p-5 shadow-xs">
                    <div className="flex items-center justify-between text-orange-900 mb-2">
                      <span className="text-xs font-extrabold uppercase tracking-wider flex items-center gap-1">
                        <span>🔥</span> หน้าคนสนใจสูงสุด (Hot Page)
                      </span>
                    </div>
                    <h3 className="text-3xl font-extrabold text-orange-950">
                      หน้า {hotPage?.page_number}
                    </h3>
                    <p className="text-xs text-orange-800 font-semibold mt-1">
                      อ่านเฉลี่ย {hotPage?.avg_duration_seconds} วินาที / ครั้ง
                    </p>
                  </div>

                  {/* Card 4: Avg Session Duration */}
                  <div className="bg-white border border-[#e2dfd5] rounded-3xl p-5 shadow-xs">
                    <div className="flex items-center justify-between text-[#755a47] mb-2">
                      <span className="text-xs font-bold uppercase tracking-wider">เวลาเฉลี่ยต่อผู้อ่าน</span>
                      <div className="p-2 rounded-xl bg-[#243129]/5 text-[#243129]">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </div>
                    </div>
                    <h3 className="text-3xl font-extrabold text-[#17221c]">
                      {avgBookDurationPerReader.toFixed(1)} วินาที
                    </h3>
                    <p className="text-xs text-[#6e746f] mt-1">
                      รวมเวลาอ่าน {formatDuration(totalBookDuration)}
                    </p>
                  </div>
                </div>

                {/* ── Visual Reader Retention Heatmap / Bar Chart ── */}
                <div className="bg-white border border-[#e2dfd5] rounded-3xl p-6 sm:p-8 shadow-xs">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-6 border-b border-[#e2dfd5]">
                    <div>
                      <h3 className="text-lg font-bold text-[#17221c] flex items-center gap-2">
                        <span>กราฟิกวิเคราะห์ความน่าสนใจผู้อ่านรายหน้า</span>
                        <span className="px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 text-[10px] font-bold">
                          Retention Heatmap
                        </span>
                      </h3>
                      <p className="text-xs text-[#6e746f] mt-0.5">
                        เปรียบเทียบระยะเวลาเฉลี่ยที่คนเปิดค้างไว้ในแต่ละหน้า (วินาที)
                      </p>
                    </div>
                    <div className="flex items-center gap-4 text-[11px] text-[#6e746f]">
                      <div className="flex items-center gap-1.5">
                        <span className="w-3 h-3 rounded-full bg-gradient-to-r from-amber-500 to-amber-600" />
                        <span className="font-semibold text-amber-900">หน้าขายดี / คนสนใจสูงสุด 🔥</span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <span className="w-3 h-3 rounded-full bg-gradient-to-r from-[#243129] to-[#3a4d40]" />
                        <span>หน้าทั่วไป</span>
                      </div>
                    </div>
                  </div>

                  {/* Horizontal Bar Chart Container */}
                  <div className="pt-6 space-y-4 max-w-4xl">
                    {pageStats.map((item) => {
                      const isTopHot = hotPage?.page_number === item.page_number;
                      const widthPercent = Math.max((item.avg_duration_seconds / maxAvgDuration) * 100, 6);

                      return (
                        <div key={item.id} className="group flex items-center gap-3">
                          <div className="w-16 text-right font-mono text-xs font-bold text-[#755a47] shrink-0 flex items-center justify-end gap-1">
                            {isTopHot && <span title="หน้า Hot Page!">🔥</span>}
                            <span>หน้า {item.page_number}</span>
                          </div>

                          <div className="flex-1 bg-[#f4f1ea] rounded-xl h-8 p-1 flex items-center relative overflow-hidden">
                            <div
                              style={{ width: `${widthPercent}%` }}
                              className={`h-full rounded-lg transition-all duration-500 flex items-center justify-end pr-3 shadow-xs ${
                                isTopHot
                                  ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-white font-black'
                                  : 'bg-gradient-to-r from-[#243129] to-[#3a4d40] text-[#e8dcc7] font-bold'
                              }`}
                            >
                              <span className="text-xs font-mono drop-shadow-xs">
                                {item.avg_duration_seconds}s
                              </span>
                            </div>
                          </div>

                          <div className="w-20 text-left font-mono text-xs text-[#6e746f] shrink-0 font-medium">
                            ({item.view_count} ครั้ง)
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* ── Page Breakdown Table ── */}
                <div className="bg-white border border-[#e2dfd5] rounded-3xl overflow-hidden shadow-xs">
                  <div className="p-6 border-b border-[#e2dfd5] flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                      <h3 className="text-base font-bold text-[#17221c]">ตารางสถิติและลำดับความสนใจรายหน้า</h3>
                      <p className="text-xs text-[#6e746f] mt-0.5">คลิกจัดเรียงตามเวลา หรือค้นหาตามหมายเลขหน้าได้</p>
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                      {/* Search Page */}
                      <input
                        type="text"
                        placeholder="ค้นหาเลขหน้า..."
                        value={searchPage}
                        onChange={(e) => setSearchPage(e.target.value)}
                        className="w-32 px-3 py-1.5 rounded-xl border border-[#d9d7cd] text-xs font-bold text-[#17221c] outline-none focus:border-[#243129]"
                      />

                      {/* Sort Pills */}
                      <div className="flex items-center gap-1 bg-[#f4f1ea] p-1 rounded-xl">
                        <button
                          onClick={() => setSortBy('page')}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold transition ${
                            sortBy === 'page' ? 'bg-[#243129] text-white shadow-xs' : 'text-[#6e746f] hover:text-[#17221c]'
                          }`}
                        >
                          เรียงตามหน้า
                        </button>
                        <button
                          onClick={() => setSortBy('duration')}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold transition ${
                            sortBy === 'duration' ? 'bg-[#243129] text-white shadow-xs' : 'text-[#6e746f] hover:text-[#17221c]'
                          }`}
                        >
                          อ่านนานสุด 🔥
                        </button>
                        <button
                          onClick={() => setSortBy('views')}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold transition ${
                            sortBy === 'views' ? 'bg-[#243129] text-white shadow-xs' : 'text-[#6e746f] hover:text-[#17221c]'
                          }`}
                        >
                          เปิดดูบ่อยสุด 👁️
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-[#fbfaf8] border-b border-[#e2dfd5] text-[#755a47] font-bold uppercase tracking-wider text-[11px]">
                        <tr>
                          <th className="py-3 px-6">หมายเลขหน้า</th>
                          <th className="py-3 px-4 text-center">ยอดเปิดอ่านทั้งหมด</th>
                          <th className="py-3 px-4 text-center">เวลาเปิดค้างเฉลี่ย</th>
                          <th className="py-3 px-4 text-center">เวลารวมทั้งหมด</th>
                          <th className="py-3 px-6 text-center">ดัชนีความน่าสนใจ</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#e2dfd5]">
                        {filteredSortedStats.map((item) => {
                          const isTop = hotPage?.page_number === item.page_number;
                          return (
                            <tr key={item.id} className="hover:bg-[#faf8f5] transition-colors">
                              <td className="py-3.5 px-6 font-bold text-sm">
                                <div className="flex items-center gap-2">
                                  <span>หน้า {item.page_number}</span>
                                  {isTop && (
                                    <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-900 text-[10px] font-extrabold border border-amber-300">
                                      🔥 อ่านนานสุด
                                    </span>
                                  )}
                                </div>
                              </td>
                              <td className="py-3.5 px-4 text-center font-bold text-[#17221c]">
                                {item.view_count.toLocaleString()} ครั้ง
                              </td>
                              <td className="py-3.5 px-4 text-center font-mono font-bold text-emerald-800">
                                {item.avg_duration_seconds} วินาที
                              </td>
                              <td className="py-3.5 px-4 text-center font-mono text-[#6e746f]">
                                {formatDuration(item.total_duration_seconds)}
                              </td>
                              <td className="py-3.5 px-6 text-center">
                                <div className="flex items-center justify-center gap-2">
                                  <div className="w-24 bg-neutral-200 rounded-full h-2 overflow-hidden">
                                    <div
                                      style={{ width: `${Math.min((item.avg_duration_seconds / maxAvgDuration) * 100, 100)}%` }}
                                      className={`h-full rounded-full ${
                                        isTop ? 'bg-amber-500' : 'bg-emerald-600'
                                      }`}
                                    />
                                  </div>
                                  <span className="text-[11px] font-mono text-[#6e746f]">
                                    {Math.round((item.avg_duration_seconds / maxAvgDuration) * 100)}%
                                  </span>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}

export default function AnalyticsDashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-[#f6f4ee] flex items-center justify-center">
          <div className="w-10 h-10 border-3 border-[#243129] border-t-transparent rounded-full animate-spin" />
        </div>
      }
    >
      <AnalyticsDashboardContent />
    </Suspense>
  );
}
