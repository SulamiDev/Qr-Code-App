import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key, required this.onUseScan});

  final ValueChanged<String> onUseScan;

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  MobileScannerController? _scannerController;
  String? _scanResult;
  bool _scanningPaused = false;
  bool _isScanningFile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    _scannerController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_scanningPaused) {
      _getScannerController().start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController?.stop();
    }
  }

  MobileScannerController _getScannerController() {
    return _scannerController ??= MobileScannerController(
          formats: [BarcodeFormat.qrCode],
          detectionSpeed: DetectionSpeed.normal,
        );
  }

  Future<void> _pickAndScan() async {
    if (_isScanningFile) return;
    if (kIsWeb) {
      showAppMessage(context, 'قراءة الصور غير متاحة على الويب');
      return;
    }
    _scannerController?.stop();
    setState(() {
      _isScanningFile = true;
      _scanResult = null;
      _scanningPaused = true;
    });
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;

      final capture =
          await MobileScannerPlatform.instance.analyzeImage(picked.path);
      final barcodes = capture?.barcodes ?? const <Barcode>[];
      final value = barcodes.isEmpty ? null : barcodes.first.rawValue;

      if (!mounted) return;
      setState(() {
        _scanResult = ((value == null || value.isEmpty) ? '' : value);
      });
      if (value == null || value.isEmpty) {
        showAppMessage(context, 'لم يتم العثور على رمز QR في هذه الصورة');
      }
    } catch (_) {
      showAppMessage(context, 'تعذر قراءة الصورة، تأكد من وضوح رمز QR');
    } finally {
      if (mounted) setState(() => _isScanningFile = false);
    }
  }

  void _onCameraDetect(BarcodeCapture capture) {
    if (_scanningPaused) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _scannerController?.stop();
    setState(() {
      _scanningPaused = true;
      _scanResult = value;
    });
  }

  void _resumeScanning() {
    setState(() {
      _scanningPaused = false;
      _scanResult = null;
    });
    _getScannerController().start();
  }

  void _useScannedText() {
    final value = _scanResult;
    if (value == null || value.isEmpty) return;
    if (_isScannedUrl) {
      _openScannedUrl();
      return;
    }
    widget.onUseScan(value);
  }

  bool get _isScannedUrl {
    final value = _scanResult;
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _openScannedUrl() async {
    final value = _scanResult;
    if (value == null || value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showAppMessage(context, 'تعذر فتح الرابط');
      }
    } catch (_) {
      if (mounted) showAppMessage(context, 'تعذر فتح الرابط');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadFailed = _scanResult == '';
    final hasResult = _scanResult != null && _scanResult!.isNotEmpty;

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
                _buildHeader(
                  title: 'امسح رمز QR بالكاميرا',
                  subtitle: 'وجّه الكاميرا نحو الرمز أو ارفع صورة تحتويه',
                ),
                const SizedBox(height: 24),
                if (_scanningPaused)
                  _buildFoundCard()
                else
                  _buildCameraCard(),
                const SizedBox(height: 20),
                if (_isScanningFile)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          'جارٍ قراءة الصورة...',
                          style: TextStyle(
                            color: gray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (uploadFailed) ...[
                  const Text(
                    'لم يتم العثور على رمز QR في الصورة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (hasResult) ...[
                  _buildScanResultCard(),
                  const SizedBox(height: 14),
                ],
                OutlinedButton.icon(
                  onPressed: _isScanningFile ? null : _pickAndScan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: const BorderSide(color: Colors.white38, width: 1.4),
                    backgroundColor: surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text(
                    'رفع صورة من المعرض',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: gray,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraCard() {
    return Container(
      height: 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gray.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _getScannerController(),
            onDetect: _onCameraDetect,
            fit: BoxFit.cover,
            placeholderBuilder: (context, child) => const ColoredBox(
              color: grayBg,
              child: Center(
                child: CircularProgressIndicator(color: gray),
              ),
            ),
            errorBuilder: (context, error, child) => _buildCameraError(error),
          ),
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.center_focus_strong_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'وجّه الكاميرا نحو رمز QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: grayBg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            denied
                ? Icons.no_photography_outlined
                : Icons.videocam_off_outlined,
            color: textColor,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            denied ? 'تحتاج للسماح باستخدام الكاميرا للمسح' : 'تعذر تشغيل الكاميرا',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _getScannerController().start(),
            style: TextButton.styleFrom(foregroundColor: textColor),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundCard() {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gray.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: textColor,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تم العثور على رمز QR',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اضغط لمسح رمز آخر',
            style: TextStyle(color: gray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _resumeScanning,
            style: FilledButton.styleFrom(
              backgroundColor: ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'مسح رمز آخر',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grayBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: textColor, size: 24),
              SizedBox(width: 8),
              Text(
                'نتيجة القراءة',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: grayBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SelectableText(
                      _scanResult!,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_isScannedUrl) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _openScannedUrl,
                    tooltip: 'فتح الرابط',
                    style: IconButton.styleFrom(
                      backgroundColor: textColor.withValues(alpha: 0.08),
                      foregroundColor: textColor,
                    ),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _scanResult!));
                    showAppMessage(context, 'تم نسخ النص');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: const BorderSide(color: Colors.white38, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text(
                    'نسخ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _useScannedText,
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _isScannedUrl
                        ? Icons.open_in_new_rounded
                        : Icons.qr_code_rounded,
                    size: 20,
                  ),
                  label: const Text(
                    'استخدام',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}