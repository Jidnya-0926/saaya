import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationGranted = false;
  bool _isPrecise = false;
  bool _locationServiceEnabled = true;

  bool _smsGranted = false;
  bool _phoneGranted = false;
  bool _micGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final locPerm = await Geolocator.checkPermission();
    final isLocGranted = (locPerm == LocationPermission.whileInUse || locPerm == LocationPermission.always);

    bool precise = false;
    if (isLocGranted) {
      final accuracy = await Geolocator.getLocationAccuracy();
      precise = (accuracy == LocationAccuracyStatus.precise);
    }

    final sms = await Permission.sms.isGranted;
    final phone = await Permission.phone.isGranted;
    final mic = await Permission.microphone.isGranted;
    final notif = await Permission.notification.isGranted;

    if (!mounted) return;
    setState(() {
      _locationServiceEnabled = serviceEnabled;
      _locationGranted = isLocGranted;
      _isPrecise = precise;
      _smsGranted = sms;
      _phoneGranted = phone;
      _micGranted = mic;
      _notificationGranted = notif;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    await permission.request();
    await _checkPermissions();
  }

  Future<void> _requestLocationPermission() async {
    await Geolocator.requestPermission();
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    String locStatusText;
    Color locStatusColor;

    if (!_locationServiceEnabled) {
      locStatusText = "GPS Services Disabled";
      locStatusColor = AppTheme.warningOrange;
    } else if (_locationGranted) {
      locStatusText = _isPrecise ? "Allowed (Precise)" : "Allowed (Approximate)";
      locStatusColor = AppTheme.safeGreen;
    } else {
      locStatusText = "Not Allowed";
      locStatusColor = AppTheme.emergencyRed;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Permission Center"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "SAAYA requires specific permissions to function effectively during emergencies.",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 20),
          // Location Permission Tile
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: const Text("Location Permission", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Status: $locStatusText\nRequired for map positioning and SOS emergency location sharing."),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () {
                  if (!_locationGranted) {
                    _requestLocationPermission();
                  } else {
                    openAppSettings();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  backgroundColor: _locationGranted ? Colors.grey.shade700 : locStatusColor,
                ),
                child: Text(_locationGranted ? "Manage" : "Grant", style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
          _buildPermissionTile(
            title: "SMS Permission",
            subtitle: "Required to automatically send emergency text messages.",
            isGranted: _smsGranted,
            onPressed: () => _requestPermission(Permission.sms),
          ),
          _buildPermissionTile(
            title: "Phone Call Permission",
            subtitle: "Required to initiate emergency calls to primary contacts.",
            isGranted: _phoneGranted,
            onPressed: () => _requestPermission(Permission.phone),
          ),
          _buildPermissionTile(
            title: "Microphone Permission",
            subtitle: "Required for voice-triggered SOS assistance.",
            isGranted: _micGranted,
            onPressed: () => _requestPermission(Permission.microphone),
          ),
          _buildPermissionTile(
            title: "Notification Permission",
            subtitle: "Required to alert you of active emergency states.",
            isGranted: _notificationGranted,
            onPressed: () => _requestPermission(Permission.notification),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text("Open System Settings"),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isGranted
            ? const Chip(
                backgroundColor: Color(0xFFE8F5E9),
                label: Text("Granted", style: TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold)),
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  backgroundColor: AppTheme.emergencyRed,
                ),
                child: const Text("Grant", style: TextStyle(fontSize: 13)),
              ),
      ),
    );
  }
}
