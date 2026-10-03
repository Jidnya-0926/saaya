import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_screen.dart';
import '../auth/google_auth_service.dart';
import '../history/history_screen.dart';
import 'permissions_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsBox = StorageService.getSettingsBox();
    final name = settingsBox.get('user_name', defaultValue: 'User');
    final email = settingsBox.get('user_email', defaultValue: '');
    final phone = settingsBox.get('user_phone', defaultValue: '');
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Appearance Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text("APPEARANCE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    currentTheme == ThemeMode.system ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: currentTheme == ThemeMode.system ? AppTheme.emergencyRed : Colors.grey,
                  ),
                  title: const Text("System Default"),
                  subtitle: const Text("Match Android system theme"),
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    currentTheme == ThemeMode.light ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: currentTheme == ThemeMode.light ? AppTheme.emergencyRed : Colors.grey,
                  ),
                  title: const Text("Light Mode"),
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    currentTheme == ThemeMode.dark ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: currentTheme == ThemeMode.dark ? AppTheme.emergencyRed : Colors.grey,
                  ),
                  title: const Text("Dark Mode"),
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // General Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text("GENERAL & EMERGENCY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded),
                  title: const Text("Permission Center"),
                  subtitle: const Text("Manage Location, SMS, Call & Mic permissions"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PermissionsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text("Emergency History"),
                  subtitle: const Text("View past emergency triggers & event logs"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Clear session and return to authentication screen"),
                  onTap: () async {
                    await GoogleAuthService.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
