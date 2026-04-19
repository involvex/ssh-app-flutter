import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkDiscoveryService {
  static final NetworkInfo _networkInfo = NetworkInfo();

  static Future<String?> getLocalIP() async {
    return _networkInfo.getWifiIP();
  }

  static Future<String?> getWifiName() async {
    return _networkInfo.getWifiName();
  }

  static Future<List<String>> scanNetwork({
    int timeoutMs = 500,
    int maxConcurrent = 50,
  }) async {
    final String? localIP = await getLocalIP();
    if (localIP == null) return <String>[];

    final parts = localIP.split('.');
    if (parts.length != 4) return <String>[];

    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    final futures = <Future<String?>>[];

    for (var i = 1; i < 255; i++) {
      final host = '$subnet.$i';
      futures.add(_checkPort(host, 22, timeoutMs));

      if (futures.length >= maxConcurrent) {
        final results = await Future.wait(futures);
        futures.clear();
        for (final result in results) {
          if (result != null) {
            return <String>[result];
          }
        }
      }
    }

    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  static Future<String?> _checkPort(
      String host, int port, int timeoutMs) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      await socket.close();
      return host;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> checkPortOpen(String host, int port,
      {int timeoutMs = 2000}) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
