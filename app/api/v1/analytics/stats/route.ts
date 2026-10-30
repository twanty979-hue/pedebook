import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const catalogId = searchParams.get('catalogId');

    if (!catalogId) {
      return NextResponse.json({ error: 'Missing catalogId parameter' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
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

    // Mock data for initial review before Supabase credentials are inserted
    const mockStats = Array.from({ length: 8 }, (_, i) => {
      const page = i + 1;
      const views = Math.floor(Math.random() * 80) + 15;
      const avg = page === 4 || page === 1 ? (Math.random() * 25 + 20) : (Math.random() * 8 + 3);
      return {
        id: `mock-${page}`,
        catalog_id: catalogId,
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
