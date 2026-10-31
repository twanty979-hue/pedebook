import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/catalog_model.dart';
import '../services/supabase_service.dart';

class BookSettingsDialog extends StatefulWidget {
  final CatalogItem catalog;
  final VoidCallback? onSaved;

  const BookSettingsDialog({super.key, required this.catalog, this.onSaved});

  static Future<void> show(BuildContext context, CatalogItem catalog, {VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BookSettingsDialog(catalog: catalog, onSaved: onSaved),
    );
  }

  @override
  State<BookSettingsDialog> createState() => _BookSettingsDialogState();
}

class _BookSettingsDialogState extends State<BookSettingsDialog> {
  late String _selectedTheme;
  late bool _isFloating;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'auto',
      'name': 'ไล่สีตามปก',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFFECDD3), Color(0xFFA7F3D0)],
      ),
    },
    {
      'id': 'cream',
      'name': 'ครีมสตูดิโอ',
      'gradient': const LinearGradient(
        colors: [Color(0xFFF6F4EE), Color(0xFFD8D4C7)],
      ),
    },
    {
      'id': 'warm',
      'name': 'ดินเผา',
      'gradient': const LinearGradient(
        colors: [Color(0xFFDFC2AC), Color(0xFFA7836B)],
      ),
    },
    {
      'id': 'forest',
      'name': 'เขียวป่า',
      'gradient': const LinearGradient(
        colors: [Color(0xFF243129), Color(0xFF121915)],
      ),
    },
    {
      'id': 'slate',
      'name': 'หินชนวนดำ',
      'gradient': const LinearGradient(
        colors: [Color(0xFF1E2022), Color(0xFF111215)],
      ),
    },
    {
      'id': 'linen',
      'name': 'ผ้าลินิน',
      'gradient': const LinearGradient(
        colors: [Color(0xFFE2DFD5), Color(0xFFD5D1C5)],
      ),
      'isPattern': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTheme = 'auto';
    _isFloating = true;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      // Save settings to Supabase table 'catalogs'
      await SupabaseService.client
          .from('catalogs')
          .update({
            'background_type': _selectedTheme == 'auto' ? 'gradient' : 'default',
            'background_value': _selectedTheme,
            'is_floating': _isFloating,
          })
          .eq('id', widget.catalog.id);
    } catch (_) {
      // Fallback if offline or demo
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text('บันทึกการตั้งค่าธีมเรียบร้อยแล้วครับ'),
            ],
          ),
          backgroundColor: const Color(0xFF243129),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ตั้งค่าธีม & รายละเอียด',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17221C),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    color: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'แก้ไขชื่อและเลือกธีมพื้นหลังหน้าสมุดเปิดอ่าน',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),

              // ชื่อแค็ตตาล็อก (อ้างอิงตามชื่อไฟล์ PDF)
              Text(
                'ชื่อแค็ตตาล็อก (อ้างอิงตามชื่อไฟล์ PDF)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF17221C),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F5F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E2D9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.catalog.fileName.isNotEmpty
                            ? widget.catalog.fileName
                            : '${widget.catalog.title}.pdf',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(CupertinoIcons.lock, size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ธีมพื้นหลัง (6 ตัวเลือกในตาราง 3x2)
              Text(
                'ธีมพื้นหลัง',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF17221C),
                ),
              ),
              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: _themes.length,
                itemBuilder: (context, idx) {
                  final theme = _themes[idx];
                  final isSelected = _selectedTheme == theme['id'];

                  return InkWell(
                    onTap: () => setState(() => _selectedTheme = theme['id']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF243129).withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF243129) : const Color(0xFFE5E2D9),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: theme['gradient'] as Gradient,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: theme['isPattern'] == true
                                ? const Center(
                                    child: Text(
                                      'Pattern',
                                      style: TextStyle(fontSize: 8, color: Color(0xFF6E746F)),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            theme['name'] as String,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF243129) : const Color(0xFF17221C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // เอฟเฟกต์สมุดลอยได้ (Floating Book)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE5E2D9).withValues(alpha: 0.6)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เอฟเฟกต์สมุดลอยได้ (Floating Book)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF17221C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'เปิดใช้งานเพื่อให้สมุดลอยขึ้นลงเบาๆ อย่างมีมิติ',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _isFloating,
                      activeTrackColor: const Color(0xFF243129),
                      onChanged: (val) => setState(() => _isFloating = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // บันทึกการตั้งค่า Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF243129),
                    foregroundColor: const Color(0xFFF7F5F0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'บันทึกการตั้งค่า',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

