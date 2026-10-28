'use client';

import { useEffect, useRef } from 'react';

interface UsePageAnalyticsProps {
  catalogId: string;
  currentPage: number;
  enabled?: boolean;
}

export function usePageAnalytics({ catalogId, currentPage, enabled = true }: UsePageAnalyticsProps) {
  const activePageRef = useRef<number>(currentPage);
  const pageEnterTimeRef = useRef<number>(Date.now());
  const sessionIdRef = useRef<string>('');

  // 1. Initialize or load unique session ID
  useEffect(() => {
    if (typeof window === 'undefined') return;
    let sId = window.sessionStorage.getItem(`pedebook_session_${catalogId}`);
    if (!sId) {
      sId = `sess_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
      window.sessionStorage.setItem(`pedebook_session_${catalogId}`, sId);
    }
    sessionIdRef.current = sId;
  }, [catalogId]);

  // 2. Helper to send page stay duration
  const sendPageDuration = (pageNumber: number, durationSeconds: number) => {
    if (!catalogId || durationSeconds < 0.5) return; // ignore sub-second instant flips

    const payload = JSON.stringify({
      catalogId,
      pageNumber,
      durationSeconds: Number(durationSeconds.toFixed(1)),
      sessionId: sessionIdRef.current,
      deviceType: typeof window !== 'undefined' && window.innerWidth < 768 ? 'mobile' : 'desktop',
    });

    if (typeof navigator !== 'undefined' && navigator.sendBeacon) {
      const blob = new Blob([payload], { type: 'application/json' });
      navigator.sendBeacon('/api/v1/analytics/ping', blob);
    } else {
      fetch('/api/v1/analytics/ping', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: payload,
        keepalive: true,
      }).catch((e) => console.debug('Analytics ping failed:', e));
    }
  };

  // 3. Track page flip changes
  useEffect(() => {
    if (!enabled) return;

    const previousPage = activePageRef.current;
    const now = Date.now();
    const durationSeconds = (now - pageEnterTimeRef.current) / 1000;

    // Send duration for the page that was just left
    if (previousPage !== currentPage) {
      sendPageDuration(previousPage, durationSeconds);
      activePageRef.current = currentPage;
      pageEnterTimeRef.current = now;
    }
  }, [currentPage, enabled]);

  // 4. Handle tab close / background change
  useEffect(() => {
    if (!enabled) return;

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'hidden') {
        const now = Date.now();
        const durationSeconds = (now - pageEnterTimeRef.current) / 1000;
        sendPageDuration(activePageRef.current, durationSeconds);
        pageEnterTimeRef.current = now;
      } else {
        pageEnterTimeRef.current = Date.now();
      }
    };

    const handleBeforeUnload = () => {
      const now = Date.now();
      const durationSeconds = (now - pageEnterTimeRef.current) / 1000;
      sendPageDuration(activePageRef.current, durationSeconds);
    };

    window.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [enabled, catalogId]);
}
