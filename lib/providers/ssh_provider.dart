import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'package:network_info_plus/network_info_plus.dart';


class SSHProvider extends ChangeNotifier {
  SSHClient? _client;
  SSHServer? _server;
  SSHSession? _session;
  Terminal terminal = Terminal();
  bool isClientConnected = false;
  bool isServerRunning = false;
  int serverPort = 2222;
  String? serverAddress;
  List<String> connectionLog = [];

  Future<void> connectClient({
    required String host,
    required int port,
    required String username,
    required String password,
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

      _session!.done.then((_) {
        addLog('Connection closed');
        isClientConnected = false;
        notifyListeners();
      });

      isClientConnected = true;
      addLog('Connected successfully');
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
    required dynamic SSHKeyType,
  }) async {
    try {
      serverPort = port;
      
      _server = SSHServer(
        hostKeys: [],
        onAuth: (user, method) async {
          if (user == username && method is SSHPasswordAuth && method.password == password) {
            return true;
          }
          return false;
        },
        onShell: (session, pty) async {
          addLog('New connection received');
          final process = await Process.start(
            Platform.isWindows ? 'cmd.exe' : 'sh',
            [],
            mode: ProcessStartMode.normal,
          );

          process.stdout.listen((data) => session.stdout.add(data));
          process.stderr.listen((data) => session.stderr.add(data));
          session.stdin.listen((data) => process.stdin.add(data));

          await process.exitCode.then((code) => session.close());
          await session.done;
        },
      );

      await _server!.bind('0.0.0.0', port);
      isServerRunning = true;
      
      final info = NetworkInfo();
      serverAddress = await info.getWifiIP();
      
      addLog('SSH Server running on ${serverAddress ?? '0.0.0.0'}:$port');
      notifyListeners();
    } catch (e) {
      addLog('Failed to start server: $e');
      rethrow;
    }
  }

  void stopServer() {
    _server?.close();
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
    _server?.close();
    super.dispose();
  }
}

mixin SSHPasswordAuth {
  String get password;
}

class SSHServer {
  final List<dynamic> hostKeys;
  final Future<bool> Function(String user, dynamic method)? onAuth;
  final Future<void> Function(dynamic session, dynamic pty)? onShell;
  bool _isClosed = false;

  SSHServer({
    this.hostKeys = const [],
    this.onAuth,
    this.onShell,
  });

  void close() {
    _isClosed = true;
  }

  bool get isClosed => _isClosed;

  Future<void> bind(String host, int port) async {}
}