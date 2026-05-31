import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:client/core/env/env.dart';
import 'package:client/core/error/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _defaultTimeout = Duration(seconds: 30);
  static const _bytesTimeout = Duration(seconds: 60);

  static const _headers = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client
        .get(_uri(path), headers: _headers)
        .timeout(_defaultTimeout);
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getJsonList(String path) async {
    final response = await _client
        .get(_uri(path), headers: _headers)
        .timeout(_defaultTimeout);
    _checkStatus(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> postJson(String path, Object body) async {
    final response = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_defaultTimeout);
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    final response = await _client
        .delete(_uri(path), headers: _headers)
        .timeout(_defaultTimeout);
    _checkStatus(response);
  }

  Future<Uint8List> getBytes(
    String path, {
    Duration timeout = _bytesTimeout,
  }) async {
    final response =
        await _client.get(_uri(path), headers: _headers).timeout(timeout);
    _checkStatus(response);
    return response.bodyBytes;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
