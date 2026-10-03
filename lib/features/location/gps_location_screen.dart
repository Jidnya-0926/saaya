import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../sos/services/sms_service.dart';
import '../sos/sos_engine.dart';

class GpsLocationScreen extends ConsumerStatefulWidget {
  const GpsLocationScreen({super.key});

  @override
  ConsumerState<GpsLocationScreen> createState() => _GpsLocationScreenState();
}

class _GpsLocationScreenState extends ConsumerState<GpsLocationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  bool _permissionDenied = false;
  bool _permanentlyDenied = false;
  bool _serviceDisabled = false;
  bool _isApproximate = false;

  final MapController _mapController = MapController();
  bool _isMapReady = false;
  LatLng? _pendingTarget;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  void _onMapReady() {
    _isMapReady = true;
    if (_pendingTarget != null) {
      _mapController.move(_pendingTarget!, 15.0);
      _pendingTarget = null;
    }
  }

  void _updateMapCamera(LatLng target) {
    if (_isMapReady) {
      _mapController.move(target, 15.0);
    } else {
      _pendingTarget = target;
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _permissionDenied = false;
      _permanentlyDenied = false;
      _serviceDisabled = false;
      _isApproximate = false;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _serviceDisabled = true;
          _errorMessage = "Location Services Disabled. Please turn on Location/GPS to use SAAYA's location safety features.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        bool userConsented = await _showLocationRationaleDialog();
        if (!userConsented) {
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
            _errorMessage = "Location permission is required to display and share your position.";
          });
          return;
        }

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
            _errorMessage = "Location permission was denied.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _permanentlyDenied = true;
          _errorMessage = "Location permission is permanently denied in System Settings. Please grant permission manually.";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      LocationAccuracyStatus accuracyStatus = await Geolocator.getLocationAccuracy();
      bool isApprox = (accuracyStatus == LocationAccuracyStatus.reduced);

      setState(() {
        _isLoading = false;
        _currentPosition = position;
        _isApproximate = isApprox;
      });

      _updateMapCamera(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Unable to determine current location: $e";
      });
    }
  }

  Future<bool> _showLocationRationaleDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.emergencyRed),
                SizedBox(width: 8),
                Text("Location Permission Required"),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SAAYA uses your current location to:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text("• Show your position on the map"),
                SizedBox(height: 4),
                Text("• Share your location with trusted contacts"),
                SizedBox(height: 4),
                Text("• Include your position in emergency SOS alerts"),
                SizedBox(height: 12),
                Text(
                  "Your location is used strictly when required by these safety features.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text("Continue"),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _generateGoogleMapsUrl(double lat, double lng) {
    return "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
  }

  Future<void> _sendToTrustedContacts() async {
    if (_currentPosition == null) return;

    final contacts = ref.read(contactsProvider);
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No trusted contacts configured. Please add contacts first."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final mapsUrl = _generateGoogleMapsUrl(lat, lng);

    final message = '''SAAYA — LIVE LOCATION

I am sharing my current location with you.

📍 My current location:
$mapsUrl

Latitude: $lat
Longitude: $lng

Please check my location and contact me if necessary.''';

    int successCount = 0;
    bool usedFallback = false;

    for (var contact in contacts) {
      final res = await SmsService.sendEmergencySms(
        phoneNumber: contact.phoneNumber,
        message: message,
      );

      if (res == SmsResult.sent) {
        successCount++;
      } else if (res == SmsResult.composerFallback) {
        usedFallback = true;
      }
    }

    if (!mounted) return;

    String toastText;
    Color toastBg;
    if (successCount == contacts.length) {
      toastText = "✓ Location sent successfully";
      toastBg = AppTheme.safeGreen;
    } else if (usedFallback) {
      toastText = "SMS composer opened";
      toastBg = AppTheme.warningOrange;
    } else {
      toastText = "Unable to send location";
      toastBg = AppTheme.emergencyRed;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              toastText.contains('✓') ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(toastText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: toastBg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS Location Share"),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Getting your current location...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_rounded, size: 70, color: AppTheme.emergencyRed),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        if (_permanentlyDenied)
                          ElevatedButton(
                            onPressed: () => openAppSettings(),
                            child: const Text("Open System Settings"),
                          )
                        else if (_serviceDisabled)
                          ElevatedButton(
                            onPressed: () => Geolocator.openLocationSettings(),
                            child: const Text("Open Location Settings"),
                          )
                        else if (_permissionDenied)
                          ElevatedButton.icon(
                            onPressed: _fetchLocation,
                            icon: const Icon(Icons.security_rounded),
                            label: const Text("Grant Permission"),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _fetchLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry Location Fetch"),
                          ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Approximate Location Warning Banner
                    if (_isApproximate)
                      Container(
                        width: double.infinity,
                        color: AppTheme.warningOrange.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.warningOrange, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Approximate location enabled. Enable Precise location in settings for exact position.",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Geolocator.openLocationSettings(),
                              child: const Text("Settings", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    // Flutter Map
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
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
                                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: AppTheme.emergencyRed,
                                    size: 45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Position Details Card & Actions
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Current GPS Coordinates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 20),
                                        onPressed: () {
                                          final mapsUrl = _generateGoogleMapsUrl(_currentPosition!.latitude, _currentPosition!.longitude);
                                          Clipboard.setData(ClipboardData(text: mapsUrl));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Google Maps link copied to clipboard!"),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}"),
                                  const SizedBox(height: 4),
                                  Text("Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}"),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text("Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m"),
                                      const SizedBox(width: 8),
                                      Chip(
                                        padding: EdgeInsets.zero,
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                        backgroundColor: _isApproximate
                                            ? AppTheme.warningOrange.withValues(alpha: 0.2)
                                            : AppTheme.safeGreen.withValues(alpha: 0.2),
                                        label: Text(
                                          _isApproximate ? "APPROXIMATE" : "PRECISE",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _isApproximate ? AppTheme.warningOrange : AppTheme.safeGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _fetchLocation,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text("Refresh"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _sendToTrustedContacts,
                                  icon: const Icon(Icons.send_rounded),
                                  label: const Text("Send to Contacts"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
