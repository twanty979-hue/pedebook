import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

function toValidUuid(id: string): string {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (uuidRegex.test(id)) return id;

  let hash = 0;
  for (let i = 0; i < id.length; i++) {
    hash = (hash << 5) - hash + id.charCodeAt(i);
    hash |= 0;
  }
  const hex = Math.abs(hash).toString(16).padStart(8, '0');
  return `00000000-0000-4000-8000-${hex.padStart(12, '0')}`;
}

async function ensureProfileExists(userId: string) {
  const targetId = toValidUuid(userId);
  const { data: existing } = await supabaseAdmin
    .from('profiles')
    .select('id')
    .eq('id', targetId)
    .maybeSingle();

  if (!existing) {
    try {
      await supabaseAdmin.auth.admin.createUser({
        id: targetId,
        email: `${userId.replace(/[^a-zA-Z0-9]/g, '').slice(0, 20) || 'user'}@pedebook.guest`,
        email_confirm: true,
        user_metadata: { display_name: 'Creator' },
      });
    } catch (e: any) {
      console.warn('Profile auto-provision note:', e?.message);
    }
  }
  return targetId;
}

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
        query = query.eq('user_id', toValidUuid(userId));
      }

      const { data, error } = await query;
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      return NextResponse.json({ success: true, catalogs: data || [] });
    }

    return NextResponse.json({
      success: true,
      catalogs: [],
      message: 'Supabase pending configuration.',
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
      const validUserId = await ensureProfileExists(userId);

      const { data, error } = await supabaseAdmin
        .from('catalogs')
        .insert({
          user_id: validUserId,
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
