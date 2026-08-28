import 'package:flutter/material.dart';

const Color ink = Color(0xFF202428);
const Color inkDark = Color(0xFF121417);
const Color pageBg = Color(0xFF0A0C0E);
const Color surface = Color(0xFF15181D);
const Color inputBg = Color(0xFF1C2025);
const Color textColor = Color(0xFFF2F4F6);
const Color gray = Color(0xFF9CA3AF);
const Color grayBorder = Color(0xFF2E3339);
const Color grayBg = Color(0xFF1C2025);
const Color whatsappGreen = Color(0xFF25D366);
const Color instagramPink = Color(0xFFE4405F);

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: inkDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
}