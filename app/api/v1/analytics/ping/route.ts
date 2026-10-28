import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      catalogId,
      pageNumber,
      durationSeconds,
      sessionId,
      deviceType,
    } = body;

    if (!catalogId || pageNumber === undefined || durationSeconds === undefined) {
      return NextResponse.json({ error: 'Missing required analytics parameters' }, { status: 400 });
    }

    const duration = Math.min(Math.max(Number(durationSeconds) || 0, 0.1), 600); // capped at 10 minutes
    const session = sessionId || 'anon_session';
    const device = deviceType || 'desktop';
    const userAgent = request.headers.get('user-agent') || '';
    const referrer = request.headers.get('referer') || '';

    // If Supabase is configured, use the atomic RPC stored procedure
    if (isSupabaseConfigured()) {
      const { error } = await (supabaseAdmin.rpc as any)('record_page_stay_time', {
        p_catalog_id: catalogId,
        p_page_number: Number(pageNumber),
        p_duration_seconds: duration,
        p_session_id: session,
        p_device_type: device,
        p_user_agent: userAgent,
        p_referrer: referrer,
      });

      if (error) {
        console.error('Supabase RPC record_page_stay_time error:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
      }
    } else {
      // In-memory / development fallback log
      console.log(`[Analytics Ping Fallback] Catalog: ${catalogId}, Page: ${pageNumber}, Stay: ${duration.toFixed(1)}s, Session: ${session}`);
    }

    return NextResponse.json({ success: true, recorded: { pageNumber, duration } });
  } catch (err: unknown) {
    console.error('Analytics ping error:', err);
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
