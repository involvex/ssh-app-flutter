import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:opencode_api/opencode_api.dart';

class OpenCodeConnectionService {
  OpenCodeConnectionService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String baseUrl;
  final String username;
  final String password;

  late final Opencode _client;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _disposed = false;

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Opencode get client => _client;

  Future<void> connect() async {
    _client = await Opencode.connect(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
    await checkHealth();
    // ignore: unawaited_futures
    _listenToEvents();
  }

  Future<HealthResponse> checkHealth() async {
    return _client.global.getHealth();
  }

  Future<List<Session>> getSessions() => _client.session.getSessions();

  Future<Session> createSession({String? title}) {
    return _client.session.createSession(
      title != null ? {'title': title} : <String, dynamic>{},
    );
  }

  Future<void> deleteSession(String id) => _client.session.deleteSession(id);

  Future<List<MessageWithParts>> getMessages(String sessionId) {
    return _client.session.getMessages(sessionId);
  }

  Future<void> sendMessageAsync(String sessionId, String text) {
    return _client.session.sendMessageAsyncRaw(
      sessionId,
      <String, dynamic>{
        'parts': <Map<String, String>>[
          {'type': 'text', 'text': text},
        ],
      },
    );
  }

  Future<bool> respondToPermission(
    String sessionId,
    String permissionId, {
    required String response,
    bool remember = false,
  }) {
    return _client.session.respondToPermissionRequest(
      sessionId,
      permissionId,
      <String, dynamic>{
        'response': response,
        'remember': remember,
      },
    );
  }

  Future<void> _listenToEvents() async {
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: <String, dynamic>{
            if (password.isNotEmpty)
              'authorization':
                  'Basic ${base64Encode(utf8.encode('$username:$password'))}',
          },
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
        ),
      ).get<ResponseBody>('/event');

      final stream = response.data?.stream;
      if (stream == null || _disposed) return;

      final buffer = StringBuffer();
      await for (final chunk in stream) {
        if (_disposed) break;
        buffer.write(utf8.decode(chunk));
        final content = buffer.toString();
        final lines = content.split('\n');
        buffer.clear();
        if (!content.endsWith('\n') && lines.isNotEmpty) {
          buffer.write(lines.removeLast());
        }
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty) continue;
            try {
              final event = json.decode(data) as Map<String, dynamic>;
              if (!_eventController.isClosed) {
                _eventController.add(event);
              }
            } catch (_) {
              // Skip malformed SSE payloads
            }
          }
        }
      }
    } catch (_) {
      // Stream ended or failed
    }
  }

  void dispose() {
    _disposed = true;
    _eventController.close();
  }
}
