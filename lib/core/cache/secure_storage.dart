import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  // Constants keys
  static const String _tokenKey = 'auth_jwt_token';
  static const String _userSessionKey = 'auth_user_session';
  static const String _onboardingSeenKey = 'onboarding_seen';
  static const String _activeRaidKey = 'active_raid';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUserSession(String sessionJson) async {
    await _storage.write(key: _userSessionKey, value: sessionJson);
  }

  Future<String?> getUserSession() async {
    return await _storage.read(key: _userSessionKey);
  }

  Future<void> deleteUserSession() async {
    await _storage.delete(key: _userSessionKey);
  }

  // ── Active Raid ──────────────────────────────────────────────────
  // Survives app kills so the user can resume a running raid.
  // Schema: { raidId, zoneId, zoneName, colour, startedAt (ISO), durationMins, status }
  // status: "running" | "awaiting_verification"

  Future<void> saveActiveRaid(Map<String, dynamic> raid) async {
    await _storage.write(key: _activeRaidKey, value: jsonEncode(raid));
  }

  Future<Map<String, dynamic>?> getActiveRaid() async {
    final raw = await _storage.read(key: _activeRaidKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveRaid() async {
    await _storage.delete(key: _activeRaidKey);
  }

  // ── Onboarding ────────────────────────────────────────────────────
  Future<void> setOnboardingSeen() async {
    await _storage.write(key: _onboardingSeenKey, value: 'true');
  }

  Future<bool> hasSeenOnboarding() async {
    return (await _storage.read(key: _onboardingSeenKey)) == 'true';
  }

  Future<void> clearAll() async {
    // Preserve the onboarding flag across sign-out so returning users don't
    // see the tutorial again.
    final seenOnboarding = await hasSeenOnboarding();
    await _storage.deleteAll();
    if (seenOnboarding) {
      await setOnboardingSeen();
    }
  }
}
