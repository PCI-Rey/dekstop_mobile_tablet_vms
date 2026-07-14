import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/storage_service.dart';
import 'core/network/dio_client.dart';
import 'core/shared/locales/translations.dart';
import 'core/shared/routes/app_pages.dart';
import 'core/shared/utils/page_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Screen/device detection on startup to lock orientation.
  // Gold standard:
  //   HP Android  (Samsung A55, shortestSide ≈ 360dp) → Portrait
  //   Tablet Android (Tab A8,   shortestSide ≈ 800dp) → Landscape
  // Lock orientasi: app ini eksklusif untuk tablet → selalu Landscape.
  // isTabletFromPhysicalSize() tidak reliable saat startup (physicalSize
  // bisa return Size.zero sebelum window siap). Lock landscape langsung.
  if (GetPlatform.isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Initialize and register global services
  final storageService = await Get.putAsync<StorageService>(
    () => StorageService().init(),
  );
  Get.put<DioClient>(DioClient(storageService));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VMS Operator Tablet',
      debugShowCheckedModeBanner: false,
      // Theme Settings (Material 3 with custom colors matching the UI references)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F62FE), // Sleek tech blue color
          brightness: Brightness.light,
          primary: const Color(0xFF0F62FE),
          surface: Colors.grey[50]!,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F62FE),
          brightness: Brightness.dark,
          surface: Colors.grey[950],
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.system, // follow system light/dark
      // Localizations Setup
      translations: AppTranslations(),
      locale: const Locale('id'), // Default Indonesian
      fallbackLocale: const Locale('en'),

      // Page Navigation Setup
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      // Log every navigation to the debug console
      navigatorObservers: [PageLogger()],
    );
  }
}
