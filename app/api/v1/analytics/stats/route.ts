import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const catalogId = searchParams.get('catalogId');
    const userId = searchParams.get('userId');

    if (isSupabaseConfigured()) {
      // กรณีระบุ catalogId เฉพาะเล่ม
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

        const { data, error } = await supabaseAdmin
          .from('catalog_page_stats')
          .select('*')
          .eq('catalog_id', targetCatalogId)
          .order('page_number', { ascending: true });

        if (error) {
          return NextResponse.json({ error: error.message }, { status: 500 });
        }

        return NextResponse.json({ success: true, stats: data || [] });
      }

      // กรณีขอสถิติภาพรวมทุกเล่ม (Overview / Multi-Book)
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

      // ดึงสถิติของทุกหน้า
      const { data: allStats, error: statsError } = await supabaseAdmin
        .from('catalog_page_stats')
        .select('*');

      if (statsError) {
        return NextResponse.json({ error: statsError.message }, { status: 500 });
      }

      const statsMap = new Map<string, any[]>();
      (allStats || []).forEach((st) => {
        if (!statsMap.has(st.catalog_id)) {
          statsMap.set(st.catalog_id, []);
        }
        statsMap.get(st.catalog_id)!.push(st);
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
        };
      });

      const totalGlobalViews = catalogSummaries.reduce((sum, c) => sum + c.totalViews, 0);
      const totalGlobalDuration = catalogSummaries.reduce((sum, c) => sum + c.totalDurationSeconds, 0);

      return NextResponse.json({
        success: true,
        overview: {
          totalCatalogs: catalogSummaries.length,
          totalViews: totalGlobalViews,
          totalDurationSeconds: totalGlobalDuration,
          catalogs: catalogSummaries,
        },
      });
    }

    // Mock data fallback
    const mockStats = Array.from({ length: 8 }, (_, i) => {
      const page = i + 1;
      const views = Math.floor(Math.random() * 80) + 15;
      const avg = page === 4 || page === 1 ? Math.random() * 25 + 20 : Math.random() * 8 + 3;
      return {
        id: `mock-${page}`,
        catalog_id: catalogId || 'mock',
        page_number: page,
        view_count: views,
        total_duration_seconds: Math.round(views * avg),
        avg_duration_seconds: Number(avg.toFixed(1)),
        updated_at: new Date().toISOString(),
      };
    });

    return NextResponse.json({
      success: true,
      stats: mockStats,
      isMock: true,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
