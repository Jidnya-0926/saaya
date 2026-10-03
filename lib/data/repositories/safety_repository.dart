import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../models/contact_model.dart';
import '../models/emergency_event_model.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository();
});

class SafetyRepository {
  // Contacts CRUD
  List<ContactModel> getContacts() {
    final box = StorageService.getContactsBox();
    return box.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<void> addContact(ContactModel contact) async {
    final box = StorageService.getContactsBox();
    await box.put(contact.id, contact);
  }

  Future<void> updateContact(ContactModel contact) async {
    final box = StorageService.getContactsBox();
    await box.put(contact.id, contact);
  }

  Future<void> deleteContact(String id) async {
    final box = StorageService.getContactsBox();
    await box.delete(id);
  }

  // Emergency History CRUD
  List<EmergencyEventModel> getHistory() {
    final box = StorageService.getHistoryBox();
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addEmergencyEvent(EmergencyEventModel event) async {
    final box = StorageService.getHistoryBox();
    await box.put(event.id, event);
  }

  Future<void> clearHistory() async {
    final box = StorageService.getHistoryBox();
    await box.clear();
  }
}
