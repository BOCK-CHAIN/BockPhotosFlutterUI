import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class HealthService {
  Future<HealthStatus> check() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/health');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        try {
          final data = jsonDecode(resp.body);
          final ok = data is Map<String, dynamic>
              ? (data['ok'] == true || data['status'] == 'ok' || data['success'] == true)
              : true;
          return HealthStatus(ok: ok);
        } catch (_) {
          return const HealthStatus(ok: true);
        }
      }
      return HealthStatus(ok: false, message: 'Health check failed (${resp.statusCode})');
    } catch (e) {
      return HealthStatus(ok: false, message: 'Network error');
    }
  }
}

class HealthStatus {
  final bool ok;
  final String? message;

  const HealthStatus({required this.ok, this.message});
}


