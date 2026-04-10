// lib/services/sftp_helper.dart
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SftpHelper {
  final SSHClient client;
  SftpHelper(this.client);

  Future<List<SftpName>> listDir(String path) async {
    final sftp = await client.sftp();
    final names = await sftp.listdir(path);
    return names;
  }

  Future<void> download(String remotePath, File localFile) async {
    final sftp = await client.sftp();
    final remoteStream = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    final sink = localFile.openWrite();
    await remoteStream.pipe(sink);
    await sink.flush();
    await sink.close();
    await remoteStream.close();
  }

  Future<void> upload(File localFile, String remotePath) async {
    final sftp = await client.sftp();
    final remoteFile = await sftp.open(remotePath, mode: SftpFileOpenMode.write | SftpFileOpenMode.create);
    await localFile.openRead().pipe(remoteFile);
    await remoteFile.close();
  }
}
