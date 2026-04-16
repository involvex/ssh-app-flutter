// lib/services/sftp_helper.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';

class SftpHelper {
  final SSHClient client;
  SftpHelper(this.client);

  Future<List<Map<String, dynamic>>> listDirWithType(String path) async {
    final sftp = await client.sftp();
    final names = await sftp.listdir(path);
    return names
        .map((n) => <String, dynamic>{
              'name': n.filename.toString(),
              'isDirectory': n.attr.isDirectory,
            })
        .toList();
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
    final file = await sftp.open(remotePath,
        mode: SftpFileOpenMode.write |
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate);
    try {
      var offset = 0;
      await for (final chunk in localFile.openRead()) {
        final bytes = Uint8List.fromList(chunk);
        await file.writeBytes(bytes, offset: offset);
        offset += bytes.length;
      }
    } finally {
      await file.close();
    }
  }

  Future<List<String>> listDrives() async {
    final sftp = await client.sftp();
    final drives = <String>[];
    for (final letter in [
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ]) {
      try {
        final path = '$letter:/';
        await sftp.listdir(path);
        drives.add(letter);
      } catch (_) {}
    }
    return drives;
  }
}
