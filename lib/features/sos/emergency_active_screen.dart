import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import 'services/sms_service.dart';
import 'sos_engine.dart';

const String policeEmergencyNumber = '112'; // Verified official ERSS helpline in India

class EmergencyActiveScreen extends ConsumerStatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  ConsumerState<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends ConsumerState<EmergencyActiveScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  LatLng? _pendingCenter;

  void _onMapReady() {
    _isMapReady = true;
    if (_pendingCenter != null) {
      _mapController.move(_pendingCenter!, 15.0);
      _pendingCenter = null;
    }
  }

  void _updateMapCenter(LatLng target) {
    if (_isMapReady) {
      _mapController.move(target, 15.0);
    } else {
      _pendingCenter = target;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final sosNotifier = ref.read(sosProvider.notifier);

    // Handle 2-second temporary delivery result popup
    if (sosNotifier.lastDeliveryResultPopup != null) {
      final popupText = sosNotifier.lastDeliveryResultPopup!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    popupText.contains('✓') ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      popupText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: popupText.contains('✓')
                  ? AppTheme.safeGreen
                  : popupText.contains('opened')
                      ? AppTheme.warningOrange
                      : AppTheme.emergencyRed,
            ),
          );
          sosNotifier.clearDeliveryPopup();
        }
      });
    }

    if (sosState == SosState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    final rawLoc = sosNotifier.rawPosition;
    final hasPosition = (rawLoc != null);
    final LatLng currentLatLng = hasPosition
        ? LatLng(rawLoc.latitude, rawLoc.longitude)
        : const LatLng(19.0760, 72.8777); // Coords fallback (Mumbai, India)

    if (hasPosition && _isMapReady) {
      _updateMapCenter(currentLatLng);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: sosState == SosState.countdown
            ? AppTheme.warningOrange
            : AppTheme.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_rounded, color: AppTheme.emergencyRed, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      sosState == SosState.countdown ? "EMERGENCY COUNTDOWN" : "EMERGENCY ACTIVE",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sosState == SosState.countdown) ...[
                  const Spacer(),
                  Text(
                    "${sosNotifier.currentTimerValue}",
                    style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text("Alerts dispatching shortly...", style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.warningOrange),
                      onPressed: () => sosNotifier.cancelCountdown(),
                      child: const Text("CANCEL SOS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  // Coordinates Banner
                  Text(
                    hasPosition
                        ? "Live GPS: ${rawLoc.latitude.toStringAsFixed(4)}° N, ${rawLoc.longitude.toStringAsFixed(4)}° E"
                        : "Live GPS: Acquiring...",
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  // In-App FlutterMap Widget
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: currentLatLng,
                              initialZoom: 15.0,
                              onMapReady: _onMapReady,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.saaya',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: currentLatLng,
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.emergencyRed.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.my_location_rounded, color: AppTheme.emergencyRed, size: 28),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: AppTheme.safeGreen, size: 10),
                                  SizedBox(width: 6),
                                  Text("Live Tracking Active", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status Timeline Card
                  Card(
                    color: AppTheme.surfaceDark,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Status Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          const Divider(color: Colors.white24, height: 12),
                          _buildTimelineTile("Alert Triggered", true),
                          _buildTimelineTile("Location Obtained", hasPosition),
                          _buildTimelineTile("Contacts Processed (${sosNotifier.notifiedCount}/${sosNotifier.totalContacts})", sosNotifier.notifiedCount > 0),
                          _buildTimelineTile("Authorities Contacted", sosNotifier.policeContacted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Contact Police Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      icon: const Icon(Icons.local_police_rounded, color: Colors.amber),
                      label: const Text("🚨 CONTACT POLICE (112)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleContactPolice(context, sosNotifier),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Cancel SOS Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed, foregroundColor: Colors.white),
                      onPressed: () => _showCancelConfirmation(context, sosNotifier),
                      child: const Text("STOP / RESOLVE EMERGENCY", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTile(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isDone ? AppTheme.safeGreen : Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: isDone ? Colors.white : Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleContactPolice(BuildContext context, SosNotifier notifier) async {
    final settingsBox = StorageService.getSettingsBox();
    final userName = settingsBox.get('user_name', defaultValue: 'User');
    final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final policeMessage = '''🚨 SAAYA EMERGENCY ALERT

I need emergency assistance.

Name: $userName

📍 Current Location:
${notifier.locationSummary}

Time:
$timeStr

Please provide emergency assistance at my current location.''';

    notifier.markPoliceContacted();

    try {
      final callUri = Uri.parse('tel:$policeEmergencyNumber');
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      }
    } catch (e) {
      debugPrint('Police call exception: $e');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_police_rounded, color: AppTheme.emergencyRed),
            SizedBox(width: 8),
            Text("Police Emergency Action"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("✓ Police call initiated to 112", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.safeGreen)),
              const SizedBox(height: 12),
              const Text("Prepared Police Alert Message:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: Text(policeMessage, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text("Copy Message"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: policeMessage));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Police emergency message copied!"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text("Send SMS"),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await SmsService.sendEmergencySms(
                phoneNumber: policeEmergencyNumber,
                message: policeMessage,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, SosNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel SOS?"),
        content: const Text("Are you sure you want to deactivate the emergency alert?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Keep Active"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.resolveEmergency();
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }
}
