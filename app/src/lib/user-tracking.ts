import { supabase, isSupabaseConfigured } from './supabase/client';

export interface UserProfileRecord {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  lastActiveAt: string;
  createdAt?: string;
  userAgent?: string;
  docType?: 'user_profile';
}

const DEFAULT_ADMIN_PIN = 'admin1234';

const DEFAULT_ADMIN_EMAILS = [
  'std.65122420112@ubru.ac.th',
  'boss@pedebook.com',
  'admin@pedebook.com',
];

/**
 * Checks if an email is in the admin email whitelist.
 */
export function isAdminEmail(email?: string | null): boolean {
  if (!email) return false;
  const adminEmailsEnv = process.env.NEXT_PUBLIC_ADMIN_EMAILS || '';
  const adminEmails = [
    ...DEFAULT_ADMIN_EMAILS,
    ...adminEmailsEnv
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  ];

  return adminEmails.includes(email.toLowerCase());
}

/**
 * Checks if the given PIN matches the configured admin PIN.
 */
export function verifyAdminPin(pin: string): boolean {
  const configuredPin = (process.env.NEXT_PUBLIC_ADMIN_PIN || DEFAULT_ADMIN_PIN).trim();
  return pin.trim() === configuredPin;
}

export type AnyUser = {
  uid: string;
  email?: string | null;
  displayName?: string | null;
  photoURL?: string | null;
  metadata?: {
    creationTime?: string;
  };
};

/**
 * Syncs the current user profile into Supabase profiles.
 */
export async function syncUserProfile(user: AnyUser): Promise<void> {
  if (!user || !user.uid) return;

  if (!isSupabaseConfigured()) return;

  try {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(user.uid);
    if (!isUuid) return;

    await supabase
      .from('profiles')
      .upsert(
        {
          id: user.uid,
          email: user.email || `${user.uid.slice(0, 12)}@pedebook.com`,
          display_name: user.displayName || user.email?.split('@')[0] || 'User',
          avatar_url: user.photoURL || null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'id' }
      );
  } catch (err) {
    console.debug('Could not sync user profile to Supabase:', err);
  }
}

/**
 * Fetches all tracked user profiles from Supabase.
 */
export async function getAllUserProfiles(): Promise<Map<string, UserProfileRecord>> {
  const userMap = new Map<string, UserProfileRecord>();

  try {
    const res = await fetch('/api/v1/users');
    const json = await res.json();
    if (json.success && Array.isArray(json.users)) {
      json.users.forEach((u: any) => {
        if (u.id) {
          userMap.set(u.id, {
            uid: u.id,
            email: u.email || null,
            displayName: u.display_name || u.email?.split('@')[0] || 'User',
            photoURL: u.avatar_url || null,
            lastActiveAt: u.updated_at || u.created_at,
            createdAt: u.created_at,
          });
        }
      });
    }
  } catch (err) {
    console.warn('Error querying user profiles from Supabase:', err);
  }

  return userMap;
}
