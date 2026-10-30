'use client';

import React, { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { supabase, isSupabaseConfigured } from '../src/lib/supabase/client';

export type AuthUser = {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
};

type NavbarClientProps = {
  locale?: 'th' | 'en';
};

export default function NavbarClient({ locale = 'th' }: NavbarClientProps) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const isEnglish = locale === 'en';
  const copy = isEnglish
    ? {
        homeLabel: 'Pedebook — Home',
        account: 'Account',
        signOut: 'Sign out',
        signIn: 'Sign in',
        start: 'Create a flipbook',
        admin: 'Admin',
        languageLabel: 'ภาษาไทย',
        languageHref: '/',
      }
    : {
        homeLabel: 'Pedebook — หน้าแรก',
        account: 'ผู้ใช้งาน',
        signOut: 'ออกจากระบบ',
        signIn: 'เข้าสู่ระบบ',
        start: 'เริ่มสร้างแคตตาล็อก',
        admin: 'แอดมิน',
        languageLabel: 'English',
        languageHref: '/en',
      };

  useEffect(() => {
    let isMounted = true;

    async function checkAuth() {
      if (isSupabaseConfigured()) {
        try {
          const {
            data: { session },
          } = await supabase.auth.getSession();
          if (session?.user && isMounted) {
            setUser({
              uid: session.user.id,
              email: session.user.email || null,
              displayName:
                session.user.user_metadata?.full_name ||
                session.user.email?.split('@')[0] ||
                'User',
              photoURL: session.user.user_metadata?.avatar_url || null,
            });
            setLoading(false);
            return;
          }
        } catch (e) {
          console.warn('Supabase session check note:', e);
        }
      }

      if (isMounted) {
        setUser(null);
        setLoading(false);
      }
    }

    checkAuth();

    let sbSub: { unsubscribe: () => void } | undefined;
    if (isSupabaseConfigured()) {
      const { data } = supabase.auth.onAuthStateChange((_event, session) => {
        if (!isMounted) return;
        if (session?.user) {
          setUser({
            uid: session.user.id,
            email: session.user.email || null,
            displayName:
              session.user.user_metadata?.full_name ||
              session.user.email?.split('@')[0] ||
              'User',
            photoURL: session.user.user_metadata?.avatar_url || null,
          });
        } else {
          setUser(null);
        }
        setLoading(false);
      });
      sbSub = data.subscription;
    }

    return () => {
      isMounted = false;
      if (sbSub) sbSub.unsubscribe();
    };
  }, []);

  const handleSignOut = async () => {
    try {
      if (isSupabaseConfigured()) {
        await supabase.auth.signOut();
      }
      setUser(null);
    } catch (error) {
      console.error('Sign out error', error);
    }
  };

  return (
    <nav className="relative z-10 flex w-full items-center justify-between px-4 py-6 sm:px-8 lg:px-12">
      <Link
        href={isEnglish ? '/en' : '/'}
        aria-label={copy.homeLabel}
        className="flex h-14 w-14 items-center justify-center rounded-[20px] shadow-[0_8px_20px_rgba(36,49,41,0.08)] transition hover:-translate-y-0.5 sm:h-16 sm:w-16"
      >
        <Image
          src="/pedebook-icon.png"
          alt="Pedebook"
          width={181}
          height={181}
          priority
          className="h-full w-full rounded-[20px] object-contain"
        />
      </Link>

      <div className="flex items-center gap-4">
        {loading ? (
          <div className="h-8 w-20 animate-pulse rounded-full bg-neutral-200" />
        ) : user ? (
          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="flex items-center gap-2 rounded-full border border-[#d9d7cd] bg-white/60 px-3 py-1.5 shadow-sm backdrop-blur hover:bg-[#243129]/5 transition-all duration-300 cursor-pointer"
            >
              {user.photoURL ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={user.photoURL}
                  alt={user.displayName || 'User Profile'}
                  className="h-7 w-7 rounded-full object-cover"
                  referrerPolicy="no-referrer"
                />
              ) : (
                <span className="grid h-7 w-7 place-items-center rounded-full bg-[#243129] text-xs font-bold text-[#e8dcc7]">
                  {user.email?.charAt(0).toUpperCase() || 'U'}
                </span>
              )}
              <div className="hidden flex-col text-left sm:flex">
                <span className="text-xs font-bold leading-tight text-[#17221c]">
                  {user.displayName || copy.account}
                </span>
                <span className="text-[10px] leading-tight text-[#6e746f]">
                  {user.email || ''}
                </span>
              </div>
            </Link>

            <Link
              href="/pricing"
              className="text-xs font-bold text-[#755a47] hover:text-[#243129] transition px-2 py-1"
            >
              {isEnglish ? 'Pricing' : 'ราคาและแพ็กเกจ'}
            </Link>

            <Link
              href="/admin"
              className="flex items-center gap-1.5 rounded-full border border-[#243129]/20 bg-white/70 px-3 py-1.5 text-xs font-bold text-[#243129] shadow-xs backdrop-blur hover:bg-[#243129] hover:text-[#e8dcc7] transition-all cursor-pointer"
              title="แผงควบคุมแอดมิน"
            >
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                />
              </svg>
              <span>{copy.admin}</span>
            </Link>

            <button
              onClick={handleSignOut}
              className="rounded-full border border-[#d9d7cd] px-4 py-1.5 text-xs font-bold text-[#755a47] hover:bg-[#243129] hover:text-[#e8dcc7] hover:border-[#243129] transition-all cursor-pointer"
            >
              {copy.signOut}
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-4">
            <Link
              href="/pricing"
              className="hidden text-sm font-semibold text-[#755a47] transition hover:text-[#243129] sm:block"
            >
              {isEnglish ? 'Pricing' : 'ราคาและแพ็กเกจ'}
            </Link>

            <Link
              href="/login"
              className="text-sm font-semibold text-[#755a47] transition hover:text-[#243129]"
            >
              {copy.signIn}
            </Link>

            <Link
              href={copy.languageHref}
              hrefLang={isEnglish ? 'th' : 'en'}
              className="text-sm font-semibold text-[#755a47] transition hover:text-[#243129]"
            >
              {copy.languageLabel}
            </Link>

            <Link
              href="/dashboard"
              className="rounded-full bg-[#243129] px-6 py-2.5 text-sm font-bold text-[#e8dcc7] shadow-[0_4px_12px_rgba(36,49,41,0.2)] transition hover:bg-[#314238]"
            >
              {copy.start}
            </Link>
          </div>
        )}
      </div>
    </nav>
  );
}
