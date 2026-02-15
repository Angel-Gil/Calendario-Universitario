import 'grade_entry_model.dart';

/// Modelo de corte/período de evaluación
class GradePeriodModel {
  final String syncId;
  final String subjectId;
  final String name;
  final double percentage;
  final double? obtainedGrade;
  final List<GradeEntry> grades; // Sub-notas dinámicas
  final int order;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  GradePeriodModel({
    required this.syncId,
    required this.subjectId,
    required this.name,
    required this.percentage,
    this.obtainedGrade,
    this.grades = const [],
    required this.order,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isGraded =>
      obtainedGrade != null || grades.any((g) => g.grade != null);

  /// Nota calculada: si hay sub-notas, promedio ponderado; si no, obtainedGrade directo
  double? get computedGrade {
    if (grades.isNotEmpty) {
      final graded = grades.where((g) => g.grade != null).toList();
      if (graded.isEmpty) return null;
      final totalWeight = graded.fold(0.0, (s, g) => s + g.weight);
      if (totalWeight == 0) return null;
      return graded.fold(0.0, (s, g) => s + g.grade! * g.weight) / totalWeight;
    }
    return obtainedGrade;
  }

  double get earnedPoints {
    final grade = computedGrade;
    return grade != null ? grade * percentage : 0.0;
  }

  Map<String, dynamic> toJson() => {
    'syncId': syncId,
    'subjectId': subjectId,
    'name': name,
    'percentage': percentage,
    'obtainedGrade': obtainedGrade,
    'grades': grades.map((g) => g.toJson()).toList(),
    'order': order,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  GradePeriodModel copyWith({
    String? name,
    double? percentage,
    double? obtainedGrade,
    List<GradeEntry>? grades,
    int? order,
    DateTime? dueDate,
    bool? isSynced,
    bool clearObtainedGrade = false,
  }) => GradePeriodModel(
    syncId: syncId,
    subjectId: subjectId,
    name: name ?? this.name,
    percentage: percentage ?? this.percentage,
    obtainedGrade: clearObtainedGrade
        ? null
        : (obtainedGrade ?? this.obtainedGrade),
    grades: grades ?? this.grades,
    order: order ?? this.order,
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isSynced: isSynced ?? this.isSynced,
    deletedAt: deletedAt,
  );
}
