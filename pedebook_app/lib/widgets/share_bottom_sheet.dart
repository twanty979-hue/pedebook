import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_model.dart';
import '../screens/qr_studio_screen.dart';

class ShareBottomSheet extends StatelessWidget {
  final CatalogItem catalog;

  const ShareBottomSheet({super.key, required this.catalog});

  static void show(BuildContext context, CatalogItem catalog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareBottomSheet(catalog: catalog),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareUrl = catalog.publicUrl;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Back button and Close button
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: const Color(0xFF17221C),
                tooltip: 'ย้อนกลับ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F7A54).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFF1F7A54),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalog.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17221C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'แชร์หรือสแกนเปิดอ่านสมุด 3D Flipbook',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 22),
                color: Colors.grey.shade600,
                tooltip: 'ปิด',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live QR Code Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBF9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E2D9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: shareUrl,
                    version: QrVersions.auto,
                    size: 180,
                    gapless: true,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1B2820),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1B2820),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 16,
                      color: Color(0xFF1F7A54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ยื่นมือถือให้ลูกค้าสแกนเปิดอ่านได้เลย',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // URL Display & Copy Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2DFD5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: Color(0xFF755A47),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shareUrl,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF17221C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('คัดลอกลิงก์เรียบร้อยแล้วครับ'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1B2820),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1F7A54),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  child: const Text('คัดลอก'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big Main Action Buttons
          Row(
            children: [
              // Native Share Button (LINE / Social)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'อ่าน ${catalog.title} ออนไลน์แบบ 3D Flipbook ได้ที่นี่ครับ: $shareUrl',
                      subject: catalog.title,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('แชร์ไปที่ LINE / โซเชียล'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2820),
                    foregroundColor: const Color(0xFFF7F5F0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Open in Browser Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl(shareUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('เปิดอ่าน'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B2820),
                    side: const BorderSide(color: Color(0xFFD9D7CD), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Shortcut to full QR Studio
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrStudioScreen(initialCatalog: catalog),
                ),
              );
            },
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 15, color: Color(0xFF1F7A54)),
            label: const Text('ตกแต่งสีสันและบันทึกภาพใน สตูดิโอ QR →'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1B2820),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
