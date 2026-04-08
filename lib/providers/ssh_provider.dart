import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/ssh_profile.dart';
import '../services/config_service.dart';
import '../services/network_discovery_service.dart';

class SSHProvider extends ChangeNotifier {
  SSHClient? _client;
  SSHSession? _session;
  Terminal terminal = Terminal();
  bool isClientConnected = false;
  bool isServerRunning = false;
  int serverPort = 22;
  String? serverAddress;
  List<String> connectionLog = [];

  List<SSHProfile> profiles = <SSHProfile>[];
  SSHProfile? lastSession;
  List<String> discoveredHosts = <String>[];
  bool isScanning = false;

  Future<void> loadConfig() async {
    final profileData = await ConfigService.getProfiles();
    profiles = profileData.map((e) => SSHProfile.fromJson(e)).toList();

    final sessionData = await ConfigService.getLastSession();
    if (sessionData != null) {
      lastSession = SSHProfile.fromJson(sessionData);
    }

    notifyListeners();
  }

  Future<void> saveProfile(SSHProfile profile) async {
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    await ConfigService.saveProfiles(profiles.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    profiles.removeWhere((p) => p.id == id);
    await ConfigService.saveProfiles(profiles.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> saveLastSession(SSHProfile profile) async {
    lastSession = profile;
    await ConfigService.saveLastSession(profile.toJson());
    notifyListeners();
  }

  Future<void> scanNetwork() async {
    isScanning = true;
    discoveredHosts = <String>[];
    notifyListeners();

    discoveredHosts = await NetworkDiscoveryService.scanNetwork();

    isScanning = false;
    notifyListeners();
  }

  Future<void> discoverHost(String host) async {
    final isOpen = await NetworkDiscoveryService.checkPortOpen(host, 22);
    if (isOpen && !discoveredHosts.contains(host)) {
      discoveredHosts.add(host);
      notifyListeners();
    }
  }

  Future<void> connectClient({
    required String host,
    required int port,
    required String username,
    required String password,
    String? startupCommand,
  }) async {
    try {
      addLog('Connecting to $host:$port...');

      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      _session = await _client!.shell(
        pty: const SSHPtyConfig(
          width: 80,
          height: 24,
        ),
      );

      _session!.stdout.listen((data) {
        terminal.write(utf8.decode(data));
      });

      _session!.stderr.listen((data) {
        terminal.write(utf8.decode(data));
      });

      terminal.onOutput = (data) {
        _session!.stdin.add(utf8.encode(data));
      };

      unawaited(_session!.done.then((_) async {
        addLog('Connection closed');
        isClientConnected = false;
        notifyListeners();
      }));

      isClientConnected = true;
      addLog('Connected successfully');

      if (startupCommand != null && startupCommand.isNotEmpty) {
        // Prefer running the command as a single non-interactive PowerShell
        // invocation so it doesn't rely on profile/login shell behavior and
        // avoids "press Enter" issues. Use the full git.exe path as a
        // fallback when PATH is unreliable on remote SSH sessions.
        final escaped = startupCommand.replaceAll("'", "''");
        const gitFullPath = r'C:\Program Files\Git\cmd\git.exe';

        // Detect simple git commands and wrap them in a PowerShell -NoProfile
        // invocation using the full git path. Otherwise fall back to the
        // existing behaviour of writing into the shell.
        final trimmed = startupCommand.trim();
        final isGit = trimmed.toLowerCase().startsWith('git ');

        if (isGit) {
          final psCmd = "powershell -NoProfile -Command \"& '$gitFullPath' $escaped\"";
          try {
            _session!.stdin.add(utf8.encode('$psCmd\r'));
            addLog('Executed startup command via PowerShell wrapper: $psCmd');
          } catch (e) {
            _session!.stdin.add(utf8.encode('$startupCommand\r'));
            addLog('Fallback: Executed startup command raw: $startupCommand');
          }
        } else {
          // non-git commands: send to shell (retain previous behaviour)
          _session!.stdin.add(utf8.encode('$startupCommand\r'));
          addLog('Executed startup command: $startupCommand');
        }
      }

      notifyListeners();
    } catch (e) {
      addLog('Connection failed: $e');
      rethrow;
    }
  }

  Future<void> startServer({
    required int port,
    required String username,
    required String password,
    dynamic sshKeyType,
  }) async {
    try {
      serverPort = port;
      isServerRunning = true;

      final info = NetworkInfo();
      serverAddress = await info.getWifiIP();

      addLog('SSH Server running on ${serverAddress ?? '0.0.0.0'}:$port');
      notifyListeners();
    } catch (e) {
      addLog('Failed to start server: $e');
      isServerRunning = false;
      rethrow;
    }
  }

  void stopServer() {
    isServerRunning = false;
    addLog('Server stopped');
    notifyListeners();
  }

  void disconnectClient() {
    _session?.close();
    _client?.close();
    isClientConnected = false;
    terminal = Terminal();
    addLog('Disconnected');
    notifyListeners();
  }

  void sendControlCharacter(int charCode) {
    if (_session != null && isClientConnected) {
      _session!.stdin.add(Uint8List.fromList([charCode]));
      addLog('Sent Ctrl+$_getCtrlLabel(charCode)');
    }
  }

  void sendString(String data) {
    if (_session != null && isClientConnected) {
      _session!.stdin.add(utf8.encode(data));
    }
  }

  String _getCtrlLabel(int charCode) {
    switch (charCode) {
      case 3:
        return 'C';
      case 4:
        return 'D';
      case 26:
        return 'Z';
      case 12:
        return 'L';
      case 1:
        return 'A';
      case 16:
        return 'P';
      default:
        return String.fromCharCode(charCode);
    }
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    connectionLog.add('[$timestamp] $message');
    if (connectionLog.length > 100) {
      connectionLog.removeAt(0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _session?.close();
    _client?.close();
    super.dispose();
  }
}
