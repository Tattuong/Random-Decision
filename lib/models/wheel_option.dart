import 'dart:convert';

class WheelOption {
  final String id;
  final String label;
  final int weight;

  const WheelOption({
    required this.id,
    required this.label,
    this.weight = 1,
  });

  WheelOption copyWith({String? label, int? weight}) => WheelOption(
        id: id,
        label: label ?? this.label,
        weight: weight ?? this.weight,
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'weight': weight};

  factory WheelOption.fromJson(Map<String, dynamic> json) => WheelOption(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        weight: (json['weight'] as num?)?.toInt() ?? 1,
      );
}

class SpinResult {
  final String optionId;
  final String label;
  final DateTime at;

  const SpinResult({required this.optionId, required this.label, required this.at});

  Map<String, dynamic> toJson() => {
        'optionId': optionId,
        'label': label,
        'at': at.toIso8601String(),
      };

  factory SpinResult.fromJson(Map<String, dynamic> json) => SpinResult(
        optionId: json['optionId']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      );
}

List<WheelOption> decodeWheelOptions(String? raw) {
  if (raw == null || raw.isEmpty) return defaultWheelOptions();
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    final options = list.map((e) => WheelOption.fromJson(e as Map<String, dynamic>)).where((o) => o.label.trim().isNotEmpty).toList();
    return options.isEmpty ? defaultWheelOptions() : options;
  } catch (_) {
    return defaultWheelOptions();
  }
}

List<SpinResult> decodeSpinHistory(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => SpinResult.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
}

List<WheelOption> defaultWheelOptions() => const [
      WheelOption(id: '1', label: 'Pizza'),
      WheelOption(id: '2', label: 'Burger'),
      WheelOption(id: '3', label: 'Sushi'),
      WheelOption(id: '4', label: 'Salad'),
      WheelOption(id: '5', label: 'Pasta'),
      WheelOption(id: '6', label: 'Tacos'),
    ];
