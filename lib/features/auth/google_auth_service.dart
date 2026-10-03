import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/services/storage_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _saveUserSession(account);
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _saveUserSession(account);
      }
      return account;
    } catch (e) {
      debugPrint('Google Silent Sign-In Error: $e');
      return null;
    }
  }

  static Future<void> _saveUserSession(GoogleSignInAccount account) async {
    final settingsBox = StorageService.getSettingsBox();
    await settingsBox.put('user_name', account.displayName ?? 'Google User');
    await settingsBox.put('user_email', account.email);
    await settingsBox.put('user_photo', account.photoUrl ?? '');
    await settingsBox.put('is_logged_in', true);
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
    final settingsBox = StorageService.getSettingsBox();
    await settingsBox.put('is_logged_in', false);
  }
}
