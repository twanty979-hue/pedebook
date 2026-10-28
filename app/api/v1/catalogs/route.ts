import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

// GET: Fetch catalogs for a user or team
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const teamId = searchParams.get('teamId');
    const slug = searchParams.get('slug');

    if (slug) {
      if (isSupabaseConfigured()) {
        const { data, error } = await supabaseAdmin
          .from('catalogs')
          .select('*')
          .eq('slug', slug)
          .single();

        if (error) return NextResponse.json({ error: error.message }, { status: 404 });
        return NextResponse.json({ success: true, catalog: data });
      }
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 501 });
    }

    if (!userId && !teamId) {
      return NextResponse.json({ error: 'Missing userId or teamId' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
      let query = supabaseAdmin.from('catalogs').select('*').order('created_at', { ascending: false });

      if (teamId) {
        query = query.eq('team_id', teamId);
      } else if (userId) {
        query = query.eq('user_id', userId);
      }

      const { data, error } = await query;
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      return NextResponse.json({ success: true, catalogs: data || [] });
    }

    // Fallback response for testing before keys are provided
    return NextResponse.json({
      success: true,
      catalogs: [],
      message: 'Supabase pending configuration. Ready for keys.',
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

// POST: Create new catalog (Mobile App & Web compatible)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      userId,
      teamId,
      slug,
      title,
      fileName,
      pdfUrl,
      storageKey,
      fileSizeBytes,
      pageCount,
      bgType,
      bgValue,
      isFloating,
      isPublic,
      allowIndexing,
      seoDescription,
    } = body;

    if (!userId || !slug || !fileName || !pdfUrl) {
      return NextResponse.json({ error: 'Missing required catalog parameters' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
      const { data, error } = await supabaseAdmin
        .from('catalogs')
        .insert({
          user_id: userId,
          team_id: teamId || null,
          slug,
          title: title || fileName.replace(/\.pdf$/i, ''),
          file_name: fileName,
          pdf_url: pdfUrl,
          storage_key: storageKey || slug,
          file_size_bytes: Number(fileSizeBytes) || 0,
          page_count: Number(pageCount) || 0,
          bg_type: bgType || 'gradient',
          bg_value: bgValue || 'auto',
          is_floating: isFloating ?? false,
          is_public: isPublic !== false,
          allow_indexing: allowIndexing === true,
          seo_description: seoDescription || null,
        })
        .select()
        .single();

      if (error) return NextResponse.json({ error: error.message }, { status: 400 });
      return NextResponse.json({ success: true, catalog: data });
    }

    return NextResponse.json({
      success: true,
      catalog: { slug, title, fileName, pdfUrl },
      message: 'Created in demo mode (Supabase pending keys)',
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
