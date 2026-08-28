import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

const String kData = 'Sulamidev';
const String kBase =
    'D:/Abood\'s Work/QrCode/qrcode/android/app/src/main/res';

const List<int> pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

void main() {
  final qrCode = QrCode.fromData(
    data: kData,
    errorCorrectLevel: QrErrorCorrectLevel.H,
  );
  final image = QrImage(qrCode);
  final n = image.moduleCount;

  const highRes = 1024;
  final canvas = img.Image(width: highRes, height: highRes, numChannels: 4);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

  final qrArea = (highRes * 0.72).round();
  final cell = qrArea ~/ n;
  final qrSize = cell * n;
  final offset = (highRes - qrSize) ~/ 2;

  final white = img.ColorRgb8(255, 255, 255);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (image.isDark(y, x)) {
        img.fillRect(
          canvas,
          x1: offset + x * cell,
          y1: offset + y * cell,
          x2: offset + (x + 1) * cell,
          y2: offset + (y + 1) * cell,
          color: white,
        );
      }
    }
  }

  const sizes = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  sizes.forEach((dir, size) {
    final resized = img.copyResize(
      canvas,
      width: size,
      height: size,
      interpolation: img.Interpolation.nearest,
    );
    final bytes = img.encodePng(resized);
    final head = bytes.take(8).toList();
    var isPng = head.length == pngSignature.length;
    for (var i = 0; i < head.length && isPng; i++) {
      isPng = head[i] == pngSignature[i];
    }
    if (!isPng) {
      stderr.writeln('ERROR: encoded output for $dir is not PNG!');
      exitCode = 1;
      return;
    }
    File('$kBase/$dir/ic_launcher.png').writeAsBytesSync(bytes);
    stdout.writeln('wrote $dir -> $size x $size');
  });
}