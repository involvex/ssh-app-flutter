import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/agent_provider.dart';
import '../providers/ssh_provider.dart';
import 'connection_foreground_service.dart';

/// Observes app lifecycle and reconnects SSH/agent sessions on resume.
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService(this._context);

  final BuildContext _context;
  DateTime? _backgroundedAt;

  static bool isInBackground = false;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        isInBackground = true;
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        isInBackground = false;
        final backgrounded = _backgroundedAt;
        _backgroundedAt = null;
        // ignore: unawaited_futures
        _onResumed(backgrounded);
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onResumed(DateTime? backgroundedAt) async {
    if (!_context.mounted) return;

    final ssh = Provider.of<SSHProvider>(_context, listen: false);
    final agents = Provider.of<AgentProvider>(_context, listen: false);

    if (backgroundedAt != null) {
      final seconds = DateTime.now().difference(backgroundedAt).inSeconds;
      ssh.addLog('App resumed after ${seconds}s in background');
    }

    await _reconnectSshSessions(ssh);
    await agents.reconnectDisconnectedAgents();
    await syncForegroundService(ssh, agents);
  }

  Future<void> _reconnectSshSessions(SSHProvider ssh) async {
    for (final session in ssh.sessions) {
      if (session.isConnected) continue;
      if (!session.disconnectedWhileBackgrounded &&
          !session.shouldReconnectOnResume) {
        continue;
      }

      try {
        ssh.addLog('Reconnecting SSH session ${session.name}...');
        await ssh.reconnectSession(session.id);
        session.disconnectedWhileBackgrounded = false;
      } catch (e) {
        ssh.addLog('SSH reconnect failed for ${session.name}: $e');
      }
    }
  }

  static Future<void> syncForegroundService(
    SSHProvider ssh,
    AgentProvider agents,
  ) async {
    final sshCount = ssh.sessions.where((s) => s.isConnected).length;
    final agentCount =
        agents.connections.where((c) => c.isConnected).length;
    await ConnectionForegroundService.syncActiveConnections(
      sshCount + agentCount,
    );
  }
}

/// Host widget that wires [AppLifecycleService] above [MaterialApp].
class AppLifecycleHost extends StatefulWidget {
  const AppLifecycleHost({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleHost> createState() => _AppLifecycleHostState();
}

class _AppLifecycleHostState extends State<AppLifecycleHost> {
  AppLifecycleService? _lifecycle;
  SSHProvider? _ssh;
  AgentProvider? _agents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycle ??= AppLifecycleService(context)..attach();

    final ssh = Provider.of<SSHProvider>(context, listen: false);
    final agents = Provider.of<AgentProvider>(context, listen: false);
    if (!identical(_ssh, ssh)) {
      _ssh?.removeListener(_syncForeground);
      _ssh = ssh..addListener(_syncForeground);
    }
    if (!identical(_agents, agents)) {
      _agents?.removeListener(_syncForeground);
      _agents = agents..addListener(_syncForeground);
    }
    // ignore: unawaited_futures
    _syncForeground();
  }

  void _syncForeground() {
    final ssh = _ssh;
    final agents = _agents;
    if (ssh == null || agents == null) return;
    // ignore: unawaited_futures
    AppLifecycleService.syncForegroundService(ssh, agents);
  }

  @override
  void dispose() {
    _ssh?.removeListener(_syncForeground);
    _agents?.removeListener(_syncForeground);
    _lifecycle?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
