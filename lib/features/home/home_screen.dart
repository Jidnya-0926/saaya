import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../contacts/contacts_screen.dart';
import '../location/gps_location_screen.dart';
import '../sos/emergency_active_screen.dart';
import '../sos/sos_engine.dart';
import '../settings/settings_screen.dart';
import '../voice/voice_screen.dart';
import '../voice/voice_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    ref.listen(sosProvider, (previous, next) {
      if (next == SosState.countdown || next == SosState.active) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const EmergencyActiveScreen()),
        );
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedKeyword = VoiceService.getKeyword();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("SAAYA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 20)),
            Text("Your Silent Protector", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Safety Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppTheme.safeGreen, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("SAFETY STATUS", style: TextStyle(fontSize: 11, color: AppTheme.safeGreen, fontWeight: FontWeight.bold)),
                        Text("YOU ARE SAFE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                    const Spacer(),
                    Chip(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppTheme.safeGreen.withValues(alpha: 0.2),
                      label: Text("🎙 '${savedKeyword.toUpperCase()}'", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.safeGreen)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Large SOS Button
              Center(
                child: GestureDetector(
                  onTap: () => ref.read(sosProvider.notifier).triggerSos(type: 'Button Tap'),
                  onLongPress: () => ref.read(sosProvider.notifier).triggerSos(type: 'Long Press'),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.emergencyRed,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emergencyRed.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("SOS", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                          SizedBox(height: 2),
                          Text("TAP FOR HELP", style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text("Tap or Long Press to trigger emergency", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              // Quick Actions Row 1 (GPS Share & Emergency Call)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.safeGreen,
                          side: const BorderSide(color: AppTheme.safeGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 20),
                        label: const Text("Share Location", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const GpsLocationScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 20, color: Colors.amber),
                        label: const Text("Emergency Call", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final primary = contacts.where((c) => c.isPrimary || c.priority == 1).toList();
                          final phone = primary.isNotEmpty ? primary.first.phoneNumber : '112';
                          final callUri = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(callUri)) {
                            await launchUrl(callUri);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Voice Activation Row Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded, size: 20, color: AppTheme.emergencyRed),
                  label: const Text("🛡 Test Voice Activation", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const VoiceScreen(isTestMode: true)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Status Cards Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ContactsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people_rounded, color: AppTheme.emergencyRed, size: 22),
                            const SizedBox(height: 8),
                            const Text("Trusted Contacts", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text("${contacts.length} Configured", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const VoiceScreen(isTestMode: false)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.mic_rounded, color: AppTheme.safeGreen, size: 22),
                            const SizedBox(height: 8),
                            const Text("Voice Keyword", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(savedKeyword.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
