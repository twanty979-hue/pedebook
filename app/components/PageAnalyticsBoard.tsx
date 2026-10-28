'use client';

import React, { useEffect, useState } from 'react';

export interface PageStatItem {
  id: string;
  catalog_id: string;
  page_number: number;
  view_count: number;
  total_duration_seconds: number;
  avg_duration_seconds: number;
  updated_at: string;
}

interface PageAnalyticsBoardProps {
  catalogId: string;
  catalogTitle: string;
  onClose?: () => void;
}

export default function PageAnalyticsBoard({
  catalogId,
  catalogTitle,
  onClose,
}: PageAnalyticsBoardProps) {
  const [stats, setStats] = useState<PageStatItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [sortBy, setSortBy] = useState<'page' | 'duration' | 'views'>('page');

  useEffect(() => {
    async function fetchStats() {
      setLoading(true);
      try {
        const res = await fetch(`/api/v1/analytics/stats?catalogId=${catalogId}`);
        const data = await res.json();
        if (data.success && data.stats) {
          setStats(data.stats);
        }
      } catch (err) {
        console.error('Failed to load page stats:', err);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, [catalogId]);

  // Derived statistics
  const totalViews = stats.reduce((acc, curr) => acc + curr.view_count, 0);
  const maxDuration = Math.max(...stats.map((s) => s.avg_duration_seconds), 1);
  const maxViews = Math.max(...stats.map((s) => s.view_count), 1);

  // Find Hot Page (longest avg duration)
  const hotPage = stats.length > 0
    ? [...stats].sort((a, b) => b.avg_duration_seconds - a.avg_duration_seconds)[0]
    : null;

  // Most viewed page
  const mostViewedPage = stats.length > 0
    ? [...stats].sort((a, b) => b.view_count - a.view_count)[0]
    : null;

  // Sorted list for table
  const sortedStats = [...stats].sort((a, b) => {
    if (sortBy === 'duration') return b.avg_duration_seconds - a.avg_duration_seconds;
    if (sortBy === 'views') return b.view_count - a.view_count;
    return a.page_number - b.page_number;
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fade-in" onClick={onClose}>
      <div
        className="bg-white rounded-3xl p-6 sm:p-8 max-w-4xl w-full border border-[#e2dfd5] shadow-2xl relative max-h-[90vh] flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-start justify-between pb-5 border-b border-[#e2dfd5] shrink-0">
          <div>
            <div className="inline-flex items-center gap-1.5 bg-emerald-50 text-emerald-800 text-[11px] font-bold px-2.5 py-0.5 rounded-full mb-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span>สถิติพฤติกรรมการเปิดอ่านแยกรายหน้า (Page Analytics)</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black text-[#17221c] truncate max-w-lg">
              {catalogTitle}
            </h2>
            <p className="text-xs text-[#6e746f] mt-1">
              วิเคราะห์ความสนใจของผู้อ่าน: หน้าไหนคนเปิดอ่านนานที่สุด และหน้าไหนถูกพลิกผ่านเร็ว
            </p>
          </div>
          {onClose && (
            <button
              onClick={onClose}
              className="text-[#6e746f] hover:text-[#17221c] p-2 rounded-full hover:bg-neutral-100 transition cursor-pointer"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>

        {/* Content Body */}
        <div className="overflow-y-auto flex-1 py-6 space-y-6 pr-1">
          {loading ? (
            <div className="py-16 text-center text-xs text-[#6e746f]">
              <div className="w-8 h-8 border-3 border-[#243129] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
              กำลังโหลดข้อมูลสถิติรายหน้า...
            </div>
          ) : stats.length === 0 ? (
            <div className="py-16 text-center text-xs text-[#6e746f] bg-[#f7f5f0] rounded-2xl border border-dashed border-[#d9d5cb]">
              <p className="font-bold text-sm text-[#17221c] mb-1">ยังไม่มีข้อมูลการเปิดอ่าน</p>
              <p>เมื่อมีผู้อ่านเปิดสมุดเล่มนี้ ระบบจะเริ่มบันทึกเวลาที่คนเปิดค้างไว้ในแต่ละหน้าทันทีครับ</p>
            </div>
          ) : (
            <>
              {/* Highlights 3 Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {/* Hot Page */}
                <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-amber-900 mb-1">
                    <span>🔥 หน้าคนสนใจมากที่สุด (Hot Page)</span>
                  </div>
                  {hotPage ? (
                    <div>
                      <p className="text-2xl font-black text-amber-950">หน้า {hotPage.page_number}</p>
                      <p className="text-[11px] text-amber-800 mt-1 font-semibold">
                        อ่านเฉลี่ย <strong className="text-amber-950 font-bold">{hotPage.avg_duration_seconds} วินาที</strong> / ครั้ง
                      </p>
                    </div>
                  ) : (
                    <p className="text-xs text-[#6e746f]">-</p>
                  )}
                </div>

                {/* Most Viewed */}
                <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-900 mb-1">
                    <span>👀 หน้าที่เปิดดูบ่อยที่สุด</span>
                  </div>
                  {mostViewedPage ? (
                    <div>
                      <p className="text-2xl font-black text-emerald-950">หน้า {mostViewedPage.page_number}</p>
                      <p className="text-[11px] text-emerald-800 mt-1 font-semibold">
                        ยอดเปิดดู <strong className="text-emerald-950 font-bold">{mostViewedPage.view_count.toLocaleString()} ครั้ง</strong>
                      </p>
                    </div>
                  ) : (
                    <p className="text-xs text-[#6e746f]">-</p>
                  )}
                </div>

                {/* Total Stats */}
                <div className="p-4 rounded-2xl bg-[#f5f3ee] border border-[#e2dfd5]">
                  <div className="text-xs font-bold text-[#755a47] mb-1">
                    <span>📊 ข้อมูลรวมทั้งหมด</span>
                  </div>
                  <p className="text-2xl font-black text-[#17221c]">{stats.length} หน้า</p>
                  <p className="text-[11px] text-[#6e746f] mt-1 font-semibold">
                    ยอดเปิดหน้าสะสมรวม {totalViews.toLocaleString()} ครั้ง
                  </p>
                </div>
              </div>

              {/* Visual Heatmap / Bar Chart */}
              <div className="bg-[#f7f5f0] p-5 rounded-2xl border border-[#e2dfd5]">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-[#755a47]">
                    กราฟเปรียบเทียบระยะเวลาที่คนเปิดค้างไว้ในแต่ละหน้า (วินาที)
                  </h3>
                  <span className="text-[10px] text-[#6e746f]">สีเข้ม = หน้าที่มีคนอ่านนานเป็นพิเศษ</span>
                </div>

                <div className="space-y-2.5">
                  {stats.map((s) => {
                    const pct = Math.min(100, Math.round((s.avg_duration_seconds / maxDuration) * 100));
                    const isHot = hotPage && hotPage.page_number === s.page_number;

                    return (
                      <div key={s.page_number} className="flex items-center gap-3 text-xs">
                        <span className="w-16 font-bold text-[#17221c] shrink-0 text-right">
                          หน้า {s.page_number} {isHot && '🔥'}
                        </span>
                        <div className="flex-1 bg-[#e8e4db] h-5 rounded-full overflow-hidden relative">
                          <div
                            className={`h-full rounded-full transition-all duration-500 flex items-center justify-end pr-2 text-[10px] font-bold ${
                              isHot
                                ? 'bg-amber-600 text-white'
                                : 'bg-[#243129] text-[#e8dcc7]'
                            }`}
                            style={{ width: `${Math.max(pct, 12)}%` }}
                          >
                            {s.avg_duration_seconds}s
                          </div>
                        </div>
                        <span className="w-20 text-[11px] text-[#6e746f] shrink-0 text-right">
                          ({s.view_count} ครั้ง)
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Detailed Table */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-[#755a47]">
                    ตารางรายละเอียดรายหน้า
                  </h3>
                  <div className="flex items-center gap-1.5 text-xs">
                    <span className="text-[#6e746f] text-[11px]">เรียงตาม:</span>
                    <button
                      onClick={() => setSortBy('page')}
                      className={`px-2.5 py-1 rounded-full text-[11px] font-semibold transition cursor-pointer ${
                        sortBy === 'page' ? 'bg-[#243129] text-white' : 'bg-neutral-100 text-[#6e746f]'
                      }`}
                    >
                      หมายเลขหน้า
                    </button>
                    <button
                      onClick={() => setSortBy('duration')}
                      className={`px-2.5 py-1 rounded-full text-[11px] font-semibold transition cursor-pointer ${
                        sortBy === 'duration' ? 'bg-[#243129] text-white' : 'bg-neutral-100 text-[#6e746f]'
                      }`}
                    >
                      เวลาอ่านนานสุด
                    </button>
                    <button
                      onClick={() => setSortBy('views')}
                      className={`px-2.5 py-1 rounded-full text-[11px] font-semibold transition cursor-pointer ${
                        sortBy === 'views' ? 'bg-[#243129] text-white' : 'bg-neutral-100 text-[#6e746f]'
                      }`}
                    >
                      ยอดเปิดดู
                    </button>
                  </div>
                </div>

                <div className="border border-[#e2dfd5] rounded-2xl overflow-hidden">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-[#f2efe9] text-[#755a47] uppercase font-bold text-[10px]">
                      <tr>
                        <th className="py-3 px-4">หน้า</th>
                        <th className="py-3 px-4">ยอดเปิดอ่านทั้งหมด</th>
                        <th className="py-3 px-4">เวลาเปิดค้างเฉลี่ย</th>
                        <th className="py-3 px-4">เวลารวมทั้งหมด</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#e2dfd5]">
                      {sortedStats.map((item) => (
                        <tr key={item.page_number} className="hover:bg-neutral-50 transition">
                          <td className="py-3 px-4 font-bold text-[#17221c]">
                            หน้า {item.page_number}
                            {hotPage?.page_number === item.page_number && (
                              <span className="ml-2 text-[10px] bg-amber-100 text-amber-900 px-2 py-0.5 rounded-full font-bold">
                                อ่านนานสุด 🔥
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-4 text-[#17221c]">
                            {item.view_count.toLocaleString()} ครั้ง
                          </td>
                          <td className="py-3 px-4 font-bold text-emerald-800">
                            {item.avg_duration_seconds} วินาที
                          </td>
                          <td className="py-3 px-4 text-[#6e746f]">
                            {Math.round(item.total_duration_seconds)} วินาที
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="pt-4 border-t border-[#e2dfd5] flex items-center justify-between shrink-0">
          <p className="text-[11px] text-[#6e746f]">
            💡 ข้อมูลจะถูกประมวลผลและอัปเดตแบบเรียลไทม์ทุกครั้งที่มีการเปิดหน้าสมุด
          </p>
          {onClose && (
            <button
              onClick={onClose}
              className="px-5 py-2 rounded-full bg-[#243129] text-[#e8dcc7] font-bold text-xs hover:bg-[#314238] transition cursor-pointer"
            >
              ปิดหน้าต่าง
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
