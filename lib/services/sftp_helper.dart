// lib/services/sftp_helper.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';

class SftpHelper {
  final SSHClient client;
  SftpHelper(this.client);

  Future<List<Map<String,dynamic>>> listDirWithType(String path) async {
    final sftp = await client.sftp();
    final names = await sftp.listdir(path);
    final List<Map<String,dynamic>> out = [];
    for (final n in names) {
      final filename = n.filename?.toString() ?? n.toString();
      final remotePath = (path == '.' || path == '/') ? filename : '$path/$filename';
      bool isDir = false;
      try {
        final attrs = await sftp.stat(remotePath);
        isDir = attrs.isDirectory;
      } catch (_) {
        isDir = false;
      }
      out.add({'name': filename, 'isDirectory': isDir});
    }
    return out;
  }

  Future<void> downloadStream(String remotePath, File localFile) async {
    final sftp = await client.sftp();
    final remoteFile = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    final sink = localFile.openWrite();
    try {
      await for (final chunk in remoteFile.read()) {
        if (chunk.isEmpty) continue;
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      await remoteFile.close();
      await sink.close();
    }
  }

  Future<void> upload(File localFile, String remotePath) async {
    final sftp = await client.sftp();
    final data = await localFile.readAsBytes();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.write | SftpFileOpenMode.create | SftpFileOpenMode.truncate);
    await file.writeBytes(Uint8List.fromList(data));
    await file.close();
  }
}
