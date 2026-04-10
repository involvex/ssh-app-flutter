// lib/widgets/sftp_browser.dart
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ssh_provider.dart';
import '../services/sftp_helper.dart';

class SftpBrowser extends StatefulWidget {
  final String sessionId;
  const SftpBrowser({required this.sessionId, super.key});

  @override
  State<SftpBrowser> createState() => _SftpBrowserState();
}

class _SftpBrowserState extends State<SftpBrowser> {
  String currentPath = '.';
  List<Map<String, dynamic>> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() => loading = true);

    final provider = Provider.of<SSHProvider>(context, listen: false);
    final matches = provider.sessions.where((s) => s.id == widget.sessionId);
    if (matches.isEmpty) {
      setState(() => loading = false);
      return;
    }
    final active = matches.first;
    final client = active.client;
    if (client == null) {
      setState(() => loading = false);
      return;
    }

    final helper = SftpHelper(client);
    final out = await helper.listDirWithType(currentPath);

    if (currentPath != '.' && currentPath != '/') {
      out.insert(0, <String, dynamic>{'name': '..', 'isDirectory': true});
    }

    if (!mounted) return;
    setState(() {
      entries = out;
      loading = false;
    });
  }

  Future<void> _download(String remoteFile) async {
    // capture context-dependent values before any awaits to avoid use_build_context_synchronously
    final provider = Provider.of<SSHProvider>(context, listen: false);
    final active = provider.sessions.firstWhere((s) => s.id == widget.sessionId);
    final client = active.client!;
    final helper = SftpHelper(client);

    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked == null) return;

    final local = File('$picked/$remoteFile');
    final remote = (currentPath == '.' || currentPath == '/') ? remoteFile : '$currentPath/$remoteFile';
    await helper.downloadStream(remote, local);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded')));
  }

  Future<void> _upload() async {
    // Capture all context-dependent values before the first await
    final provider = Provider.of<SSHProvider>(context, listen: false);
    final active = provider.sessions.firstWhere((s) => s.id == widget.sessionId);
    final helper = SftpHelper(active.client!);
    final messenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final path = result.files.single.path!;
    final file = File(path);
    final remotePath = (currentPath == '.' || currentPath == '/') ? result.files.single.name : '$currentPath/${result.files.single.name}';
    await helper.upload(file, remotePath);
    if (!mounted) return;
    await _refresh();
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Uploaded')));
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
                      final name = item['name'] as String;
                      final isDir = item['isDirectory'] as bool? ?? false;

                      return ListTile(
                        leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                        title: Text(name),
                        onTap: () async {
                          if (name == '..') {
                            final lastSlash = currentPath.lastIndexOf('/');
                            if (lastSlash <= 0) {
                              setState(() => currentPath = lastSlash == 0 ? '/' : '.');
                            } else {
                              setState(() => currentPath = currentPath.substring(0, lastSlash));
                            }
                            await _refresh();
                            return;
                          }
                          if (isDir) {
                            setState(() => currentPath = (currentPath == '.' || currentPath == '/') ? name : '$currentPath/$name');
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
