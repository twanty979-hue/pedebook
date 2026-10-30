export type PlanId = 'free' | 'pro' | 'ultra' | 'business';

export interface PlanConfig {
  id: PlanId;
  name: string;
  nameTh: string;
  tagline: string;
  priceMonthly: number;
  priceYearly: number;
  storageMb: number;
  storageLabel: string;
  maxCatalogs: number; // -1 for unlimited
  maxFileSizeMb: number;
  maxTeamMembers: number;
  hasWatermark: boolean;
  adsOnOverQuota: boolean; // ถ้าใช้เกิน 100 MB สำหรับแพลนฟรี จะเปิดแสดงโฆษณาในเล่มสมุด
  hasPageAnalytics: boolean;
  hasHeatmapAnalytics: boolean;
  canPasswordProtect: boolean;
  canDownloadPdf: boolean;
  canCustomLogo: boolean;
  canTeamCollab: boolean;
  features: string[];
  popular?: boolean;
}

export const PLANS: Record<PlanId, PlanConfig> = {
  free: {
    id: 'free',
    name: 'Free Starter',
    nameTh: 'แพ็กเกจ Free (เริ่มต้นฟรี)',
    tagline: 'เหมาะสำหรับผู้เริ่มต้น ทดลองสร้างแค็ตตาล็อกออนไลน์',
    priceMonthly: 0,
    priceYearly: 0,
    storageMb: 100, // 100 MB โควตาฟรี
    storageLabel: '100 MB (อัปโหลดเกินได้ มีโฆษณา)',
    maxCatalogs: -1, // อัปโหลดได้ต่อเนื่อง
    maxFileSizeMb: 100,
    maxTeamMembers: 1,
    hasWatermark: true,
    adsOnOverQuota: true, // หากเกิน 100 MB จะติดโฆษณาแบบบล็อกไม่ได้
    hasPageAnalytics: true, // ดูสถิติหน้าเบื้องต้นได้
    hasHeatmapAnalytics: false,
    canPasswordProtect: false,
    canDownloadPdf: true,
    canCustomLogo: false,
    canTeamCollab: false,
    features: [
      'พื้นที่โควตาฟรี 100 MB (สามารถอัปเกินได้)',
      'หากอัปโหลดเกิน 100 MB ระบบจะแสดงโฆษณาในเล่มสมุด',
      'แปลงไฟล์ PDF เป็น 3D Flipbook เปิดอ่านออนไลน์',
      'สร้าง QR Code และแชร์ลิงก์ส่งทาง LINE / Social ได้ทันที',
      'รองรับการเปิดอ่านบนมือถือ แท็บเล็ต และคอมพิวเตอร์',
      'ดูสถิติการเปิดอ่านเบื้องต้น',
    ],
  },
  pro: {
    id: 'pro',
    name: 'Pro Trader',
    nameTh: 'แพ็กเกจ Pro (สุดคุ้ม 49.-)',
    tagline: 'สำหรับร้านค้าออนไลน์ SME และฟรีแลนซ์ที่ต้องการความมืออาชีพ',
    priceMonthly: 49,
    priceYearly: 490, // แถม 2 เดือน
    storageMb: 5000, // 5 GB
    storageLabel: '5 GB',
    maxCatalogs: -1,
    maxFileSizeMb: 250,
    maxTeamMembers: 1,
    hasWatermark: false,
    adsOnOverQuota: false,
    hasPageAnalytics: true,
    hasHeatmapAnalytics: true,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: false,
    canTeamCollab: false,
    popular: true,
    features: [
      'พื้นที่จัดเก็บบนคลาวด์ขนาดใหญ่ 5 GB',
      'ไม่มีโฆษณา (Ad-Free 100%)',
      'ปลดล็อกลายน้ำ Pedebook ออกจากเล่มสมุด',
      'ระบบเก็บสถิติเปิดอ่านแต่ละหน้า (หน้าไหนคนอ่านนานที่สุด)',
      'ระบบตั้งรหัสผ่าน (Password Protection) ล็อกราคาส่ง/ข้อมูลเฉพาะกลุ่ม',
      'เปิด/ปิด ปุ่มดาวน์โหลดไฟล์ PDF ต้นฉบับได้',
      'ปรับแต่งสีพื้นหลัง แสงเงา 3D และหน้าปกได้อิสระ',
      'ความเร็ว CDN สูงสุด รองรับคนเปิดอ่านพร้อมกันจำนวนมาก',
    ],
  },
  ultra: {
    id: 'ultra',
    name: 'Ultra Creator',
    nameTh: 'แพ็กเกจ Ultra (ยอดนิยม 199.-)',
    tagline: 'สำหรับแบรนด์ที่เน้นภาพลักษณ์ระดับพรีเมียม และต้องการวิเคราะห์พฤติกรรมลูกค้าเชิงลึก',
    priceMonthly: 199,
    priceYearly: 1990,
    storageMb: 50000, // 50 GB
    storageLabel: '50 GB',
    maxCatalogs: -1,
    maxFileSizeMb: 500,
    maxTeamMembers: 2,
    hasWatermark: false,
    adsOnOverQuota: false,
    hasPageAnalytics: true,
    hasHeatmapAnalytics: true,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: true,
    canTeamCollab: false,
    features: [
      'พื้นที่จัดเก็บขนาดใหญ่พิเศษ 50 GB (มาตรฐานสากล SaaS)',
      'ทุกฟังก์ชันของแพ็กเกจ Pro',
      'ใส่โลโก้แบรนด์ของลูกค้าเอง (Custom Branding) ที่มุมเครื่องเล่น',
      'แดชบอร์ด Heatmap วิเคราะห์เวลาที่ลูกค้าเปิดค้างในแต่ละหน้าแบบละเอียด',
      'ปุ่มสั่งซื้อด่วน (Call-to-Action) เชื่อมต่อ LINE OA หรือ Shopee',
      'ระบบ Lead Form (เก็บชื่อ-เบอร์โทรลูกค้า ก่อนเปิดอ่าน)',
      'Priority CDN ความเร็วสูงสุดระดับ Global Edge',
    ],
  },
  business: {
    id: 'business',
    name: 'Business Enterprise',
    nameTh: 'แพ็กเกจ Business (ทีม & องค์กร 599.-)',
    tagline: 'สำหรับองค์กร บริษัท โรงงาน และทีมงานที่ต้องการทำงานร่วมกัน',
    priceMonthly: 599,
    priceYearly: 5990,
    storageMb: 300000, // 300 GB
    storageLabel: '300 GB',
    maxCatalogs: -1,
    maxFileSizeMb: 1000, // 1 GB ต่อเล่ม
    maxTeamMembers: 10, // เชิญคนเข้าทีมได้สูงสุด 10 คน
    hasWatermark: false,
    adsOnOverQuota: false,
    hasPageAnalytics: true,
    hasHeatmapAnalytics: true,
    canPasswordProtect: true,
    canDownloadPdf: true,
    canCustomLogo: true,
    canTeamCollab: true,
    features: [
      'พื้นที่จัดเก็บระดับองค์กร 300 GB',
      'ระบบเชิญทีมงาน (Team Collaboration) สูงสุด 10 คนต่อทีม',
      'กำหนดสิทธิ์สมาชิกในทีมได้ (Owner, Admin, Editor, Viewer)',
      'ทุกฟังก์ชันของแพ็กเกจ Ultra',
      'ระบบสถิติเชิงลึก Export ข้อมูลรายงานการอ่าน (CSV/Excel)',
      'ความเร็ว CDN สูงสุด พร้อม Dedicated Server Gateway',
      'ทีมงานดูแลระบบและให้คำปรึกษาด่วนพิเศษผ่าน LINE ส่วนตัว',
    ],
  },
};

/**
 * ตรวจสอบความถูกต้องของไฟล์
 */
export function validateUploadLimits(
  _currentCatalogCount: number,
  _currentTotalSizeBytes: number,
  newFileSizeBytes: number,
  _plan: PlanConfig = PLANS.free
): { allowed: boolean; reason?: string } {
  const newFileSizeMb = newFileSizeBytes / (1024 * 1024);

  // ป้องกันเฉพาะไฟล์ที่ใหญ่เกิน 1,000 MB (1 GB) เพื่อไม่ให้กระทบ Browser Memory
  if (newFileSizeMb > 1000) {
    return {
      allowed: false,
      reason: `ไฟล์มีขนาดใหญ่เกิน 1,000 MB (1 GB) ครับ แนะนำแบ่งไฟล์หรือบีบอัดก่อนอัปโหลดครับ`,
    };
  }

  // อัปโหลดได้ไม่จำกัดขนาด! หากเกิน 100 MB ระบบหลังบ้าน (Supabase Trigger) จะติดโฆษณา 5 วิให้อัตโนมัติ
  return { allowed: true };
}
