import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

type RouteContext = {
  params: Promise<{ id: string }>;
};

// GET: Fetch a single catalog by ID
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id } = await params;

    if (!id) {
      return NextResponse.json({ error: 'Missing catalog id' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
      const { data, error } = await supabaseAdmin
        .from('catalogs')
        .select('*, catalog_page_stats(*)')
        .eq('id', id)
        .single();

      if (error) return NextResponse.json({ error: error.message }, { status: 404 });
      return NextResponse.json({ success: true, catalog: data });
    }

    return NextResponse.json({
      success: true,
      catalog: { id, title: 'Demo Catalog', isMock: true },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

// PATCH / PUT: Update catalog metadata (Title, Theme, SEO, Visibility)
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  try {
    const { id } = await params;
    const body = await request.json();
    const {
      title,
      fileName,
      bgType,
      bgValue,
      isFloating,
      isPublic,
      allowIndexing,
      seoDescription,
      pdfUrl,
      storageKey,
      fileSizeBytes,
    } = body;

    if (!id) {
      return NextResponse.json({ error: 'Missing catalog id' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
      const updatePayload: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (title !== undefined) updatePayload.title = title;
      if (fileName !== undefined) updatePayload.file_name = fileName;
      if (bgType !== undefined) updatePayload.bg_type = bgType;
      if (bgValue !== undefined) updatePayload.bg_value = bgValue;
      if (isFloating !== undefined) updatePayload.is_floating = Boolean(isFloating);
      if (isPublic !== undefined) updatePayload.is_public = Boolean(isPublic);
      if (allowIndexing !== undefined) updatePayload.allow_indexing = Boolean(allowIndexing);
      if (seoDescription !== undefined) updatePayload.seo_description = seoDescription;
      if (pdfUrl !== undefined) updatePayload.pdf_url = pdfUrl;
      if (storageKey !== undefined) updatePayload.storage_key = storageKey;
      if (fileSizeBytes !== undefined) updatePayload.file_size_bytes = Number(fileSizeBytes);

      const { data, error } = await supabaseAdmin
        .from('catalogs')
        .update(updatePayload)
        .eq('id', id)
        .select()
        .single();

      if (error) return NextResponse.json({ error: error.message }, { status: 400 });
      return NextResponse.json({ success: true, catalog: data });
    }

    return NextResponse.json({
      success: true,
      catalog: { id, ...body },
      message: 'Updated in demo mode',
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

// DELETE: Delete a catalog
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  try {
    const { id } = await params;

    if (!id) {
      return NextResponse.json({ error: 'Missing catalog id' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
      // 1. Get storage_key to clean up from R2
      const { data: catalog } = await supabaseAdmin
        .from('catalogs')
        .select('storage_key')
        .eq('id', id)
        .single();

      // 2. Delete from database (Cascades to page_stats and analytics_logs)
      const { error } = await supabaseAdmin
        .from('catalogs')
        .delete()
        .eq('id', id);

      if (error) return NextResponse.json({ error: error.message }, { status: 400 });

      // 3. Delete from R2 if configured
      if (catalog?.storage_key) {
        try {
          await fetch(`${process.env.NEXT_PUBLIC_SITE_URL || ''}/api/delete-file`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ key: catalog.storage_key }),
          });
        } catch (e) {
          console.warn('R2 file deletion warning:', e);
        }
      }

      return NextResponse.json({ success: true, message: 'Deleted catalog successfully' });
    }

    return NextResponse.json({ success: true, message: 'Deleted in demo mode' });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
