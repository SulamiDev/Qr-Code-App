import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'pages/about_dialog.dart';
import 'pages/generate_page.dart';
import 'pages/read_page.dart';
import 'theme.dart';

void main() {
  runApp(const QrCodeApp());
}

class QrCodeApp extends StatelessWidget {
  const QrCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qr Code',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          brightness: Brightness.dark,
        ).copyWith(surface: surface),
        scaffoldBackgroundColor: pageBg,
        dialogTheme: const DialogThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            );
          }),
        ),
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  final GlobalKey<GenerateTabState> _generateKey = GlobalKey<GenerateTabState>();

  void _useScan(String value) {
    setState(() => _currentTab = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateKey.currentState?.applyText(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppBar(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [inkDark, ink],
                ),
              ),
            ),
            title: Row(
              children: [
                const SizedBox(width: 2),
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: QrImageView(
                    data: 'Sulamidev',
                    version: QrVersions.auto,
                    size: 38,
                    gapless: true,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    backgroundColor: Colors.black,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.white,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Qr Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => showAppInfo(context),
                tooltip: 'معلومات',
                color: Colors.white,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
        ),
      ),
      body: _currentTab == 1
          ? ReadPage(onUseScan: _useScan)
          : GenerateTab(key: _generateKey),
      bottomNavigationBar: NavigationBar(
        backgroundColor: inkDark,
        elevation: 8,
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        indicatorColor: Colors.white.withValues(alpha: 0.22),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_rounded, color: Colors.white60),
            selectedIcon: Icon(Icons.qr_code_2_rounded, color: Colors.white),
            label: 'توليد',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_rounded, color: Colors.white60),
            selectedIcon: Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
            ),
            label: 'قراءة',
          ),
        ],
      ),
    );
  }
}