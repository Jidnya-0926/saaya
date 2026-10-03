import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  final settingsBox = StorageService.getSettingsBox();
  final bool isLoggedIn = settingsBox.get('is_logged_in', defaultValue: false);

  runApp(
    ProviderScope(
      child: SaayaApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class SaayaApp extends ConsumerWidget {
  final bool isLoggedIn;
  const SaayaApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SAAYA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: isLoggedIn ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
