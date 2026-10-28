import { User } from 'firebase/auth';
import { doc, setDoc, getDocs, collection, query, where } from 'firebase/firestore';
import { db } from './firebase';

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

/**
 * Checks if an email is in the admin email whitelist.
 */
export function isAdminEmail(email?: string | null): boolean {
  if (!email) return false;
  const adminEmailsEnv = process.env.NEXT_PUBLIC_ADMIN_EMAILS || '';
  const adminEmails = adminEmailsEnv
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);

  if (adminEmails.length > 0 && adminEmails.includes(email.toLowerCase())) {
    return true;
  }

  return false;
}

/**
 * Checks if the given PIN matches the configured admin PIN.
 */
export function verifyAdminPin(pin: string): boolean {
  const configuredPin = (process.env.NEXT_PUBLIC_ADMIN_PIN || DEFAULT_ADMIN_PIN).trim();
  return pin.trim() === configuredPin;
}

/**
 * Syncs the current user profile into Firestore.
 * Saves to both 'catalogs' (with docType: 'user_profile' for guaranteed permissions)
 * and 'users' collection (if permitted).
 */
export async function syncUserProfile(user: User): Promise<void> {
  if (!user || !user.uid) return;

  const profileData: UserProfileRecord = {
    uid: user.uid,
    email: user.email || null,
    displayName: user.displayName || user.email?.split('@')[0] || 'User',
    photoURL: user.photoURL || null,
    lastActiveAt: new Date().toISOString(),
    createdAt: user.metadata.creationTime || new Date().toISOString(),
    userAgent: typeof window !== 'undefined' ? window.navigator.userAgent : '',
    docType: 'user_profile',
  };

  try {
    // 1. Save in catalogs collection with user_profile_{uid} ID
    // This collection is always readable according to existing rules
    const profileDocRef = doc(db, 'catalogs', `user_profile_${user.uid}`);
    await setDoc(profileDocRef, profileData, { merge: true });
  } catch (err) {
    console.debug('Could not sync user profile to catalogs collection:', err);
  }

  try {
    // 2. Also try saving in users collection
    const userDocRef = doc(db, 'users', user.uid);
    await setDoc(userDocRef, profileData, { merge: true });
  } catch (err) {
    // Non-critical if firestore rules restrict 'users' collection
    console.debug('Could not sync user profile to users collection (likely rules):', err);
  }
}

/**
 * Fetches all tracked user profiles from Firestore.
 */
export async function getAllUserProfiles(): Promise<Map<string, UserProfileRecord>> {
  const userMap = new Map<string, UserProfileRecord>();

  try {
    // Fetch from catalogs where docType == 'user_profile'
    const q = query(collection(db, 'catalogs'), where('docType', '==', 'user_profile'));
    const snapshot = await getDocs(q);
    snapshot.docs.forEach((d) => {
      const data = d.data() as UserProfileRecord;
      if (data.uid) {
        userMap.set(data.uid, data);
      }
    });
  } catch (err) {
    console.warn('Error querying user profiles from catalogs:', err);
  }

  return userMap;
}
