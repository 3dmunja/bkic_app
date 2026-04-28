import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/exceptions.dart';
import 'auth_service.dart';

class ApiHelper {
  static Uri _buildUri(String url) {
    return Uri.parse(url);
  }

  static Future<Map<String, String>> _buildHeaders({
    bool authRequired = false,
    bool includeAuthIfAvailable = false,
    Map<String, String>? headers,
    bool isJson = false,
  }) async {
    final map = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    if (isJson) {
      map['Content-Type'] = 'application/json';
    }

    if (authRequired || includeAuthIfAvailable) {
      final token = await AuthService.storage.read(key: tokenStorageKey);

      if (authRequired && (token == null || token.isEmpty)) {
        throw const SessionExpiredException('Sesija nije važeća');
      }

      if (token != null && token.isNotEmpty) {
        map['Authorization'] = 'Bearer $token';
      }
    }

    return map;
  }

  static Future<Map<String, dynamic>> getJson(
    String url, {
    bool authRequired = false,
    bool includeAuthIfAvailable = false,
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      _buildUri(url),
      headers: await _buildHeaders(
        authRequired: authRequired,
        includeAuthIfAvailable: includeAuthIfAvailable,
        headers: headers,
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postJson(
    String url, {
    required Map<String, dynamic> body,
    bool authRequired = false,
    bool includeAuthIfAvailable = false,
    Map<String, String>? headers,
  }) async {
    final response = await http.post(
      _buildUri(url),
      headers: await _buildHeaders(
        authRequired: authRequired,
        includeAuthIfAvailable: includeAuthIfAvailable,
        headers: headers,
        isJson: true,
      ),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    required String fileFieldName,
    required File file,
    bool authRequired = false,
    bool includeAuthIfAvailable = false,
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(url));

    request.headers.addAll(
      await _buildHeaders(
        authRequired: authRequired,
        includeAuthIfAvailable: includeAuthIfAvailable,
        headers: headers,
      ),
    );

    request.fields.addAll(fields);

    request.files.add(
      await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(
    String url,
    String token,
  ) async {
    final response = await http.get(
      _buildUri(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static String _extractMessage(
    Map<String, dynamic> decoded,
    String fallback,
  ) {
    final message = decoded['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final data = decoded['data'];

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    final code = decoded['code'];
    if (code != null && code.toString().trim().isNotEmpty) {
      return code.toString();
    }

    return fallback;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final raw = response.body.trim();
    Map<String, dynamic> decoded = <String, dynamic>{};

    if (raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);

        if (data is Map<String, dynamic>) {
          decoded = data;
        } else if (data is Map) {
          decoded = Map<String, dynamic>.from(data);
        } else {
          throw ApiException(
            'Server svarede med ugyldigt JSON-format',
            statusCode: response.statusCode,
          );
        }
      } catch (_) {
        throw ApiException(
          'Server svarede ikke med gyldig JSON',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SessionExpiredException(
        _extractMessage(decoded, 'Niste autorizovani'),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractMessage(decoded, 'HTTP greška: ${response.statusCode}'),
        statusCode: response.statusCode,
      );
    }

    if (decoded.isEmpty) {
      throw const ApiException('Prazan ili nevažeći odgovor servera');
    }

    return decoded;
  }
}