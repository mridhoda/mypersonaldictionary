import 'dart:convert';

class LanguageProfile {
  const LanguageProfile({
    required this.code,
    required this.name,
    this.dailyGoal = 10,
    this.colorHex,
  });

  final String code;
  final String name;
  final int dailyGoal;
  final String? colorHex;

  LanguageProfile copyWith({
    String? code,
    String? name,
    int? dailyGoal,
    String? colorHex,
  }) {
    return LanguageProfile(
      code: code ?? this.code,
      name: name ?? this.name,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'dailyGoal': dailyGoal,
      'colorHex': colorHex,
    };
  }

  factory LanguageProfile.fromMap(Map<String, dynamic> map) {
    return LanguageProfile(
      code: map['code'] as String,
      name: map['name'] as String,
      dailyGoal: (map['dailyGoal'] ?? 10) as int,
      colorHex: map['colorHex'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory LanguageProfile.fromJson(String source) =>
      LanguageProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
