import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';

class DeepSeekApi {
  static const String _baseUrl = 'https://api.deepseek.com';
  final String apiKey;
  final Dio _dio = Dio();

  DeepSeekApi({required this.apiKey}) {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  // 普通请求
  Future<dynamic> chatCompletions({
    required List<Map<String, String>> messages,
    String? model,
    bool? stream,
  }) async {
    model ??= 'deepseek-chat';
    stream ??= false;
    if (stream) {
          final controller = StreamController<String>();

    _dio
        .post(
          '/chat/completions',
          data: {'model': model, 'messages': messages, 'stream': true},
          options: Options(responseType: ResponseType.stream),
        )
        .then((response) {
          final responseStream = response.data as ResponseBody;
          responseStream.stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(
                (line) {
                  if (line.startsWith('data:')) {
                    final data = line.substring(5).trim();
                    if (data != '[DONE]') {
                      controller.add(data);
                    }
                  }
                },
                onDone: controller.close,
                onError: controller.addError,
              );
        })
        .catchError(controller.addError);

    return controller.stream;
    } else {
      try {
        final response = await _dio.post(
          '/chat/completions',
          data: {'model': model, 'messages': messages, 'stream': stream},
        );
        return response.data;
      } on DioException catch (e) {
        throw Exception(
          'Failed to call DeepSeek API: ${e.response?.data ?? e.message}',
        );
      }
    }
  }

}
