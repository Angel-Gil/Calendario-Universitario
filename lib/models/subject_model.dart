/// Modelo de materia académica
class SubjectModel {
  final String syncId;
  final String semesterId;
  final String name;
  final String? professor;
  final int colorValue;
  final double passingGrade;
  final int? credits;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  SubjectModel({
    required this.syncId,
    required this.semesterId,
    required this.name,
    this.professor,
    required this.colorValue,
    required this.passingGrade,
    this.credits,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'syncId': syncId,
    'semesterId': semesterId,
    'name': name,
    'professor': professor,
    'colorValue': colorValue,
    'passingGrade': passingGrade,
    'credits': credits,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSynced': isSynced,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
    syncId: json['syncId'],
    semesterId: json['semesterId'],
    name: json['name'],
    professor: json['professor'],
    colorValue: json['colorValue'],
    passingGrade: (json['passingGrade'] as num).toDouble(),
    credits: json['credits'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    isSynced: json['isSynced'] ?? false,
    deletedAt: json['deletedAt'] != null
        ? DateTime.parse(json['deletedAt'])
        : null,
  );

  SubjectModel copyWith({
    String? name,
    String? professor,
    int? colorValue,
    double? passingGrade,
    bool? isSynced,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => SubjectModel(
    syncId: syncId,
    semesterId: semesterId,
    name: name ?? this.name,
    professor: professor ?? this.professor,
    colorValue: colorValue ?? this.colorValue,
    passingGrade: passingGrade ?? this.passingGrade,
    credits: credits,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isSynced: isSynced ?? this.isSynced,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );
}
