import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/contact_model.dart';
import '../../data/models/emergency_event_model.dart';
import '../../data/repositories/safety_repository.dart';
import 'services/sms_service.dart';

enum SosState { idle, countdown, active, cancelled, resolved }

class SosNotifier extends StateNotifier<SosState> {
  final Ref ref;
  Timer? _countdownTimer;
  int countdownSeconds = 5;
  int currentCountdown = 5;
  String triggerType = 'Button';
  int _elapsedSeconds = 0;
  Timer? _activeTimer;
  String _locationSummary = 'Location pending...';
  Position? _rawPosition;
  int _notifiedCount = 0;
  int _totalContacts = 0;
  String _smsDeliveryStatus = 'Pending';
  bool _policeContacted = false;
  String? _lastDeliveryResultPopup;

  SosNotifier(this.ref) : super(SosState.idle);

  int get currentTimerValue => currentCountdown;
  int get elapsedSeconds => _elapsedSeconds;
  String get locationSummary => _locationSummary;
  Position? get rawPosition => _rawPosition;
  int get notifiedCount => _notifiedCount;
  int get totalContacts => _totalContacts;
  String get smsDeliveryStatus => _smsDeliveryStatus;
  bool get policeContacted => _policeContacted;
  String? get lastDeliveryResultPopup => _lastDeliveryResultPopup;

  void clearDeliveryPopup() {
    _lastDeliveryResultPopup = null;
  }

  void markPoliceContacted() {
    _policeContacted = true;
    state = SosState.active; // trigger rebuild
  }

  void triggerSos({String type = 'Button', bool skipCountdown = true}) {
    if (state == SosState.active || state == SosState.countdown) return;

    triggerType = type;
    _policeContacted = false;
    _lastDeliveryResultPopup = null;

    if (skipCountdown) {
      _activateEmergency();
    } else {
      countdownSeconds = 5;
      currentCountdown = 5;
      state = SosState.countdown;

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (currentCountdown > 1) {
          currentCountdown--;
          state = SosState.countdown;
        } else {
          timer.cancel();
          _activateEmergency();
        }
      });
    }
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    state = SosState.cancelled;
    _logEvent('Cancelled');
    Timer(const Duration(seconds: 2), () {
      if (state == SosState.cancelled) {
        state = SosState.idle;
      }
    });
  }

  Future<void> _activateEmergency() async {
    state = SosState.active;
    _elapsedSeconds = 0;
    _notifiedCount = 0;
    _smsDeliveryStatus = 'Sending...';

    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
    });

    await _fetchAndShareLocation();
    await _executeEmergencyPipeline();
  }

  Future<void> _fetchAndShareLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationSummary = 'GPS disabled';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationSummary = 'Location permission denied';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationSummary = 'Location permission permanently denied';
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _rawPosition = position;
      _locationSummary = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    } catch (e) {
      _locationSummary = 'Unable to acquire location: $e';
    }
  }

  Future<void> _executeEmergencyPipeline() async {
    final List<ContactModel> contacts = ref.read(contactsProvider);
    _totalContacts = contacts.length;
    _notifiedCount = 0;

    final message = '''EMERGENCY! I may need help. This alert was triggered through SAAYA.
My current location:
$_locationSummary

Please contact me or call emergency services if necessary.''';

    bool usedDirectSms = false;
    bool usedFallback = false;

    if (contacts.isEmpty) {
      _smsDeliveryStatus = 'No Contacts Configured';
      _lastDeliveryResultPopup = 'No trusted contacts configured';
      state = SosState.active; // rebuild UI
      return;
    }

    for (var contact in contacts) {
      final result = await SmsService.sendEmergencySms(
        phoneNumber: contact.phoneNumber,
        message: message,
      );

      if (result == SmsResult.sent) {
        _notifiedCount++;
        usedDirectSms = true;
      } else if (result == SmsResult.composerFallback) {
        _notifiedCount++;
        usedFallback = true;
      }
    }

    if (usedDirectSms && _notifiedCount == _totalContacts) {
      _smsDeliveryStatus = 'Automatic SMS Dispatched';
      _lastDeliveryResultPopup = '✓ Emergency messages sent successfully';
    } else if (usedDirectSms && _notifiedCount > 0) {
      _smsDeliveryStatus = 'Partial SMS Dispatched';
      _lastDeliveryResultPopup = 'Emergency messages: $_notifiedCount/$_totalContacts sent';
    } else if (usedFallback) {
      _smsDeliveryStatus = 'SMS Composer Launched';
      _lastDeliveryResultPopup = 'SMS composer opened';
    } else {
      _smsDeliveryStatus = 'Failed / No Contacts';
      _lastDeliveryResultPopup = 'Unable to send emergency messages';
    }

    final primaryContacts = contacts.where((c) => c.isPrimary || c.priority == 1).toList();
    if (primaryContacts.isNotEmpty) {
      try {
        final callUri = Uri.parse('tel:${primaryContacts.first.phoneNumber}');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        }
      } catch (e) {
        debugPrint('Failed to initiate emergency call: $e');
      }
    }

    _logEvent('Active');
    state = SosState.active; // rebuild UI to trigger popup
  }

  void resolveEmergency() {
    _countdownTimer?.cancel();
    _activeTimer?.cancel();
    state = SosState.resolved;
    _logEvent('Resolved');

    Timer(const Duration(seconds: 2), () {
      if (state == SosState.resolved) {
        state = SosState.idle;
      }
    });
  }

  void _logEvent(String status) {
    try {
      final repo = ref.read(safetyRepositoryProvider);
      final event = EmergencyEventModel(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        triggerType: triggerType,
        contactsNotifiedCount: _notifiedCount,
        locationSummary: _locationSummary,
        resolutionStatus: status,
        durationSeconds: _elapsedSeconds,
      );
      repo.addEmergencyEvent(event);
    } catch (e) {
      debugPrint('Failed to log emergency event: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _activeTimer?.cancel();
    super.dispose();
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  return SosNotifier(ref);
});

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<ContactModel>>((ref) {
  return ContactsNotifier(ref);
});

class ContactsNotifier extends StateNotifier<List<ContactModel>> {
  final Ref ref;
  ContactsNotifier(this.ref) : super([]) {
    loadContacts();
  }

  void loadContacts() {
    final repo = ref.read(safetyRepositoryProvider);
    state = repo.getContacts();
  }

  Future<void> addContact(ContactModel contact) async {
    final repo = ref.read(safetyRepositoryProvider);
    await repo.addContact(contact);
    loadContacts();
  }

  Future<void> updateContact(ContactModel contact) async {
    final repo = ref.read(safetyRepositoryProvider);
    await repo.updateContact(contact);
    loadContacts();
  }

  Future<void> deleteContact(String id) async {
    final repo = ref.read(safetyRepositoryProvider);
    await repo.deleteContact(id);
    loadContacts();
  }
}
