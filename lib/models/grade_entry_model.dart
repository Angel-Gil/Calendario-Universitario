/// Modelo de una nota individual dentro de un corte
class GradeEntry {
  final String id;
  final String label;
  final double weight; // 0.0 - 1.0 (porcentaje del corte)
  final double? grade;

  GradeEntry({
    required this.id,
    required this.label,
    required this.weight,
    this.grade,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'weight': weight,
    'grade': grade,
  };

  factory GradeEntry.fromJson(Map<String, dynamic> json) => GradeEntry(
    id: json['id'],
    label: json['label'],
    weight: (json['weight'] as num).toDouble(),
    grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
  );

  GradeEntry copyWith({
    String? label,
    double? weight,
    double? grade,
    bool clearGrade = false,
  }) => GradeEntry(
    id: id,
    label: label ?? this.label,
    weight: weight ?? this.weight,
    grade: clearGrade ? null : (grade ?? this.grade),
  );
}
