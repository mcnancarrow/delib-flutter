import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const baseUrl = 'https://www.delib.io';
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'delib_token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'delib_token', value: token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: 'delib_user', value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final str = await _storage.read(key: 'delib_user');
    if (str == null) return null;
    return jsonDecode(str);
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (!res.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Login failed');
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (!res.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Registration failed');
    }
    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/auth/me'), headers: headers);
    final data = jsonDecode(res.body);
    if (!res.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Failed to fetch user');
    }
    return data;
  }

  // ── Deliberation ─────────────────────────────────────────────────
  // mode values: 'freethinkers' | 'api' | 'full'

  static Future<Map<String, dynamic>> deliberate({
    required String question,
    required String mode,
    String verdictStyle = 'analytical',
    String verdictCustom = '',
  }) async {
    final headers = await _authHeaders();

    final Uri uri = mode == 'freethinkers'
        ? Uri.parse('$baseUrl/api/freethinkers')
        : Uri.parse('$baseUrl/api/ask');

    final body = <String, dynamic>{
      'question': question,
      'verdictStyle': verdictStyle,
      'verdictCustom': verdictCustom,
    };
    if (mode != 'freethinkers') body['mode'] = mode; // 'api' or 'full'

    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 403) throw Exception('no_subscription');
    if (res.statusCode == 429) throw Exception('quota_exceeded');
    if (!res.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Deliberation failed');
    }
    return data;
  }

  // ── Stripe ───────────────────────────────────────────────────────

  static Future<String> createCheckout(String plan) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/stripe/checkout'),
      headers: headers,
      body: jsonEncode({'plan': plan}),
    );
    final data = jsonDecode(res.body);
    if (!res.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Checkout failed');
    }
    return data['url'];
  }

  static Future<String> getBillingPortal() async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/stripe/portal'),
      headers: headers,
    );
    final data = jsonDecode(res.body);
    return data['url'] ?? '';
  }
}
