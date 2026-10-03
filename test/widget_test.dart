import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:saaya/core/services/storage_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test_temp');
    await StorageService.init(isTest: true);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  test('SAAYA Core Storage Verification', () {
    expect(StorageService.getSettingsBox().isOpen, isTrue);
  });
}
