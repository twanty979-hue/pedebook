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
    nameTh: 'แพ็กเกจฟรี (ทดลองใช้)',
    tagline: 'เหมาะสำหรับผู้เริ่มต้น ทดลองสร้างแค็ตตาล็อกเล่มแรก',
    priceMonthly: 0,
    priceYearly: 0,
    storageMb: 100, // 100 MB
    storageLabel: '100 MB',
    maxCatalogs: 10, // 10 เล่ม
    maxFileSizeMb: 10, // เล่มละ 10 MB
    hasWatermark: true,
    canPasswordProtect: false,
    canDownloadPdf: true,
    canCustomLogo: false,
    canLeadForm: false,
    features: [
      'อัปโหลดแค็ตตาล็อกได้สูงสุด 10 เล่ม',
      'ขนาดไฟล์สูงสุด 10 MB / เล่ม (พื้นที่รวม 100 MB)',
      'แปลงเป็น 3D Flipbook เปิดอ่านออนไลน์เสมือนจริง',
      'สร้าง QR Code และแชร์ลิงก์ส่งทาง LINE / Social ได้ทันที',
      'รองรับการเปิดอ่านบนมือถือ แท็บเล็ต และคอมพิวเตอร์',
      'มีเครดิต Pedebook ใต้เล่มสมุด',
    ],
  },
  starter: {
    id: 'starter',
    name: 'Pro Trader',
    nameTh: 'แพ็กเกจ Pro (ยอดนิยม)',
    tagline: 'เหมาะสำหรับร้านค้าออนไลน์ SME ตัวแทนจำหน่าย และฟรีแลนซ์',
    priceMonthly: 149,
    priceYearly: 1490, // แถม 2 เดือน
    storageMb: 5000, // 5 GB
    storageLabel: '5 GB',
    maxCatalogs: 30, // 30 เล่ม
    maxFileSizeMb: 100, // 100 MB / เล่ม
    hasWatermark: false,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: false,
    canLeadForm: false,
    popular: true,
    features: [
      'อัปโหลดแค็ตตาล็อกได้สูงสุด 30 เล่ม',
      'ขนาดไฟล์สูงสุด 100 MB / เล่ม (พื้นที่รวม 5 GB)',
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
    storageMb: 25000, // 25 GB
    storageLabel: '25 GB',
    maxCatalogs: -1, // Unlimited
    maxFileSizeMb: 250, // 250 MB / เล่ม
    hasWatermark: false,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: true,
    canLeadForm: true,
    features: [
      'อัปโหลดแค็ตตาล็อกได้ไม่จำกัดจำนวนเล่ม (Unlimited)',
      'ขนาดไฟล์สูงสุด 250 MB / เล่ม (พื้นที่รวม 25 GB)',
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
 */
export function validateUploadLimits(
  currentCatalogCount: number,
  currentTotalSizeBytes: number,
  newFileSizeBytes: number,
  plan: PlanConfig = PLANS.free
): { allowed: boolean; reason?: string } {
  const newFileSizeMb = newFileSizeBytes / (1024 * 1024);
  const currentTotalMb = currentTotalSizeBytes / (1024 * 1024);

  // 1. Check max file size
  if (newFileSizeMb > plan.maxFileSizeMb) {
    return {
      allowed: false,
      reason: `ขนาดไฟล์ (${newFileSizeMb.toFixed(1)} MB) เกินขีดจำกัดของ${plan.nameTh} ที่อนุญาตสูงสุด ${plan.maxFileSizeMb} MB ต่อเล่มครับ`,
    };
  }

  // 2. Check catalog count limit
  if (plan.maxCatalogs !== -1 && currentCatalogCount >= plan.maxCatalogs) {
    return {
      allowed: false,
      reason: `จำนวนแค็ตตาล็อกครบขีดจำกัด ${plan.maxCatalogs} เล่มของ${plan.nameTh}แล้วครับ`,
    };
  }

  // 3. Check total storage limit
  if (currentTotalMb + newFileSizeMb > plan.storageMb) {
    return {
      allowed: false,
      reason: `พื้นที่จัดเก็บรวมจะเกิน ${plan.storageLabel} ของ${plan.nameTh}ครับ (ใช้งานปัจจุบัน: ${currentTotalMb.toFixed(1)} MB)`,
    };
  }

  return { allowed: true };
}
