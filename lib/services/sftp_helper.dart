// lib/services/sftp_helper.dart
import 'dart:io';
import 'dart:typed_data';
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
    final sftp = await client.sftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    // Stream the remote file in chunks and write to the local file to avoid OOM on large files.
    final sink = localFile.openWrite();
    try {
      // The SftpFile exposes a Stream<Uint8List> via read(), so iterate over it
      final stream = file.read();
      await for (final chunk in stream) {
        if (chunk.isEmpty) break;
        sink.add(chunk);
      }
    } finally {
      await file.close();
      await sink.close();
    }
  }

  Future<void> upload(File localFile, String remotePath) async {
    final sftp = await client.sftp();
    final data = await localFile.readAsBytes();
    // open for write (create/truncate)
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.write | SftpFileOpenMode.create | SftpFileOpenMode.truncate);
    await file.writeBytes(Uint8List.fromList(data));
    await file.close();
  }
}
