import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/contact_model.dart';
import '../../data/models/emergency_event_model.dart';

class StorageService {
  static const String contactsBox = 'contacts_box';
  static const String historyBox = 'history_box';
  static const String settingsBox = 'settings_box';

  static Future<void> init({bool isTest = false}) async {
    if (!isTest) {
      await Hive.initFlutter();
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ContactModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EmergencyEventModelAdapter());
    }

    if (!Hive.isBoxOpen(contactsBox)) {
      await Hive.openBox<ContactModel>(contactsBox);
    }
    if (!Hive.isBoxOpen(historyBox)) {
      await Hive.openBox<EmergencyEventModel>(historyBox);
    }
    if (!Hive.isBoxOpen(settingsBox)) {
      await Hive.openBox<dynamic>(settingsBox);
    }
  }

  static Box<ContactModel> getContactsBox() => Hive.box<ContactModel>(contactsBox);
  static Box<EmergencyEventModel> getHistoryBox() => Hive.box<EmergencyEventModel>(historyBox);
  static Box<dynamic> getSettingsBox() => Hive.box<dynamic>(settingsBox);
}
