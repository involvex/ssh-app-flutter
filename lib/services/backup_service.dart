import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'config_service.dart';
import '../constants/app_metadata.dart';
import 'secure_storage_service.dart';
import 'widget_profile_service.dart';

class BackupService {
  static const int _backupVersion = 1;

  static Future<void> export() async {
    final settings = SecureStorageService.stripApiKeys(
      await ConfigService.getSettings(),
    );
    final data = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profiles': await ConfigService.getProfiles(),
      'sshKeys': await ConfigService.getSSHKeys(),
      'snippets': await ConfigService.getSnippets(),
      'settings': settings,
      'lastSession': await ConfigService
          .getLastSession(), // nullable; serialized as null if absent
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ssh_app_backup.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '$kAppDisplayName Backup',
      ),
    );
  }

  static Future<String> import() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return 'Import cancelled';

    final path = result.files.single.path;
    if (path == null) throw Exception('Could not read selected file');

    final jsonString = await File(path).readAsString();
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final version = data['version'] as int?;
    if (version != _backupVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    if (data['profiles'] is List) {
      await ConfigService.saveProfiles(
        (data['profiles'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    }
    if (data['sshKeys'] is List) {
      await ConfigService.saveSSHKeys(
        (data['sshKeys'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    }
    if (data['snippets'] is List) {
      await ConfigService.saveSnippets(
        (data['snippets'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    }
    if (data['settings'] is Map) {
      final settings = Map<String, dynamic>.from(data['settings'] as Map);
      await SecureStorageService.importApiKeysFromBackup(settings);
      await ConfigService.saveSettings(settings);
    }
    if (data['lastSession'] is Map) {
      await ConfigService.saveLastSession(
        Map<String, dynamic>.from(data['lastSession'] as Map),
      );
    } else if (data.containsKey('lastSession') && data['lastSession'] == null) {
      // Skip — no last session to restore
    }

    await WidgetProfileService.syncFromConfig();

    return 'Import successful';
  }
}
