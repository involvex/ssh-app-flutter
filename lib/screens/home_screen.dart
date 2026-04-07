import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'package:xterm/ui.dart';
import '../providers/ssh_provider.dart';
import '../widgets/ssh_client_form.dart';
import '../widgets/ssh_server_form.dart';
import '../widgets/log_viewer.dart';
import '../widgets/profile_manager.dart';
import '../widgets/key_manager.dart';
import '../widgets/keyboard_shortcut_bar.dart';
import '../widgets/connection_modal.dart';
import '../widgets/network_discovery.dart';
import '../widgets/ctrl_button_panel.dart';
import '../widgets/snippet_button_panel.dart';
import '../widgets/snippet_manager.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final ssh = Provider.of<SSHProvider>(context, listen: false);
    await ssh.loadConfig();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final ctrl = HardwareKeyboard.instance.isControlPressed;

      if (ctrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        _showConnectionModal();
      } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyP) {
        _showProfileManager();
      } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyD) {
        _showNetworkDiscovery();
      } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyK) {
        _showKeyManager();
      }
    }
  }

  void _showConnectionModal() {
    showDialog<void>(
      context: context,
      builder: (context) => const ConnectionModal(),
    );
  }

  void _showProfileManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ProfileManager(),
    );
  }

  void _showNetworkDiscovery() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const NetworkDiscoverySheet(),
    );
  }

  void _showKeyManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const KeyManager(),
    );
  }

  void _showSnippetManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SnippetManager(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SSH App'),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: 'Snippets',
              onPressed: _showSnippetManager,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Network Discovery (Ctrl+D)',
              onPressed: _showNetworkDiscovery,
            ),
            IconButton(
              icon: const Icon(Icons.key),
              tooltip: 'Key Manager (Ctrl+K)',
              onPressed: _showKeyManager,
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profiles (Ctrl+P)',
              onPressed: _showProfileManager,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Connection (Ctrl+N)',
              onPressed: _showConnectionModal,
            ),
          ],
        ),
        body: Column(
          children: [
            const KeyboardShortcutBar(),
            NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.computer),
                  label: 'Client',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dns),
                  label: 'Server',
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
                children: const <Widget>[
                  ClientTab(),
                  ServerTab(),
                  LogViewer(),
                ],
              ),
            ),
          ],
        ),
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
          children: <Widget>[
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
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CtrlButtonPanel(),
                    SizedBox(width: 16),
                    SnippetButtonPanel(),
                  ],
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
          children: <Widget>[
            if (!ssh.isServerRunning)
              const Expanded(child: SSHServerForm())
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
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
