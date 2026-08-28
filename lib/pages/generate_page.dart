import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';

enum _SaveAction { save, share }

enum QrContentType {
  text('نص', 'كتابة نص عادي', 'اكتب أي نص هنا...', Icons.text_fields_rounded),
  link('رابط', 'رابط موقع أو صفحة', 'الصق الرابط هنا...', Icons.link_rounded),
  whatsapp(
      'واتساب',
      'رقم للتواصل عبر واتساب',
      'أدخل رقم الواتساب (مثال: 9677XXXXXXX)',
      Icons.chat_rounded),
  instagram(
      'انستغرام',
      'حساب انستغرام',
      'أدخل اسم المستخدم',
      Icons.photo_camera_rounded),
  telegram(
      'تيليغرام',
      'قناة أو حساب تيليغرام',
      'أدخل اسم المستخدم أو القناة',
      Icons.send_rounded),
  youtube('يوتيوب', 'قناة يوتيوب', 'أدخل اسم القناة', Icons.play_circle_fill_rounded);

  const QrContentType(this.label, this.desc, this.hint, this.icon);

  final String label;
  final String desc;
  final String hint;
  final IconData icon;
}

class GenerateTab extends StatefulWidget {
  const GenerateTab({super.key});

  @override
  GenerateTabState createState() => GenerateTabState();
}

class GenerateTabState extends State<GenerateTab> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();

  String _data = 'Sulamidev';
  String _generatedFor = '';
  _SaveAction? _activeAction;
  Color _qrColor = Colors.black;
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _moduleShape = QrDataModuleShape.square;
  QrContentType _type = QrContentType.text;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void applyText(String value) {
    _controller.text = value;
    _generate();
  }

  void _generate() {
    final data = _buildData(_controller.text);
    setState(() {
      _data = data;
      _generatedFor = data;
    });
  }

  String _buildData(String input) {
    final t = input.trim();
    if (t.isEmpty) return 'Sulamidev';
    switch (_type) {
      case QrContentType.link:
        return t.startsWith('http://') || t.startsWith('https://')
            ? t
            : 'https://$t';
      case QrContentType.whatsapp:
        return 'https://wa.me/${t.replaceAll(RegExp(r'[^0-9+]'), '')}';
      case QrContentType.instagram:
        return 'https://instagram.com/${t.replaceAll('@', '')}';
      case QrContentType.telegram:
        return 'https://t.me/${t.replaceAll('@', '')}';
      case QrContentType.youtube:
        return 'https://youtube.com/@${t.replaceAll('@', '')}';
      case QrContentType.text:
        return t;
    }
  }

  void _clearInput() {
    _controller.clear();
    _generate();
  }

  Future<Uint8List> _captureQr() async {
    final boundary =
        _qrKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    if (_activeAction != null) return;
    setState(() => _activeAction = _SaveAction.save);
    try {
      final bytes = await _captureQr();
      final fileName =
          'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';

      bool hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }
      if (!hasAccess) {
        if (!mounted) return;
        showAppMessage(context, 'تم رفض إذن حفظ الصور');
        return;
      }
      await Gal.putImageBytes(bytes, name: fileName);
      if (!mounted) return;
      showAppMessage(context, 'تم الحفظ في معرض الصور');
    } on GalException catch (e) {
      if (!mounted) return;
      showAppMessage(context, 'تعذر الحفظ: ${e.type.message}');
    } catch (_) {
      if (!mounted) return;
      showAppMessage(context, 'حدث خطأ أثناء الحفظ');
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _shareQr() async {
    if (_activeAction != null) return;
    setState(() => _activeAction = _SaveAction.share);
    try {
      final bytes = await _captureQr();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          title: 'Qr Code',
          subject: 'Qr Code',
          text: _generatedFor,
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(context, 'حدث خطأ أثناء المشاركة');
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  String _colorHex(Color color) {
    String hex(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '#${hex(r)}${hex(g)}${hex(b)}';
  }

  Future<void> _pickQrColor(BuildContext ctx) async {
    var next = _qrColor;
    final picked = await showDialog<Color>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'اختر لون الرمز',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _qrColor,
            onColorChanged: (color) => next = color,
            enableAlpha: false,
            displayThumbColor: true,
            portraitOnly: true,
            hexInputBar: true,
            labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: textColor),
            child:
                const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, next),
            style: FilledButton.styleFrom(
              backgroundColor: ink,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('تطبيق', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() => _qrColor = picked);
      showAppMessage(context, 'تم تغيير لون الرمز');
    }
  }

  Future<void> _showDesignCard() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.palette_rounded, color: textColor, size: 22),
              SizedBox(width: 10),
              Text(
                'تخصيص التصميم',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => _pickQrColor(dialogContext),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: grayBg,
                    border: Border.all(color: grayBorder, width: 1.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _qrColor,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'لون الرمز',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _colorHex(_qrColor),
                        style: const TextStyle(
                          color: gray,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.colorize_rounded, color: gray, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildShapeChip(
                      label: 'مربع',
                      icon: Icons.square_rounded,
                      selected: _moduleShape == QrDataModuleShape.square,
                      onTap: () {
                        setState(() {
                          _moduleShape = QrDataModuleShape.square;
                          _eyeShape = QrEyeShape.square;
                        });
                        setDialogState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShapeChip(
                      label: 'دائري',
                      icon: Icons.circle_rounded,
                      selected: _moduleShape == QrDataModuleShape.circle,
                      onTap: () {
                        setState(() {
                          _moduleShape = QrDataModuleShape.circle;
                          _eyeShape = QrEyeShape.circle;
                        });
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'تم',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: pageBg,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQrCard(),
                const SizedBox(height: 18),
                const Text(
                  'صُنع بواسطة عبدالله السلمي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: grayBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_generatedFor.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: grayBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'المحتوى: ',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _generatedFor,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: _data,
                version: QrVersions.auto,
                size: 220,
                gapless: true,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: _eyeShape,
                  color: _qrColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: _moduleShape,
                  color: _qrColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'امسح الرمز ضوئياً لقراءته',
            style: TextStyle(
              color: gray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: grayBorder),
          const SizedBox(height: 14),
          _buildSaveShareRow(),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: grayBorder),
          const SizedBox(height: 14),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSaveShareRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconAction(
          icon: Icons.save_alt_rounded,
          label: 'حفظ',
          action: _SaveAction.save,
          onTap: _saveToGallery,
        ),
        const SizedBox(width: 26),
        _buildIconAction(
          icon: Icons.share_rounded,
          label: 'مشاركة',
          action: _SaveAction.share,
          onTap: _shareQr,
        ),
      ],
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required _SaveAction action,
    required VoidCallback onTap,
  }) {
    final isActive = _activeAction == action;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          elevation: isActive ? 0 : 5,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isActive ? null : onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ink, inkDark],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: isActive
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 21),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: grayBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickTypeSheet,
        child: Row(
          children: [
            Icon(_type.icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _type.label,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTypeSheet() async {
    final picked = await showModalBottomSheet<QrContentType>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: grayBorder,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر نوع المحتوى',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'سيتم توليد رمز QR مناسب للنوع المختار',
                textAlign: TextAlign.center,
                style: TextStyle(color: gray, fontSize: 13),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in QrContentType.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTypeCard(
                          t,
                          selected: t == _type,
                          onTap: () => Navigator.pop(sheetContext, t),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _type = picked);
      _generate();
    }
  }

  Widget _buildTypeCard(
    QrContentType type, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? textColor.withValues(alpha: 0.12) : inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white70 : grayBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.white : inputBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white70 : grayBorder,
                  width: 1.2,
                ),
              ),
              child: Icon(
                type.icon,
                color: selected ? ink : Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.desc,
                    style: const TextStyle(
                      color: gray,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)
            else
              const Icon(Icons.chevron_left_rounded, color: gray, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTypeDropdown(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: textColor, fontSize: 15),
                cursorColor: Colors.white,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _generate(),
                decoration: InputDecoration(
                  hintText: _type.hint,
                  hintStyle: const TextStyle(color: gray, fontSize: 14),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearInput,
                          icon: const Icon(Icons.close_rounded, color: gray),
                          tooltip: 'مسح',
                        )
                      : null,
                  filled: true,
                  fillColor: grayBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white70, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildDesignButton(),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _generate,
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text(
            'توليد رمز QR',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignButton() {
    return Tooltip(
      message: 'تخصيص التصميم',
      child: InkWell(
        onTap: _showDesignCard,
        customBorder: const CircleBorder(),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: grayBg,
            shape: BoxShape.circle,
            border: Border.all(color: grayBorder, width: 1.4),
          ),
          child: const Icon(Icons.palette_rounded, color: textColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildShapeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? ink : inputBg,
          border: Border.all(
            color: selected ? Colors.white70 : Colors.white24,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : gray,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}