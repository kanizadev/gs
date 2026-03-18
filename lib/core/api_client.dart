import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    TokenStore? tokenStore,
  })  : _http = httpClient ?? http.Client(),
        _tokenStore = tokenStore ?? TokenStore.instance;

  final String baseUrl;
  final http.Client _http;
  final TokenStore _tokenStore;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _tokenStore.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _http.get(_uri(path, query), headers: _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final res = await _http.post(
      _uri(path, query),
      headers: _headers(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    return _decodeJson(res);
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}', statusCode: res.statusCode);
    }

    final text = res.body.trim();
    if (text.isEmpty) return const <String, dynamic>{};

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Expected JSON object');
  }
}

