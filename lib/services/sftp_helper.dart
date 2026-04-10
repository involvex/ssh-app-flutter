// lib/services/sftp_helper.dart
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SftpHelper {
  final SSHClient client;
  SftpHelper(this.client);

  Future<List<dynamic>> listDir(String path) async {
    final sftp = await client.sftp();
    final names = await sftp.listdir(path);
    return names;
  }

  Future<void> download(String remotePath, File localFile) async {
    // NOTE: Implementing streaming SFTP download depends on dartssh2 SftpFile API.
    // Placeholder implementation: read entire file into memory if supported by API.
    final sftp = await client.sftp();
    if (sftp == null) throw UnimplementedError('SFTP not supported');
    throw UnimplementedError('SFTP download not implemented for this dartssh2 version');
  }

  Future<void> upload(File localFile, String remotePath) async {
    // Placeholder until dartssh2 SFTP write API is adapted.
    throw UnimplementedError('SFTP upload not implemented for this dartssh2 version');
  }
}
