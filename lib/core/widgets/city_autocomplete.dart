import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

/// 城市搜索结果
class CityResult {
  final String name;
  final String country;
  final double lat;
  final double lng;
  final String timezone;

  const CityResult({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    required this.timezone,
  });

  /// 显示名："Beijing, CN"
  String get displayName => '$name, $country';

  factory CityResult.fromJson(Map<String, dynamic> json) {
    return CityResult(
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      timezone: json['timezone'] as String? ?? '',
    );
  }
}

/// 城市自动补全输入框
class CityAutocomplete extends StatefulWidget {
  final String initialValue;
  final ValueChanged<CityResult> onSelected;
  final InputDecoration? decoration;

  const CityAutocomplete({
    super.key,
    this.initialValue = '',
    required this.onSelected,
    this.decoration,
  });

  @override
  State<CityAutocomplete> createState() => _CityAutocompleteState();
}

class _CityAutocompleteState extends State<CityAutocomplete> {
  late final TextEditingController _controller;
  List<CityResult> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _suppressSearch = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_suppressSearch) {
      _suppressSearch = false;
      return;
    }
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    try {
      final uri = Uri.parse(
          'https://api.freeastroapi.com/api/v1/geo/search?q=$query&limit=6');
      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (json['results'] as List<dynamic>? ?? [])
          .map((e) => CityResult.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    } catch (_) {
      // 搜索失败静默处理
    }
  }

  void _selectCity(CityResult city) {
    _suppressSearch = true;
    _controller.text = city.displayName;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    widget.onSelected(city);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: widget.decoration ??
              InputDecoration(
                hintText: '输入城市名（英文）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.search,
                    size: 18, color: AppTheme.textSecondary),
              ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (context, index) {
                final city = _suggestions[index];
                return InkWell(
                  onTap: () => _selectCity(city),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppTheme.accentGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            city.displayName,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          city.timezone,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
