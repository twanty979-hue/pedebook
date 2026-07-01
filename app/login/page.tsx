"use client";

import React, { useState } from "react";
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  GoogleAuthProvider,
  signInWithPopup,
} from "firebase/auth";
import { useRouter } from "next/navigation";
import { auth } from "../src/lib/firebase";

type ActiveMode = "login" | "register" | "forgot";

export default function LoginPage() {
  const [mode, setMode] = useState<ActiveMode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleEmailAction = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      if (mode === "login") {
        await signInWithEmailAndPassword(auth, email, password);
        router.push("/");
      } else if (mode === "register") {
        if (password !== confirmPassword) {
          throw new Error("passwords-dont-match");
        }
        await createUserWithEmailAndPassword(auth, email, password);
        setSuccess("สมัครสมาชิกสำเร็จแล้ว! ระบบกำลังนำคุณไปที่หน้าหลัก...");
        setTimeout(() => {
          router.push("/");
        }, 1500);
      } else if (mode === "forgot") {
        await sendPasswordResetEmail(auth, email);
        setSuccess("ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณแล้ว กรุณาตรวจสอบกล่องจดหมายครับ");
        setEmail("");
        setMode("login");
      }
    } catch (err: any) {
      console.error(err);
      if (err.message === "passwords-dont-match") {
        setError("รหัสผ่านและการยืนยันรหัสผ่านไม่ตรงกันครับ");
      } else if (err.code === "auth/email-already-in-use") {
        setError("อีเมลนี้ถูกใช้งานแล้วในระบบครับ");
      } else if (err.code === "auth/weak-password") {
        setError("รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษรครับ");
      } else if (err.code === "auth/invalid-email") {
        setError("รูปแบบอีเมลไม่ถูกต้องครับ");
      } else if (err.code === "auth/user-not-found" || err.code === "auth/wrong-password" || err.code === "auth/invalid-credential") {
        setError("อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้งครับ");
      } else {
        setError("เกิดข้อผิดพลาดขึ้น กรุณาลองใหม่อีกครั้งในภายหลังครับ");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setError(null);
    setSuccess(null);
    setLoading(true);
    const provider = new GoogleAuthProvider();

    try {
      await signInWithPopup(auth, provider);
      setSuccess("เข้าสู่ระบบด้วย Google สำเร็จแล้ว!");
      setTimeout(() => {
        router.push("/");
      }, 800);
    } catch (err: any) {
      console.error(err);
      if (err.code !== "auth/popup-closed-by-user") {
        setError("เกิดข้อผิดพลาดในการเข้าสู่ระบบด้วย Google กรุณาลองใหม่อีกครั้งครับ");
      }
    } finally {
      setLoading(false);
    }
  };

  const changeMode = (newMode: ActiveMode) => {
    setMode(newMode);
    setError(null);
    setSuccess(null);
    setPassword("");
    setConfirmPassword("");
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#f6f4ee] p-4 font-sans text-[#17221c]">
      {/* วงกลมเบลอพื้นหลังเลียนแบบหน้าแรก */}
      <div className="absolute left-1/2 top-1/2 h-[350px] w-[350px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#d3b894]/30 blur-[80px] sm:h-[500px] sm:w-[500px]" />

      <div className="relative z-10 w-full max-w-md rounded-3xl border border-[#e2dfd5] bg-white/80 p-8 shadow-[0_20px_50px_rgba(36,49,41,0.06)] backdrop-blur-md">
        {/* โลโก้แบรนด์ */}
        <div className="mb-6 flex flex-col items-center justify-center gap-2">
          <a href="/" className="flex items-center gap-2.5">
            <img
              src="/logo.png"
              alt="Pedebook Logo"
              className="h-10 w-10 rounded-xl object-contain shadow-sm"
            />
            <div className="flex flex-col">
              <span className="text-lg font-bold tracking-tight text-[#17221c] leading-tight">
                Pedebook
              </span>
              <span className="text-[10px] font-semibold text-[#9a7257] tracking-wide leading-none">
                Digital Flipbook Platform
              </span>
            </div>
          </a>
        </div>

        <header className="mb-6 text-center">
          <h1 className="text-2xl font-medium tracking-tight text-[#17221c]">
            {mode === "login" && (
              <>
                ยินดีต้อนรับ{" "}
                <span className="font-serif italic text-[#9a7257]">
                  กลับมาครับ
                </span>
              </>
            )}
            {mode === "register" && (
              <>
                เริ่มสร้าง{" "}
                <span className="font-serif italic text-[#9a7257]">
                  บัญชีใหม่
                </span>
              </>
            )}
            {mode === "forgot" && (
              <>
                กู้คืน{" "}
                <span className="font-serif italic text-[#9a7257]">
                  รหัสผ่าน
                </span>
              </>
            )}
          </h1>
          <p className="mt-2 text-sm text-[#6e746f]">
            {mode === "login" && "เข้าสู่ระบบเพื่อจัดการและเผยแพร่แค็ตตาล็อกของคุณ"}
            {mode === "register" && "ลงทะเบียนฟรีเพื่อเปลี่ยน PDF เป็นสมุดพลิกออนไลน์"}
            {mode === "forgot" && "ระบบจะส่งลิงก์เพื่อรีเซ็ตรหัสผ่านใหม่ไปยังอีเมลของคุณ"}
          </p>
        </header>

        {/* ปุ่มลอกอินด้วย Google (เฉพาะโหมดเข้าสู่ระบบและสมัครสมาชิก) */}
        {mode !== "forgot" && (
          <div className="mb-5">
            <button
              type="button"
              onClick={handleGoogleLogin}
              disabled={loading}
              className="flex w-full items-center justify-center gap-3 rounded-xl border border-[#d9d7cd] bg-white px-4 py-3 text-sm font-semibold text-[#17221c] shadow-sm transition-all hover:bg-neutral-50 active:scale-[0.98] disabled:opacity-50"
            >
              <svg className="h-5 w-5" viewBox="0 0 24 24">
                <path
                  fill="#EA4335"
                  d="M12 5.04c1.66 0 3.2.57 4.38 1.69l3.27-3.27C17.67 1.47 14.98 1 12 1 7.35 1 3.39 3.65 1.5 7.5l3.92 3.04c.92-2.76 3.51-4.5 6.58-4.5z"
                />
                <path
                  fill="#4285F4"
                  d="M23.49 12.27c0-.81-.07-1.59-.2-2.34H12v4.58h6.48c-.28 1.48-1.12 2.74-2.38 3.58l3.7 2.87c2.16-2 3.69-4.94 3.69-8.69z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.42 14.96c-.24-.72-.38-1.49-.38-2.28s.14-1.56.38-2.28L1.5 7.36c-.8 1.6-1.25 3.4-1.25 5.3 0 1.9.45 3.7 1.25 5.3l3.92-3z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c3.24 0 5.97-1.07 7.96-2.91l-3.7-2.87c-1.03.69-2.35 1.1-4.26 1.1-3.07 0-5.66-1.74-6.58-4.5L1.5 16.86C3.39 20.71 7.35 23 12 23z"
                />
              </svg>
              <span>ดำเนินการต่อด้วย Google</span>
            </button>

            <div className="relative my-6 flex items-center justify-center">
              <span className="absolute inset-x-0 border-t border-[#e2dfd5]" />
              <span className="relative bg-[#fbfaf8] px-3 text-xs font-semibold uppercase tracking-wider text-[#755a47]">
                หรือ
              </span>
            </div>
          </div>
        )}

        {/* ฟอร์มทำรายการ */}
        <form onSubmit={handleEmailAction} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-[#755a47] mb-1.5">
              อีเมล
            </label>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="example@email.com"
              className="w-full rounded-xl border border-[#d9d7cd] bg-white px-4 py-2.5 text-sm text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257] transition"
              required
              disabled={loading}
            />
          </div>

          {mode !== "forgot" && (
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-bold uppercase tracking-wider text-[#755a47]">
                  รหัสผ่าน
                </label>
                {mode === "login" && (
                  <button
                    type="button"
                    onClick={() => changeMode("forgot")}
                    className="text-xs font-semibold text-[#9a7257] hover:underline"
                    disabled={loading}
                  >
                    ลืมรหัสผ่าน?
                  </button>
                )}
              </div>
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="ป้อนรหัสผ่านของคุณ"
                className="w-full rounded-xl border border-[#d9d7cd] bg-white px-4 py-2.5 text-sm text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257] transition"
                required
                disabled={loading}
              />
            </div>
          )}

          {mode === "register" && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#755a47] mb-1.5">
                ยืนยันรหัสผ่านอีกครั้ง
              </label>
              <input
                type="password"
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                placeholder="ยืนยันรหัสผ่านของคุณ"
                className="w-full rounded-xl border border-[#d9d7cd] bg-white px-4 py-2.5 text-sm text-[#17221c] outline-none focus:border-[#9a7257] focus:ring-1 focus:ring-[#9a7257] transition"
                required
                disabled={loading}
              />
            </div>
          )}

          {error && (
            <div className="rounded-xl bg-red-50/80 border border-red-200/50 px-4 py-3 text-xs font-medium text-red-600">
              ⚠️ {error}
            </div>
          )}

          {success && (
            <div className="rounded-xl bg-emerald-50/80 border border-emerald-200/50 px-4 py-3 text-xs font-medium text-emerald-600">
              ✓ {success}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-[#243129] py-3 text-sm font-bold text-[#e8dcc7] shadow-[0_4px_12px_rgba(36,49,41,0.2)] transition hover:bg-[#314238] active:scale-[0.98] disabled:opacity-50"
          >
            {loading ? "กำลังดำเนินการ..." : ""}
            {!loading && mode === "login" && "ลงชื่อเข้าใช้งาน"}
            {!loading && mode === "register" && "สมัครสมาชิก"}
            {!loading && mode === "forgot" && "ส่งข้อมูลรีเซ็ตรหัสผ่าน"}
          </button>
        </form>

        {/* เมนูเปลี่ยนโหมดด้านล่างสุด */}
        <div className="mt-6 text-center text-sm text-[#6e746f]">
          {mode === "login" && (
            <>
              ยังไม่มีบัญชีผู้ใช้?{" "}
              <button
                type="button"
                onClick={() => changeMode("register")}
                className="font-bold text-[#9a7257] hover:underline"
                disabled={loading}
              >
                สมัครสมาชิกฟรี
              </button>
            </>
          )}

          {mode === "register" && (
            <>
              มีบัญชีผู้ใช้อยู่แล้ว?{" "}
              <button
                type="button"
                onClick={() => changeMode("login")}
                className="font-bold text-[#9a7257] hover:underline"
                disabled={loading}
              >
                เข้าสู่ระบบ
              </button>
            </>
          )}

          {mode === "forgot" && (
            <button
              type="button"
              onClick={() => changeMode("login")}
              className="font-bold text-[#9a7257] hover:underline"
              disabled={loading}
            >
              ย้อนกลับหน้าเข้าสู่ระบบ
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
