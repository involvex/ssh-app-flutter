import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _opencodeZenApiKeyKey = 'opencode_zen_api_key';
  static const String _kiloApiKeyKey = 'kilo_api_key';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String> readOpencodeZenApiKey() async {
    return await _storage.read(key: _opencodeZenApiKeyKey) ?? '';
  }

  static Future<String> readKiloApiKey() async {
    return await _storage.read(key: _kiloApiKeyKey) ?? '';
  }

  static Future<void> writeOpencodeZenApiKey(String value) async {
    if (value.isEmpty) {
      await _storage.delete(key: _opencodeZenApiKeyKey);
      return;
    }
    await _storage.write(key: _opencodeZenApiKeyKey, value: value);
  }

  static Future<void> writeKiloApiKey(String value) async {
    if (value.isEmpty) {
      await _storage.delete(key: _kiloApiKeyKey);
      return;
    }
    await _storage.write(key: _kiloApiKeyKey, value: value);
  }

  /// Moves legacy plain-text keys from [settings] into secure storage.
  ///
  /// Returns `true` when keys were migrated and should be removed from settings.
  static Future<bool> migrateApiKeysFromSettings(
    Map<String, dynamic> settings,
  ) async {
    var migrated = false;

    final opencodeKey = settings['opencodeZenApiKey'] as String?;
    if (opencodeKey != null && opencodeKey.isNotEmpty) {
      await writeOpencodeZenApiKey(opencodeKey);
      settings.remove('opencodeZenApiKey');
      migrated = true;
    }

    final kiloKey = settings['kiloApiKey'] as String?;
    if (kiloKey != null && kiloKey.isNotEmpty) {
      await writeKiloApiKey(kiloKey);
      settings.remove('kiloApiKey');
      migrated = true;
    }

    return migrated;
  }

  static Future<void> importApiKeysFromBackup(
    Map<String, dynamic> settings,
  ) async {
    final opencodeKey = settings['opencodeZenApiKey'] as String?;
    if (opencodeKey != null && opencodeKey.isNotEmpty) {
      await writeOpencodeZenApiKey(opencodeKey);
    }

    final kiloKey = settings['kiloApiKey'] as String?;
    if (kiloKey != null && kiloKey.isNotEmpty) {
      await writeKiloApiKey(kiloKey);
    }

    settings.remove('opencodeZenApiKey');
    settings.remove('kiloApiKey');
  }

  static Map<String, dynamic> stripApiKeys(Map<String, dynamic> settings) {
    return Map<String, dynamic>.from(settings)
      ..remove('opencodeZenApiKey')
      ..remove('kiloApiKey');
  }
}
