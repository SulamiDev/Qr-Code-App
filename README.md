# Qr Code App

A Flutter-based app for generating and reading QR codes, with advanced customization options and a sleek dark design.

## Features

### Generate
- Create QR codes for multiple content types:
  - Plain text
  - Links / URLs
  - WhatsApp numbers
  - Instagram profiles
  - Telegram channels/accounts
  - YouTube channels
- **Design customization:**
  - Change the QR color with a full color picker (HEX/RGB)
  - Square or rounded modules and eyes
- **Save** the QR code to the photo gallery as PNG
- **Share** the QR code with any app

### Read
- Direct camera scanning with instant detection
- Upload an image from the gallery and scan the code in it
- Copy the result with one tap
- Open detected links directly
- Send the scanned content straight to the Generate tab

## Technologies
- **Flutter** (Material 3)
- `qr_flutter` — QR generation
- `mobile_scanner` — camera scanning
- `image_picker` — image upload
- `gal` — save to gallery
- `share_plus` — sharing
- `url_launcher` — opening links

## Getting Started

```bash
git clone https://github.com/AbdullahSulami/Qr-Code-App.git
cd Qr-Code-App

flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry & navigation
├── theme.dart                # Colors & theme tokens
└── pages/
    ├── generate_page.dart    # QR generation tab
    ├── read_page.dart        # QR reading tab
    └── about_dialog.dart     # About dialog
```

## Author
Built by **Abdullah Al-Sulami**
