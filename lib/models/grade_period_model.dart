/// Modelo de corte/período de evaluación
class GradePeriodModel {
  final String syncId;
  final String subjectId;
  final String name;
  final double percentage;
  final double? obtainedGrade;
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
    required this.order,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isGraded => obtainedGrade != null;
  double get earnedPoints =>
      obtainedGrade != null ? obtainedGrade! * percentage : 0.0;

  Map<String, dynamic> toJson() => {
    'syncId': syncId,
    'subjectId': subjectId,
    'name': name,
    'percentage': percentage,
    'obtainedGrade': obtainedGrade,
    'order': order,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  GradePeriodModel copyWith({
    String? name,
    double? percentage,
    double? obtainedGrade,
    int? order,
    DateTime? dueDate,
    bool? isSynced,
  }) => GradePeriodModel(
    syncId: syncId,
    subjectId: subjectId,
    name: name ?? this.name,
    percentage: percentage ?? this.percentage,
    obtainedGrade: obtainedGrade ?? this.obtainedGrade,
    order: order ?? this.order,
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isSynced: isSynced ?? this.isSynced,
    deletedAt: deletedAt,
  );
}
