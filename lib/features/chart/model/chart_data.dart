/// A single planet's position in a chart.
class PlanetPosition {
  final String name;
  final String sign;       // e.g. "Ari", "Tau", "Gem" ...
  final double degree;     // 0-30 within sign
  final double absDegree;  // 0-360 absolute
  final int house;         // 1-12
  final bool retrograde;

  const PlanetPosition({
    required this.name,
    required this.sign,
    required this.degree,
    required this.absDegree,
    required this.house,
    required this.retrograde,
  });

  /// 星座完整中文名
  String get signChinese => _signMap[sign] ?? sign;

  /// 星座符号 unicode
  String get signGlyph => _glyphMap[sign] ?? '?';

  /// 行星符号 unicode
  String get planetGlyph => _planetGlyphMap[name] ?? name[0];

  static const _signMap = {
    'Ari': '白羊座', 'Tau': '金牛座', 'Gem': '双子座', 'Can': '巨蟹座',
    'Leo': '狮子座', 'Vir': '处女座', 'Lib': '天秤座', 'Sco': '天蝎座',
    'Sag': '射手座', 'Cap': '摩羯座', 'Aqu': '水瓶座', 'Pis': '双鱼座',
  };

  static const _glyphMap = {
    'Ari': '\u2648', 'Tau': '\u2649', 'Gem': '\u264A', 'Can': '\u264B',
    'Leo': '\u264C', 'Vir': '\u264D', 'Lib': '\u264E', 'Sco': '\u264F',
    'Sag': '\u2650', 'Cap': '\u2651', 'Aqu': '\u2652', 'Pis': '\u2653',
  };

  static const _planetGlyphMap = {
    'Sun': '\u2609', 'Moon': '\u263D', 'Mercury': '\u263F',
    'Venus': '\u2640', 'Mars': '\u2642', 'Jupiter': '\u2643',
    'Saturn': '\u2644', 'Uranus': '\u2645', 'Neptune': '\u2646',
    'Pluto': '\u2647',
  };

  static const signOrder = [
    'Ari', 'Tau', 'Gem', 'Can', 'Leo', 'Vir',
    'Lib', 'Sco', 'Sag', 'Cap', 'Aqu', 'Pis',
  ];

  factory PlanetPosition.fromApiJson(Map<String, dynamic> json) {
    return PlanetPosition(
      name: json['name'] as String? ?? '',
      sign: json['sign'] as String? ?? '',
      degree: (json['pos'] as num?)?.toDouble() ?? 0,
      absDegree: (json['abs_pos'] as num?)?.toDouble() ?? 0,
      house: (json['house'] as num?)?.toInt() ?? 1,
      retrograde: json['retrograde'] as bool? ?? false,
    );
  }
}

/// Complete chart data (natal or transit).
class ChartData {
  final List<PlanetPosition> planets;
  final double ascendantDegree; // 0-360

  const ChartData({
    required this.planets,
    required this.ascendantDegree,
  });

  PlanetPosition? get sun => _byName('Sun');
  PlanetPosition? get moon => _byName('Moon');
  PlanetPosition? get ascendant => planets.isEmpty
      ? null
      : PlanetPosition(
          name: 'Asc',
          sign: PlanetPosition.signOrder[(ascendantDegree ~/ 30).clamp(0, 11)],
          degree: ascendantDegree % 30,
          absDegree: ascendantDegree,
          house: 1,
          retrograde: false,
        );

  PlanetPosition? _byName(String name) {
    for (final p in planets) {
      if (p.name == name) return p;
    }
    return null;
  }

  factory ChartData.fromApiJson(Map<String, dynamic> json) {
    final planetsJson = json['planets'] as List<dynamic>? ?? [];
    final planets = planetsJson
        .map((p) => PlanetPosition.fromApiJson(p as Map<String, dynamic>))
        .toList();

    // Extract ascendant degree from angles
    final angles = json['angles'] as Map<String, dynamic>?;
    final asc = (angles?['asc'] as num?)?.toDouble() ?? 0;

    return ChartData(planets: planets, ascendantDegree: asc);
  }

  /// Mock data for development without API key
  factory ChartData.mock({bool isTransit = false}) {
    if (isTransit) {
      return const ChartData(
        ascendantDegree: 195.0,
        planets: [
          PlanetPosition(name: 'Sun', sign: 'Ari', degree: 13.5, absDegree: 13.5, house: 7, retrograde: false),
          PlanetPosition(name: 'Moon', sign: 'Sco', degree: 22.1, absDegree: 232.1, house: 2, retrograde: false),
          PlanetPosition(name: 'Mercury', sign: 'Pis', degree: 28.7, absDegree: 358.7, house: 6, retrograde: true),
          PlanetPosition(name: 'Venus', sign: 'Tau', degree: 5.3, absDegree: 35.3, house: 8, retrograde: false),
          PlanetPosition(name: 'Mars', sign: 'Can', degree: 18.9, absDegree: 108.9, house: 10, retrograde: false),
          PlanetPosition(name: 'Jupiter', sign: 'Gem', degree: 10.2, absDegree: 70.2, house: 9, retrograde: false),
          PlanetPosition(name: 'Saturn', sign: 'Pis', degree: 15.8, absDegree: 345.8, house: 6, retrograde: false),
          PlanetPosition(name: 'Uranus', sign: 'Tau', degree: 28.4, absDegree: 58.4, house: 8, retrograde: false),
          PlanetPosition(name: 'Neptune', sign: 'Ari', degree: 2.6, absDegree: 2.6, house: 7, retrograde: false),
          PlanetPosition(name: 'Pluto', sign: 'Aqu', degree: 4.1, absDegree: 304.1, house: 5, retrograde: false),
        ],
      );
    }
    return const ChartData(
      ascendantDegree: 187.0,
      planets: [
        PlanetPosition(name: 'Sun', sign: 'Leo', degree: 15.3, absDegree: 135.3, house: 10, retrograde: false),
        PlanetPosition(name: 'Moon', sign: 'Gem', degree: 22.7, absDegree: 82.7, house: 8, retrograde: false),
        PlanetPosition(name: 'Mercury', sign: 'Vir', degree: 3.1, absDegree: 153.1, house: 11, retrograde: false),
        PlanetPosition(name: 'Venus', sign: 'Can', degree: 28.5, absDegree: 118.5, house: 9, retrograde: false),
        PlanetPosition(name: 'Mars', sign: 'Ari', degree: 10.8, absDegree: 10.8, house: 5, retrograde: false),
        PlanetPosition(name: 'Jupiter', sign: 'Sag', degree: 5.2, absDegree: 245.2, house: 2, retrograde: false),
        PlanetPosition(name: 'Saturn', sign: 'Cap', degree: 18.9, absDegree: 288.9, house: 3, retrograde: true),
        PlanetPosition(name: 'Uranus', sign: 'Sco', degree: 12.4, absDegree: 222.4, house: 1, retrograde: false),
        PlanetPosition(name: 'Neptune', sign: 'Sag', degree: 27.6, absDegree: 267.6, house: 2, retrograde: false),
        PlanetPosition(name: 'Pluto', sign: 'Lib', degree: 20.1, absDegree: 200.1, house: 12, retrograde: false),
      ],
    );
  }
}
