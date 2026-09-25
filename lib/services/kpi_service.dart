import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_state.dart';

class KpiService {
  static Future<Map<String, dynamic>> fetch() async {
    final res = await http.get(
      Uri.parse('${AuthState.baseUrl}/api/auth/kpi/'),
      headers: {'Authorization': 'Token ${AuthState.instance.token}'},
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur serveur ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}