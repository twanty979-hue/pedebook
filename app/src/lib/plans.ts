export interface PlanConfig {
  id: 'free' | 'starter' | 'business';
  name: string;
  nameTh: string;
  tagline: string;
  priceMonthly: number;
  priceYearly: number;
  storageMb: number;
  storageLabel: string;
  maxCatalogs: number; // -1 for unlimited
  maxFileSizeMb: number;
  hasWatermark: boolean;
  canPasswordProtect: boolean;
  canDownloadPdf: boolean;
  canCustomLogo: boolean;
  canLeadForm: boolean;
  features: string[];
  popular?: boolean;
}

export const PLANS: Record<'free' | 'starter' | 'business', PlanConfig> = {
  free: {
    id: 'free',
    name: 'Free Starter',
    nameTh: 'แพ็กเกจฟรี (ใช้งานได้เต็มรูปแบบ)',
    tagline: 'ใช้งานฟรี ไม่จำกัดจำนวนเล่ม พร้อมสร้างยอดขายได้ทันที',
    priceMonthly: 0,
    priceYearly: 0,
    storageMb: -1, // ไม่จำกัด
    storageLabel: 'ไม่จำกัด (Unlimited)',
    maxCatalogs: -1, // ไม่จำกัด
    maxFileSizeMb: 300, // 300 MB
    hasWatermark: false,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: true,
    canLeadForm: true,
    features: [
      'อัปโหลดแค็ตตาล็อกได้ไม่จำกัดจำนวนเล่ม (Unlimited)',
      'ขนาดไฟล์สูงสุด 300 MB / เล่ม พื้นที่จัดเก็บบนคลาวด์ไม่จำกัด',
      'แปลงเป็น 3D Flipbook เปิดอ่านออนไลน์เสมือนจริง',
      'สร้าง QR Code และแชร์ลิงก์ส่งทาง LINE / Social ได้ทันที',
      'รองรับการเปิดอ่านบนมือถือ แท็บเล็ต และคอมพิวเตอร์',
      'ปรับแต่งสีพื้นหลัง แสงเงา 3D และข้อมูล SEO ได้อิสระ',
    ],
  },
  starter: {
    id: 'starter',
    name: 'Pro Trader',
    nameTh: 'แพ็กเกจ Pro (ยอดนิยม)',
    tagline: 'เหมาะสำหรับร้านค้าออนไลน์ SME ตัวแทนจำหน่าย และฟรีแลนซ์',
    priceMonthly: 149,
    priceYearly: 1490, // แถม 2 เดือน
    storageMb: -1,
    storageLabel: 'ไม่จำกัด (Unlimited)',
    maxCatalogs: -1,
    maxFileSizeMb: 300,
    hasWatermark: false,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: true,
    canLeadForm: true,
    popular: true,
    features: [
      'อัปโหลดแค็ตตาล็อกได้ไม่จำกัดจำนวนเล่ม (Unlimited)',
      'ขนาดไฟล์สูงสุด 300 MB / เล่ม (พื้นที่จัดเก็บไม่จำกัด)',
      'ปลดล็อกลายน้ำ (ไม่มีเครดิต Pedebook)',
      'ระบบตั้งรหัสผ่าน (Password Protection) ล็อกราคาส่ง/ข้อมูลเฉพาะกลุ่ม',
      'เปิด/ปิด ปุ่มดาวน์โหลดไฟล์ PDF ต้นฉบับได้',
      'ปรับแต่งสีพื้นหลัง แสงเงา 3D และหน้าปกได้อิสระ',
      'ดูสถิติยอดคนเปิดอ่านและอุปกรณ์ของผู้เข้าชม',
      'ความเร็ว CDN สูงสุด รองรับคนเปิดอ่านพร้อมกันจำนวนมาก',
    ],
  },
  business: {
    id: 'business',
    name: 'Business Enterprise',
    nameTh: 'แพ็กเกจ Business (สำหรับองค์กร)',
    tagline: 'สำหรับแบรนด์ บริษัท โรงงาน และร้านอาหารที่มีสินค้าจำนวนมาก',
    priceMonthly: 390,
    priceYearly: 3900,
    storageMb: -1,
    storageLabel: 'ไม่จำกัด (Unlimited)',
    maxCatalogs: -1,
    maxFileSizeMb: 500,
    hasWatermark: false,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: true,
    canLeadForm: true,
    features: [
      'อัปโหลดแค็ตตาล็อกได้ไม่จำกัดจำนวนเล่ม (Unlimited)',
      'ขนาดไฟล์สูงสุด 500 MB / เล่ม (พื้นที่จัดเก็บไม่จำกัด)',
      'ทุกฟังก์ชันของแพ็กเกจ Pro',
      'ใส่โลโก้แบรนด์ของลูกค้าเอง (Custom Branding) ที่มุมเครื่องเล่น',
      'ปุ่มสั่งซื้อด่วน (Call-to-Action) เชื่อมต่อ LINE OA หรือ Shopee',
      'ระบบ Lead Form (เก็บชื่อ-เบอร์โทรลูกค้า ก่อนเปิดอ่าน)',
      'Priority CDN ความเร็วสูงสุดระดับ Global Edge',
      'ทีมงานดูแลระบบและให้คำปรึกษาด่วนพิเศษผ่าน LINE ส่วนตัว',
    ],
  },
};

/**
 * Helper to check whether an upload violates plan constraints.
 * ปลดล็อกให้ทุกแพลนใช้งานได้ปกติ ไม่จำกัดจำนวนเล่ม เพื่อเน้นเพิ่มยอดผู้ใช้งาน
 */
export function validateUploadLimits(
  _currentCatalogCount: number,
  _currentTotalSizeBytes: number,
  newFileSizeBytes: number,
  _plan: PlanConfig = PLANS.free
): { allowed: boolean; reason?: string } {
  const newFileSizeMb = newFileSizeBytes / (1024 * 1024);

  // ป้องกันเฉพาะกรณีไฟล์ใหญ่เกิน 500 MB ซึ่งอาจทำให้เบราว์เซอร์รับไม่ไหว
  if (newFileSizeMb > 500) {
    return {
      allowed: false,
      reason: `ขนาดไฟล์ (${newFileSizeMb.toFixed(1)} MB) ใหญ่เกิน 500 MB ครับ แนะนำให้ขนาดไฟล์ไม่เกิน 500 MB เพื่อให้เปิดอ่านบนมือถือได้อย่างรวดเร็วครับ`,
    };
  }

  // อนุญาตทุกกรณี ไม่จำกัดจำนวนเล่มและพื้นที่จัดเก็บ
  return { allowed: true };
}
