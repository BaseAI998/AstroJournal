import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chart_data.dart';

class AstroApiService {
  // ============================================================
  // 👇 在这里替换你的 API Key
  static const String _apiKey = '1bd9c2fbdcc82dc42895317d15f438390e8e3ec7337fe645019437d5b7f71561';
  // ============================================================

  static const String _baseUrl = 'https://api.freeastroapi.com/api/v1';

  /// 获取本命盘数据
  static Future<ChartData> fetchNatalChart({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/natal/calculate'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      },
      body: jsonEncode({
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute,
        'city': city,
        'zodiac_type': 'tropical',
        'house_system': 'placidus',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_friendlyError('本命盘', response.statusCode, response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ChartData.fromApiJson(json);
  }

  /// 获取当前行运盘数据
  static Future<ChartData> fetchTransitChart({
    required int natalYear,
    required int natalMonth,
    required int natalDay,
    required int natalHour,
    required int natalMinute,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/transits/calculate'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      },
      body: jsonEncode({
        'natal': {
          'year': natalYear,
          'month': natalMonth,
          'day': natalDay,
          'hour': natalHour,
          'minute': natalMinute,
          'city': city,
        },
        'current_city': city,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_friendlyError('行运盘', response.statusCode, response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Transit 端点返回的行星在 transit_planets 字段
    final transitPlanets = json['transit_planets'] as List<dynamic>? ?? [];
    final angles = json['angles'] as Map<String, dynamic>?;
    final asc = (angles?['asc'] as num?)?.toDouble() ?? 0;

    return ChartData(
      planets: transitPlanets
          .map((p) => PlanetPosition.fromApiJson(p as Map<String, dynamic>))
          .toList(),
      ascendantDegree: asc,
    );
  }

  static String _friendlyError(String label, int statusCode, String body) {
    final bodyLower = body.toLowerCase();

    if (statusCode == 422 || bodyLower.contains('city') || bodyLower.contains('location')) {
      return '无法识别出生城市，请在设置中使用英文城市名（如 Beijing, Shanghai）';
    }
    if (statusCode == 429) {
      return '请求过于频繁，请稍后再试';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'API Key 无效，请检查配置';
    }
    return '$label请求失败 ($statusCode)';
  }
}
