import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'services/cache_service.dart';
import 'providers/app_providers.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.init();

  runApp(
    const ProviderScope(
      child: AgriTwinApp(),
    ),
  );
}

class AgriTwinApp extends ConsumerWidget {
  const AgriTwinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeProvider);

    return MaterialApp(
      title: 'AgriTwin AI',
      debugShowCheckedModeBanner: false,
      locale: Locale(localeCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ta'),
        Locale('te'),
      ],
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008000), // Forest Green
          brightness: Brightness.light,
          background: const Color(0xFFF9FAFA), // Off-white
          surface: Colors.white,
          primary: const Color(0xFF008000), // Forest Green
          secondary: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFA),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFF1E293B), // Dark text
          displayColor: const Color(0xFF1E293B),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
