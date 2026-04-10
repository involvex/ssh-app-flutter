// lib/services/sftp_helper.dart
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SftpHelper {
  final SSHClient client;
  SftpHelper(this.client);

  Future<List<SftpName>> listDir(String path) async {
    final sftp = await client.sftp();
    final names = await sftp.listdir(path);
    return names; // List<SftpName>
  }

  Future<void> download(String remotePath, File localFile) async {
    final sftp = await client.sftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    // Use readBytes to get full content (the API provides streaming read as well)
    final bytes = await file.readBytes();
    await file.close();
    await localFile.writeAsBytes(bytes);
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
