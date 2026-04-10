// lib/widgets/sftp_browser.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';
import '../services/sftp_helper.dart';
import 'package:file_picker/file_picker.dart';

class SftpBrowser extends StatefulWidget {
  final String sessionId;
  const SftpBrowser({required this.sessionId, super.key});

  @override
  State<SftpBrowser> createState() => _SftpBrowserState();
}

class _SftpBrowserState extends State<SftpBrowser> {
  String currentPath = '.';
  List<SftpName> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    final provider = Provider.of<SSHProvider>(context, listen: false);
    final active = provider.sessions.firstWhere((s) => s.id == widget.sessionId);
    final client = active.client!;
    final helper = SftpHelper(client);
    final list = await helper.listDir(currentPath);
    setState(() {
      entries = list;
      loading = false;
    });
  }

  Future<void> _download(String remoteFile) async {
    final provider = Provider.of<SSHProvider>(context, listen: false);
    final active = provider.sessions.firstWhere((s) => s.id == widget.sessionId);
    final client = active.client!;
    final helper = SftpHelper(client);

    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked == null) return;
    final local = File('${picked}/$remoteFile');
    await helper.download('$currentPath/$remoteFile', local);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded')));
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final path = result.files.single.path!;
    final file = File(path);
    final provider = Provider.of<SSHProvider>(context, listen: false);
    final active = provider.sessions.firstWhere((s) => s.id == widget.sessionId);
    final helper = SftpHelper(active.client!);
    final remotePath = '$currentPath/${result.files.single.name}';
    await helper.upload(file, remotePath);
    await _refresh();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          ListTile(
            title: Text('SFTP — $currentPath'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: _upload, icon: const Icon(Icons.upload_file)),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ]),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, idx) {
                      final item = entries[idx];
                      final name = item.filename;
                      final isDir = item.attrs != null && item.attrs.isDirectory;
                      return ListTile(
                        leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                        title: Text(name),
                        onTap: () async {
                          if (isDir) {
                            setState(() => currentPath = '$currentPath/$name');
                            await _refresh();
                          }
                        },
                        trailing: isDir ? null : IconButton(icon: const Icon(Icons.download), onPressed: () => _download(name)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
