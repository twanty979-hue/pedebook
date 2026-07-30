'use client';

import React, { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { onAuthStateChanged, signOut, User } from 'firebase/auth';
import { auth } from '../src/lib/firebase';

export default function NavbarClient() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error('Sign out error', error);
    }
  };

  return (
    <nav className="relative z-10 flex w-full items-center justify-between px-4 py-6 sm:px-8 lg:px-12">
      <Link
        href="/"
        aria-label="Pedebook — หน้าแรก"
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
                // eslint-disable-next-line @next/next/no-img-element -- Dynamic Firebase user avatar URL
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
                  {user.displayName || 'ผู้ใช้งาน'}
                </span>
                <span className="text-[10px] leading-tight text-[#6e746f]">
                  {user.email}
                </span>
              </div>
            </Link>
            
            <button
              onClick={handleSignOut}
              className="rounded-full border border-[#d9d7cd] px-4 py-1.5 text-xs font-bold text-[#755a47] hover:bg-[#243129] hover:text-[#e8dcc7] hover:border-[#243129] transition-all cursor-pointer"
            >
              ออกจากระบบ
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-4">
            <Link
              href="/login"
              className="hidden text-sm font-semibold text-[#755a47] transition hover:text-[#243129] sm:block"
            >
              เข้าสู่ระบบ
            </Link>

            <Link
              href="/login"
              className="rounded-full bg-[#243129] px-6 py-2.5 text-sm font-bold text-[#e8dcc7] shadow-[0_4px_12px_rgba(36,49,41,0.2)] transition hover:bg-[#314238]"
            >
              เริ่มสร้างแคตตาล็อก
            </Link>
          </div>
        )}
      </div>
    </nav>
  );
}
