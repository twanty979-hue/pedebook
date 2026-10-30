import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const catalogId = searchParams.get('catalogId');
    const userId = searchParams.get('userId');

    if (isSupabaseConfigured()) {
      // ══════════════════════════════════════════════════════════════
      // 1. กรณีระบุ catalogId เฉพาะเล่ม (Single Book Analytics)
      // ══════════════════════════════════════════════════════════════
      if (catalogId && catalogId !== 'all') {
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        let targetCatalogId = catalogId;

        if (!uuidRegex.test(catalogId)) {
          // ค้นหา ID จริงของหนังสือจาก Supabase โดยใช้ slug
          const { data: cat } = await supabaseAdmin
            .from('catalogs')
            .select('id')
            .eq('slug', catalogId)
            .maybeSingle();

          if (cat?.id) {
            targetCatalogId = cat.id;
          }
        }

        // ดึงสถิติรายหน้า
        const { data: pageData, error: pageError } = await supabaseAdmin
          .from('catalog_page_stats')
          .select('*')
          .eq('catalog_id', targetCatalogId)
          .order('page_number', { ascending: true });

        if (pageError) {
          return NextResponse.json({ error: pageError.message }, { status: 500 });
        }

        // ดึงสถิติตัวตนคนอ่านจริง (Unique Readers vs Returning Readers) จาก catalog_readers
        const { data: readersData, error: readersError } = await supabaseAdmin
          .from('catalog_readers')
          .select('reader_id, visit_count, first_seen_at, last_seen_at, total_read_seconds, device_type')
          .eq('catalog_id', targetCatalogId);

        if (readersError) {
          console.warn('catalog_readers query warning:', readersError.message);
        }

        const readers = readersData || [];
        const totalUniqueReaders = readers.length;
        const returningReaders = readers.filter((r) => Number(r.visit_count) > 1).length;
        const newReaders = readers.filter((r) => Number(r.visit_count) <= 1).length;
        const returnRatePercent = totalUniqueReaders > 0 ? Math.round((returningReaders / totalUniqueReaders) * 100) : 0;

        return NextResponse.json({
          success: true,
          stats: pageData || [],
          readers: {
            totalUniqueReaders,
            returningReaders,
            newReaders,
            returnRatePercent,
          },
        });
      }

      // ══════════════════════════════════════════════════════════════
      // 2. กรณีขอสถิติภาพรวมทุกเล่ม (Overview / Multi-Book Analytics)
      // ══════════════════════════════════════════════════════════════
      let catalogQuery = supabaseAdmin
        .from('catalogs')
        .select('id, slug, file_name, display_title, cover_image, file_size_bytes, created_at, user_id')
        .order('created_at', { ascending: false });

      if (userId) {
        catalogQuery = catalogQuery.eq('user_id', userId);
      }

      const { data: catalogs, error: catError } = await catalogQuery;
      if (catError) {
        return NextResponse.json({ error: catError.message }, { status: 500 });
      }

      const catalogIds = (catalogs || []).map((c) => c.id);

      // ดึงสถิติของทุกหน้า
      const { data: allStats, error: statsError } = await supabaseAdmin
        .from('catalog_page_stats')
        .select('*');

      if (statsError) {
        return NextResponse.json({ error: statsError.message }, { status: 500 });
      }

      // ดึงข้อมูลผู้อ่านจาก catalog_readers สำหรับทุกเล่ม
      let readersQuery = supabaseAdmin.from('catalog_readers').select('*');
      if (catalogIds.length > 0) {
        readersQuery = readersQuery.in('catalog_id', catalogIds);
      }
      const { data: allReaders } = await readersQuery;

      const statsMap = new Map<string, any[]>();
      (allStats || []).forEach((st) => {
        if (!statsMap.has(st.catalog_id)) {
          statsMap.set(st.catalog_id, []);
        }
        statsMap.get(st.catalog_id)!.push(st);
      });

      const readersMap = new Map<string, any[]>();
      (allReaders || []).forEach((r) => {
        if (!readersMap.has(r.catalog_id)) {
          readersMap.set(r.catalog_id, []);
        }
        readersMap.get(r.catalog_id)!.push(r);
      });

      const catalogSummaries = (catalogs || []).map((cat) => {
        const pStats = statsMap.get(cat.id) || [];
        const totalViews = pStats.reduce((sum, p) => sum + (Number(p.view_count) || 0), 0);
        const totalDuration = pStats.reduce((sum, p) => sum + (Number(p.total_duration_seconds) || 0), 0);
        const avgDuration = totalViews > 0 ? totalDuration / totalViews : 0;
        const pageCount = pStats.length;
        const sortedByDuration = [...pStats].sort(
          (a, b) => (Number(b.avg_duration_seconds) || 0) - (Number(a.avg_duration_seconds) || 0)
        );
        const topPage = sortedByDuration.length > 0 ? sortedByDuration[0].page_number : 1;

        // Reader metrics for this book
        const catReaders = readersMap.get(cat.id) || [];
        const uniqueReaders = catReaders.length;
        const returningCount = catReaders.filter((r) => Number(r.visit_count) > 1).length;
        const newCount = catReaders.filter((r) => Number(r.visit_count) <= 1).length;
        const returnRate = uniqueReaders > 0 ? Math.round((returningCount / uniqueReaders) * 100) : 0;

        return {
          id: cat.id,
          slug: cat.slug,
          fileName: cat.file_name,
          displayTitle: cat.display_title || cat.file_name?.replace(/\.pdf$/i, '').replace(/-/g, ' '),
          coverImage: cat.cover_image,
          size: Number(cat.file_size_bytes || 0),
          createdAt: cat.created_at,
          totalViews,
          totalDurationSeconds: Math.round(totalDuration),
          avgDurationSeconds: Number(avgDuration.toFixed(1)),
          pageCount,
          topPage,
          uniqueReaders,
          returningCount,
          newCount,
          returnRate,
        };
      });

      const totalGlobalViews = catalogSummaries.reduce((sum, c) => sum + c.totalViews, 0);
      const totalGlobalDuration = catalogSummaries.reduce((sum, c) => sum + c.totalDurationSeconds, 0);

      // Global Unique Readers across all books
      const allUniqueReaderSet = new Set((allReaders || []).map((r) => r.reader_id));
      const totalGlobalUniqueReaders = allUniqueReaderSet.size;
      const totalGlobalReturningReaders = (allReaders || []).filter((r) => Number(r.visit_count) > 1).length;
      const totalGlobalNewReaders = (allReaders || []).filter((r) => Number(r.visit_count) <= 1).length;
      const globalReturnRate = totalGlobalUniqueReaders > 0
        ? Math.round((totalGlobalReturningReaders / (totalGlobalReturningReaders + totalGlobalNewReaders || 1)) * 100)
        : 0;

      return NextResponse.json({
        success: true,
        overview: {
          totalCatalogs: catalogSummaries.length,
          totalViews: totalGlobalViews,
          totalDurationSeconds: totalGlobalDuration,
          totalUniqueReaders: totalGlobalUniqueReaders,
          totalReturningReaders: totalGlobalReturningReaders,
          totalNewReaders: totalGlobalNewReaders,
          returnRatePercent: globalReturnRate,
          catalogs: catalogSummaries,
        },
      });
    }

    return NextResponse.json({
      success: true,
      stats: [],
      readers: {
        totalUniqueReaders: 0,
        returningReaders: 0,
        newReaders: 0,
        returnRatePercent: 0,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
