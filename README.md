# Qr Code App

تطبيق Flutter عربي لإنشاء وقراءة رموز QR بسهولة تامة، مع أدوات تخصيص متقدمة وتصميم داكن أنيق.

A Flutter-based Arabic app for generating and reading QR codes with advanced customization options and a sleek dark design.

## ✨ Features / المميزات

### توليد رموز QR (Generate)
- توليد رموز QR لعدة أنواع من المحتوى:
  - نص عادي (Text)
  - رابط / صفحة (Link)
  - رقم واتساب (WhatsApp)
  - حساب انستغرام (Instagram)
  - قناة/حساب تيليغرام (Telegram)
  - قناة يوتيوب (YouTube)
- **تخصيص التصميم:**
  - تغيير لون الرمز من منتقي ألوان كامل (HEX/RGB)
  - شكل مربع أو دائري للمكوّنات والعيون
- **حفظ** رمز QR في معرض الصور
- **مشاركة** الرمز (صورة PNG) مع أي تطبيق

### قراءة رموز QR (Read)
- مسح مباشر بالكاميرا مع كشف فوري
- رفع صورة من المعرض وقراءة الرمز منها
- نسخ النتيجة بنقرة واحدة
- فتح الروابط المكتشفة مباشرة
- إرسال النتيجة مباشرة إلى تبويب التوليد

## 🛠 Technologies / التقنيات
- **Flutter** (Material 3)
- `qr_flutter` — توليد رموز QR
- `mobile_scanner` — المسح بالكاميرا
- `image_picker` — رفع الصور
- `gal` — الحفظ في معرض الصور
- `share_plus` — المشاركة
- `url_launcher` — فتح الروابط

## 🚀 Getting Started / التشغيل

```bash
# clone the repo
git clone https://github.com/AbdullahSulami/Qr-Code-App.git
cd Qr-Code-App

# install dependencies
flutter pub get

# run the app
flutter run
```

## 📁 Project Structure / هيكل المشروع

```
lib/
├── main.dart                 # App entry & navigation
├── theme.dart                # Colors & theme tokens
└── pages/
    ├── generate_page.dart    # QR generation tab
    ├── read_page.dart        # QR reading tab
    └── about_dialog.dart     # About dialog
```

## 👤 Author / المطوّر
صُنع بواسطة **عبدالله السلمي** (Abdullah Al-Sulami)
