import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// ดึงค่าคอนฟิกจากไฟล์ .env.local
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// ตรวจสอบความปลอดภัยเบื้องต้น
if (!firebaseConfig.apiKey) {
  console.warn("⚠️ แจ้งเตือน: ยังไม่พบค่า NEXT_PUBLIC_FIREBASE_API_KEY ในไฟล์ .env.local");
}

// ป้องกันระบบ Initialize ซ้ำตอน Next.js ทำการ Hot Reload
const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

export { app, auth, db };