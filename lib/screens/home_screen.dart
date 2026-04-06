import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'package:xterm/ui.dart';
import '../providers/ssh_provider.dart';
import '../widgets/ssh_client_form.dart';
import '../widgets/ssh_server_form.dart';
import '../widgets/log_viewer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter SSH'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.computer),
                label: 'SSH Client',
              ),
              NavigationDestination(
                icon: Icon(Icons.dns),
                label: 'SSH Server',
              ),
              NavigationDestination(
                icon: Icon(Icons.article),
                label: 'Logs',
              ),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                ClientTab(),
                ServerTab(),
                LogViewer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClientTab extends StatelessWidget {
  const ClientTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, ssh, child) {
        return Column(
          children: [
            if (!ssh.isClientConnected)
              const Expanded(child: SSHClientForm())
            else
              Expanded(
                child: TerminalView(
                  ssh.terminal,
                  padding: const EdgeInsets.all(8),
                  textStyle: const TerminalStyle(
                    fontSize: 12,
                    fontFamily: 'Courier New',
                  ),
                ),
              ),
            if (ssh.isClientConnected)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => ssh.disconnectClient(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Disconnect'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ServerTab extends StatelessWidget {
  const ServerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, ssh, child) {
        return Column(
          children: [
            if (!ssh.isServerRunning)
              const Expanded(child: SSHServerForm())
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text('SSH Server is Running', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Address: ${ssh.serverAddress ?? '0.0.0.0'}:${ssh.serverPort}'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ssh.stopServer(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Stop Server'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}