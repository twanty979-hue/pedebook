'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase, isSupabaseConfigured } from '@/app/src/lib/supabase/client';
import { syncUserProfile } from '@/app/src/lib/user-tracking';

export default function AuthCallbackPage() {
  const router = useRouter();
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    async function handleAuth() {
      if (!isSupabaseConfigured()) {
        if (isMounted) {
          setErrorMsg('ระบบ Supabase ยังไม่ได้ตั้งค่าใน .env.local ครับ');
          setTimeout(() => router.replace('/login'), 2500);
        }
        return;
      }

      // 1. ตรวจสอบข้อผิดพลาดจาก Query หรือ Hash URL
      if (typeof window !== 'undefined') {
        const searchParams = new URLSearchParams(window.location.search);
        const hashParams = new URLSearchParams(window.location.hash.replace(/^#/, ''));
        const error = searchParams.get('error') || hashParams.get('error');
        const errorDesc =
          searchParams.get('error_description') || hashParams.get('error_description');

        if (error) {
          console.error('OAuth Callback Error:', error, errorDesc);
          if (isMounted) {
            setErrorMsg(errorDesc || error || 'เกิดข้อผิดพลาดในการเชื่อมต่อกับ Google');
            setTimeout(() => router.replace('/login'), 3500);
          }
          return;
        }

        // กรณีมี code (PKCE) ให้สั่ง exchangeCodeForSession ทันที
        const code = searchParams.get('code');
        if (code) {
          try {
            const { data, error: exchangeErr } =
              await supabase.auth.exchangeCodeForSession(code);
            if (exchangeErr) {
              console.warn('exchangeCodeForSession note:', exchangeErr.message);
            } else if (data.session?.user && isMounted) {
              await syncUserProfile({
                uid: data.session.user.id,
                email: data.session.user.email,
                displayName:
                  data.session.user.user_metadata?.full_name ||
                  data.session.user.email?.split('@')[0],
                photoURL: data.session.user.user_metadata?.avatar_url,
              });
              router.replace('/dashboard');
              return;
            }
          } catch (e) {
            console.warn('Code exchange error:', e);
          }
        }
      }

      // 2. ตรวจสอบ Session ที่มีอยู่
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();
        if (session?.user && isMounted) {
          await syncUserProfile({
            uid: session.user.id,
            email: session.user.email,
            displayName:
              session.user.user_metadata?.full_name ||
              session.user.email?.split('@')[0],
            photoURL: session.user.user_metadata?.avatar_url,
          });
          router.replace('/dashboard');
          return;
        }
      } catch (err) {
        console.warn('Session check note:', err);
      }

      // 3. ฟัง Event เมื่อล็อกอินสำเร็จ (onAuthStateChange)
      const {
        data: { subscription },
      } = supabase.auth.onAuthStateChange(async (event, session) => {
        if (!isMounted) return;
        if ((event === 'SIGNED_IN' || event === 'INITIAL_SESSION') && session?.user) {
          await syncUserProfile({
            uid: session.user.id,
            email: session.user.email,
            displayName:
              session.user.user_metadata?.full_name ||
              session.user.email?.split('@')[0],
            photoURL: session.user.user_metadata?.avatar_url,
          });
          subscription.unsubscribe();
          router.replace('/dashboard');
        }
      });

      // 4. Fallback Timeout ป้องกันหน้าค้าง
      const timer = setTimeout(async () => {
        if (!isMounted) return;
        const {
          data: { session: finalCheck },
        } = await supabase.auth.getSession();
        if (finalCheck?.user) {
          router.replace('/dashboard');
        } else {
          router.replace('/login');
        }
      }, 4000);

      return () => {
        subscription.unsubscribe();
        clearTimeout(timer);
      };
    }

    handleAuth();

    return () => {
      isMounted = false;
    };
  }, [router]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#f6f4ee] font-sans text-[#17221c]">
      <div className="flex flex-col items-center gap-4 rounded-3xl border border-[#e2dfd5] bg-white/80 p-8 shadow-lg backdrop-blur-md text-center max-w-sm w-full mx-4">
        {errorMsg ? (
          <>
            <div className="text-4xl animate-bounce">⚠️</div>
            <h2 className="text-base font-bold text-red-600">การเข้าสู่ระบบไม่สำเร็จ</h2>
            <p className="text-xs text-[#6e746f]">{errorMsg}</p>
            <p className="text-[11px] text-[#9a7257]">กำลังพากลับหน้าเข้าสู่ระบบ...</p>
          </>
        ) : (
          <>
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#243129] border-t-transparent" />
            <h2 className="text-base font-bold text-[#17221c]">กำลังเข้าสู่ระบบด้วย Google...</h2>
            <p className="text-xs text-[#755a47]">กรุณารอสักครู่ กำลังนำคุณเข้าสู่แดชบอร์ด</p>
          </>
        )}
      </div>
    </div>
  );
}

