import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';

// GET: List team details & members
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const teamId = searchParams.get('teamId');
    const userId = searchParams.get('userId');

    if (!isSupabaseConfigured()) {
      return NextResponse.json({
        success: true,
        team: {
          id: teamId || 'demo-team',
          name: 'ทีมงานการตลาดและฝ่ายขาย',
          plan: 'business',
          max_members: 10,
        },
        members: [
          { id: '1', invited_email: 'owner@example.com', role: 'owner', status: 'accepted' },
          { id: '2', invited_email: 'designer@example.com', role: 'editor', status: 'accepted' },
          { id: '3', invited_email: 'sales@example.com', role: 'viewer', status: 'pending' },
        ],
        isMock: true,
      });
    }

    if (teamId) {
      const { data: team, error: teamErr } = await supabaseAdmin
        .from('teams')
        .select('*')
        .eq('id', teamId)
        .single();

      if (teamErr) return NextResponse.json({ error: teamErr.message }, { status: 404 });

      const { data: members, error: memErr } = await supabaseAdmin
        .from('team_members')
        .select('*')
        .eq('team_id', teamId);

      if (memErr) return NextResponse.json({ error: memErr.message }, { status: 500 });

      return NextResponse.json({ success: true, team, members });
    }

    if (userId) {
      // Find teams owned by or member of
      const { data: teams, error } = await supabaseAdmin
        .from('teams')
        .select('*, team_members(*)')
        .eq('owner_id', userId);

      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      return NextResponse.json({ success: true, teams });
    }

    return NextResponse.json({ error: 'Missing teamId or userId' }, { status: 400 });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

// POST: Invite new team member (Enforces max 10 members check)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { teamId, email, role } = body;

    if (!teamId || !email) {
      return NextResponse.json({ error: 'กรุณาระบุ Team ID และ Email ของผู้รับเชิญ' }, { status: 400 });
    }

    if (!isSupabaseConfigured()) {
      return NextResponse.json({
        success: true,
        message: `ส่งคำเชิญไปยัง ${email} เรียบร้อยแล้ว (Demo Mode)`,
      });
    }

    // Check current count
    const { count, error: countErr } = await supabaseAdmin
      .from('team_members')
      .select('*', { count: 'exact', head: true })
      .eq('team_id', teamId);

    if (countErr) return NextResponse.json({ error: countErr.message }, { status: 500 });

    if ((count ?? 0) >= 10) {
      return NextResponse.json(
        { error: 'ทีมมีสมาชิกครบ 10 คนแล้วครับ (จำกัดสูงสุด 10 คนต่อทีมสำหรับแพ็กเกจ Business)' },
        { status: 400 }
      );
    }

    const { data, error } = await supabaseAdmin
      .from('team_members')
      .insert({
        team_id: teamId,
        invited_email: email.trim().toLowerCase(),
        role: role || 'editor',
        status: 'pending',
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ success: true, member: data });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
