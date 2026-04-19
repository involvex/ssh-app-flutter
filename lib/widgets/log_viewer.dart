import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';

class LogViewer extends StatelessWidget {
  const LogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, ssh, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Connection Logs',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => ssh.connectionLog.clear(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(8.0),
                itemCount: ssh.connectionLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      ssh.connectionLog.reversed.toList()[index],
                      style: const TextStyle(
                          fontFamily: 'Courier New', fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
