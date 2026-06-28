import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/ai_provider.dart';

class AiGatewayException implements Exception {
  AiGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiGatewayService {
  static const String opencodeZenBaseUrl = 'https://opencode.ai/zen/v1';
  static const String kiloGatewayBaseUrl = 'https://api.kilo.ai/api/gateway';

  static const String defaultOpencodeModel = AiProviderDefaults.opencodeZenModel;
  static const String defaultKiloModel = AiProviderDefaults.kiloModel;

  static String baseUrlFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.opencodeZen => opencodeZenBaseUrl,
      AiProvider.kiloGateway => kiloGatewayBaseUrl,
    };
  }

  static String defaultModelFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.opencodeZen => defaultOpencodeModel,
      AiProvider.kiloGateway => defaultKiloModel,
    };
  }

  static Future<List<String>> fetchModels({
    required AiProvider provider,
    required String apiKey,
  }) async {
    final dio = _createDio(provider: provider, apiKey: apiKey);
    try {
      final response = await dio.get<Map<String, dynamic>>('/models');
      final data = response.data?['data'];
      if (data is! List) {
        throw AiGatewayException('Unexpected models response format');
      }
      final models = data
          .map((entry) {
            if (entry is Map<String, dynamic>) {
              return entry['id'] as String?;
            }
            if (entry is Map) {
              return Map<String, dynamic>.from(entry)['id'] as String?;
            }
            return null;
          })
          .whereType<String>()
          .toList();
      if (models.isEmpty) {
        throw AiGatewayException('No models returned from provider');
      }
      return models;
    } on DioException catch (e) {
      throw AiGatewayException(_dioMessage(e));
    }
  }

  static Future<String> generateCommand({
    required AiProvider provider,
    required String apiKey,
    required String model,
    required String userPrompt,
    String? terminalContext,
    CancelToken? cancelToken,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in streamCommand(
      provider: provider,
      apiKey: apiKey,
      model: model,
      userPrompt: userPrompt,
      terminalContext: terminalContext,
      cancelToken: cancelToken,
    )) {
      buffer.write(chunk);
    }

    final command = _stripCommand(buffer.toString());
    if (command.isEmpty) {
      throw AiGatewayException('AI returned an empty command');
    }
    return command;
  }

  static Stream<String> streamCommand({
    required AiProvider provider,
    required String apiKey,
    required String model,
    required String userPrompt,
    String? terminalContext,
    CancelToken? cancelToken,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw AiGatewayException('API key is required for the selected provider');
    }
    if (userPrompt.trim().isEmpty) {
      throw AiGatewayException('Describe the command you want to generate');
    }

    final dio = _createDio(provider: provider, apiKey: apiKey);
    final contextBlock = terminalContext != null && terminalContext.isNotEmpty
        ? '\n\nRecent terminal output:\n$terminalContext'
        : '';

    try {
      final response = await dio.post<ResponseBody>(
        '/chat/completions',
        cancelToken: cancelToken,
        data: <String, dynamic>{
          'model': model,
          'stream': true,
          'messages': <Map<String, String>>[
            {
              'role': 'system',
              'content':
                  'You generate shell commands for SSH terminals. Return only '
                  'a single command with no markdown, no explanation, and no '
                  'code fences.',
            },
            {
              'role': 'user',
              'content': '$userPrompt$contextBlock',
            },
          ],
        },
        options: Options(responseType: ResponseType.stream),
      );

      final body = response.data;
      if (body == null) {
        throw AiGatewayException('No response body from AI provider');
      }

      yield* _parseSseStream(body.stream);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return;
      }
      throw AiGatewayException(_dioMessage(e));
    }
  }

  static Stream<String> _parseSseStream(Stream<List<int>> byteStream) async* {
    final pending = StringBuffer();

    await for (final bytes in byteStream) {
      pending.write(utf8.decode(bytes));
      var content = pending.toString();

      while (true) {
        final separatorIndex = content.indexOf('\n\n');
        if (separatorIndex == -1) {
          break;
        }

        final eventBlock = content.substring(0, separatorIndex);
        content = content.substring(separatorIndex + 2);
        pending
          ..clear()
          ..write(content);

        for (final line in eventBlock.split('\n')) {
          if (!line.startsWith('data:')) {
            continue;
          }
          final payload = line.substring(5).trim();
          if (payload.isEmpty || payload == '[DONE]') {
            continue;
          }

          final delta = _extractDeltaContent(payload);
          if (delta != null && delta.isNotEmpty) {
            yield delta;
          }
        }
      }
    }
  }

  static String? _extractDeltaContent(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return null;
      }
      final choices = Map<String, dynamic>.from(decoded)['choices'];
      if (choices is! List || choices.isEmpty) {
        return null;
      }
      final first = choices.first;
      if (first is! Map) {
        return null;
      }
      final delta = Map<String, dynamic>.from(first)['delta'];
      if (delta is! Map) {
        return null;
      }
      final content = Map<String, dynamic>.from(delta)['content'];
      return content is String ? content : null;
    } catch (_) {
      return null;
    }
  }

  static Dio _createDio({
    required AiProvider provider,
    required String apiKey,
  }) {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    if (provider == AiProvider.opencodeZen) {
      headers['x-opencode-client'] = 'cli';
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrlFor(provider),
        headers: headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
  }

  static String _stripCommand(String raw) {
    var command = raw.trim();
    if (command.startsWith('```')) {
      command = command.replaceFirst(RegExp(r'^```[\w]*\n?'), '');
      command = command.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return command.trim();
  }

  static String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errorBody = Map<String, dynamic>.from(data);
      final message = errorBody['error'];
      if (message is Map) {
        final msg = Map<String, dynamic>.from(message)['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (message is String && message.isNotEmpty) return message;
    }
    return error.message ?? 'AI request failed';
  }
}
