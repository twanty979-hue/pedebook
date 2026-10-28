import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/app/src/lib/supabase/server';
import { isSupabaseConfigured } from '@/app/src/lib/supabase/client';
import { PLANS, PlanId } from '@/app/src/lib/plans';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');

    if (!userId) {
      return NextResponse.json({ error: 'Missing userId parameter' }, { status: 400 });
    }

    if (isSupabaseConfigured()) {
      const { data: profile, error } = await supabaseAdmin
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        return NextResponse.json({ error: error.message }, { status: 404 });
      }

      const profileData = profile as Record<string, any>;
      const planKey = (profileData.current_plan as PlanId) || 'free';
      const planConfig = PLANS[planKey] || PLANS.free;
      const storageUsed = Number(profileData.storage_used_bytes) || 0;
      const isOverQuota = planKey === 'free' && storageUsed > (100 * 1024 * 1024);

      return NextResponse.json({
        success: true,
        profile,
        plan: planConfig,
        storageUsedBytes: storageUsed,
        storageUsedMb: Number((storageUsed / (1024 * 1024)).toFixed(1)),
        isOverQuota,
        adsActive: isOverQuota,
      });
    }

    return NextResponse.json({
      success: true,
      profile: {
        id: userId,
        current_plan: 'free',
        storage_used_bytes: 0,
      },
      plan: PLANS.free,
      storageUsedBytes: 0,
      storageUsedMb: 0,
      isOverQuota: false,
      adsActive: false,
      isMock: true,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
