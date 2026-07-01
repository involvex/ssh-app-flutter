import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'package:xterm/ui.dart';
import '../providers/settings_provider.dart';
import '../providers/ssh_provider.dart';
import '../widgets/ssh_server_form.dart';
import '../widgets/log_viewer.dart';
import '../widgets/profile_manager.dart';
import '../widgets/key_manager.dart';
import '../widgets/keyboard_shortcut_bar.dart';
import '../widgets/connection_modal.dart';
import '../widgets/network_discovery.dart';
import '../widgets/ctrl_button_panel.dart';
import '../widgets/snippet_button_panel.dart';
import '../widgets/sftp_browser.dart';
import '../screens/settings_screen.dart';
import '../screens/snippet_config_screen.dart';
import '../screens/agents_tab.dart';
import '../services/widget_launch_handler.dart';
import '../utils/terminal_style_builder.dart';

enum AppTab { client, server, agents, logs }

enum _HomeOverflowAction { snippets, discovery, keys, profiles }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.pendingLaunch});

  final WidgetLaunchAction? pendingLaunch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab _selectedTab = AppTab.client;
  bool _isFullScreen = false;
  bool _agentsChatOpen = false;
  StreamSubscription<Uri?>? _widgetClickSub;
  final FocusNode _keyboardFocusNode = FocusNode();
  final GlobalKey<AgentsTabState> _agentsTabKey = GlobalKey<AgentsTabState>();

  @override
  void initState() {
    super.initState();
    _loadConfig();
    if (!kIsWeb && Platform.isAndroid) {
      _widgetClickSub = HomeWidget.widgetClicked.listen(_onWidgetClicked);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    unawaited(_widgetClickSub?.cancel());
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final ssh = Provider.of<SSHProvider>(context, listen: false);
    await ssh.loadConfig();
    if (!mounted) {
      return;
    }
    final pending = widget.pendingLaunch;
    if (pending != null) {
      await WidgetLaunchHandler.execute(
        context,
        pending,
        onTabSelected: _selectTab,
      );
    }
  }

  void _selectTab(AppTab tab) {
    if (!mounted) {
      return;
    }
    setState(() => _selectedTab = tab);
  }

  void _onWidgetClicked(Uri? uri) {
    final action = WidgetLaunchHandler.parseUri(uri);
    if (action == null || !mounted) {
      return;
    }
    // ignore: unawaited_futures
    WidgetLaunchHandler.execute(
      context,
      action,
      onTabSelected: _selectTab,
    );
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

  void _showConnectionModal() async {
    final ssh = Provider.of<SSHProvider>(context, listen: false);

    // If we have a last session saved, try quick-connect using it.
    if (ssh.lastSession != null) {
      final session = ssh.lastSession!;

      // Show a small progress dialog while connecting
      // ignore: unawaited_futures
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Color(0xFF16213E),
          content: Row(
            children: [
              SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator()),
              SizedBox(width: 16),
              Text('Connecting...'),
            ],
          ),
        ),
      );

      try {
        if (session.isServer) {
          await ssh.startServer(
            port: session.port,
            username: session.username,
            password: session.password ?? '',
            sshKeyType: null,
          );
        } else {
          await ssh.connectClient(
            host: session.host,
            port: session.port,
            username: session.username,
            password: session.password ?? '',
            startupCommand: session.startupCommand,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) Navigator.of(context).pop();
      }

      return;
    }

    // No last session — show the connection modal so the user can enter details.
    // ignore: unawaited_futures
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

  void _showSnippetConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SnippetConfigScreen()),
    );
  }

  void _handleOverflowAction(_HomeOverflowAction action) {
    switch (action) {
      case _HomeOverflowAction.snippets:
        _showSnippetConfig();
      case _HomeOverflowAction.discovery:
        _showNetworkDiscovery();
      case _HomeOverflowAction.keys:
        _showKeyManager();
      case _HomeOverflowAction.profiles:
        _showProfileManager();
    }
  }

  List<AppTab> _visibleTabs(SettingsProvider settings) {
    return <AppTab>[
      AppTab.client,
      if (settings.showServerTab) AppTab.server,
      AppTab.agents,
      AppTab.logs,
    ];
  }

  void _ensureValidTab(SettingsProvider settings) {
    final tabs = _visibleTabs(settings);
    if (!tabs.contains(_selectedTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedTab = AppTab.client);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SSHProvider, SettingsProvider>(
      builder: (context, ssh, settings, child) {
        _ensureValidTab(settings);
        final tabs = _visibleTabs(settings);
        final navIndex = tabs.indexOf(_selectedTab).clamp(0, tabs.length - 1);

        // Automatically exit full screen if no sessions are connected
        if (_isFullScreen && !ssh.sessions.any((s) => s.isConnected)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isFullScreen = false);
          });
        }

        final shouldDelegateAgentsBack =
            _selectedTab == AppTab.agents && _agentsChatOpen;

        return PopScope(
          canPop: !shouldDelegateAgentsBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && shouldDelegateAgentsBack) {
              _agentsTabKey.currentState?.handleBack();
            }
          },
          child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                Consumer<SSHProvider>(
                  builder: (context, ssh, child) {
                    if (ssh.sessions.any((s) => s.isConnected) &&
                        _selectedTab == AppTab.client) {
                      return IconButton(
                        icon: Icon(_isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen),
                        tooltip:
                            _isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                        onPressed: () =>
                            setState(() => _isFullScreen = !_isFullScreen),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Connect',
                  onPressed: _showConnectionModal,
                ),
                PopupMenuButton<_HomeOverflowAction>(
                  tooltip: 'More',
                  onSelected: _handleOverflowAction,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_HomeOverflowAction>>[
                    const PopupMenuItem<_HomeOverflowAction>(
                      value: _HomeOverflowAction.snippets,
                      child: ListTile(
                        leading: Icon(Icons.code),
                        title: Text('Snippets'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const PopupMenuItem<_HomeOverflowAction>(
                      value: _HomeOverflowAction.discovery,
                      child: ListTile(
                        leading: Icon(Icons.search),
                        title: Text('Network Discovery'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const PopupMenuItem<_HomeOverflowAction>(
                      value: _HomeOverflowAction.keys,
                      child: ListTile(
                        leading: Icon(Icons.key),
                        title: Text('Keys'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const PopupMenuItem<_HomeOverflowAction>(
                      value: _HomeOverflowAction.profiles,
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profiles'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            bottomNavigationBar: _isFullScreen
                ? null
                : NavigationBar(
                    selectedIndex: navIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedTab = tabs[index];
                      });
                    },
                    destinations: tabs.map((tab) {
                      return switch (tab) {
                        AppTab.client => const NavigationDestination(
                            icon: Icon(Icons.computer),
                            label: 'Client',
                          ),
                        AppTab.server => const NavigationDestination(
                            icon: Icon(Icons.dns),
                            label: 'Server',
                          ),
                        AppTab.agents => const NavigationDestination(
                            icon: Icon(Icons.smart_toy),
                            label: 'Agents',
                          ),
                        AppTab.logs => const NavigationDestination(
                            icon: Icon(Icons.article),
                            label: 'Logs',
                          ),
                      };
                    }).toList(),
                  ),
            body: Column(
              children: [
                if (!_isFullScreen) const KeyboardShortcutBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab.index,
                    children: <Widget>[
                      ClientTab(isFullScreen: _isFullScreen),
                      const ServerTab(),
                      AgentsTab(
                        key: _agentsTabKey,
                        onChatOpenChanged: (open) {
                          if (_agentsChatOpen != open) {
                            setState(() => _agentsChatOpen = open);
                          }
                        },
                      ),
                      const LogViewer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

class ClientTab extends StatelessWidget {
  final bool isFullScreen;
  const ClientTab({required this.isFullScreen, super.key});

  Widget _buildSessionTabBar(BuildContext context) {
    return Consumer<SSHProvider>(builder: (context, ssh, child) {
      final sessions = ssh.sessions;
      final chips = sessions.map((s) {
        final isActive = ssh.activeSessionId == s.id;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: InputChip(
            selected: isActive,
            avatar: CircleAvatar(
              radius: 4,
              backgroundColor: s.isConnected ? Colors.green : Colors.red,
            ),
            label: Text('${s.name} (${s.profile.host}:${s.profile.port})'),
            onPressed: () => ssh.switchActiveSession(s.id),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => ssh.removeSession(s.id),
          ),
        );
      }).toList();

      chips.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GestureDetector(
            onTap: () => showDialog<void>(
                context: context, builder: (c) => const ConnectionModal()),
            child: const Chip(label: Icon(Icons.add)),
          ),
        ),
      );

      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'SFTP Browser',
            onPressed: () {
              if (ssh.activeSession == null ||
                  !ssh.activeSession!.isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Connect to a session first')));
                return;
              }
              showModalBottomSheet(
                  context: context,
                  builder: (_) => SftpBrowser(sessionId: ssh.activeSessionId!));
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SSHProvider, SettingsProvider>(
      builder: (context, ssh, settings, child) {
        final isHacker = settings.appTheme == AppTheme.hacker;

        final terminalTheme = isHacker
            ? const TerminalTheme(
                cursor: Color(0XFFAEAFAD),
                selection: Color(0XFFAEAFAD),
                foreground: Colors.greenAccent,
                background: Color(0XFF000000),
                black: Color(0XFF000000),
                red: Color(0XFFCD3131),
                green: Color(0XFF0DBC79),
                yellow: Color(0XFFE5E510),
                blue: Color(0XFF2472C8),
                magenta: Color(0XFFBC3FBC),
                cyan: Color(0XFF11A8CD),
                white: Color(0XFFE5E5E5),
                brightBlack: Color(0XFF666666),
                brightRed: Color(0XFFF14C4C),
                brightGreen: Color(0XFF23D18B),
                brightYellow: Color(0XFFF5F543),
                brightBlue: Color(0XFF3B8EEA),
                brightMagenta: Color(0XFFD670D6),
                brightCyan: Color(0XFF29B8DB),
                brightWhite: Color(0XFFFFFFFF),
                searchHitBackground: Color(0XFFFFFF2B),
                searchHitBackgroundCurrent: Color(0XFF31FF26),
                searchHitForeground: Color(0XFF000000),
              )
            : TerminalThemes.defaultTheme;

        return Column(
          children: <Widget>[
            if (!isFullScreen) _buildSessionTabBar(context),
            Expanded(
              child: Consumer<SSHProvider>(builder: (context, ssh, child) {
                final active = ssh.activeSession;
                if (active == null) {
                  return const Center(
                      child: Text('No session. Click + to connect'));
                }
                if (!active.isConnected) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Not connected'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                try {
                                  await ssh.connectSession(active.id);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Reconnect failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reconnect'),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () => ssh.removeSession(active.id),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  color: terminalTheme.background,
                  child: TerminalView(
                    active.terminal,
                    padding: const EdgeInsets.all(8),
                    theme: terminalTheme,
                    textStyle:
                        TerminalStyleBuilder.buildTerminalStyle(settings),
                    autoResize: true,
                  ),
                );
              }),
            ),
            if (ssh.sessions.any((s) => s.isConnected))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CtrlButtonPanel(),
                    SnippetButtonPanel(),
                  ],
                ),
              ),
            if (ssh.sessions.any((s) => s.isConnected) && !isFullScreen)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final active =
                        Provider.of<SSHProvider>(context, listen: false)
                            .activeSession;
                    if (active != null) {
                      await Provider.of<SSHProvider>(context, listen: false)
                          .disconnectSession(active.id);
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
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
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'SSH Server is Running',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Address: ${ssh.serverAddress ?? '0.0.0.0'}:${ssh.serverPort}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () => ssh.stopServer(),
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Server'),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
