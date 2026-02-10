import 'enums.dart';

/// Modelo de semestre académico
class SemesterModel {
  final String syncId;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final SemesterStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  SemesterModel({
    required this.syncId,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = SemesterStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'syncId': syncId,
    'userId': userId,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SemesterModel.fromJson(Map<String, dynamic> json) => SemesterModel(
    syncId: json['syncId'],
    userId: json['userId'],
    name: json['name'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    status: SemesterStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SemesterStatus.active,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    isSynced: json['isSynced'] ?? false,
    deletedAt: json['deletedAt'] != null
        ? DateTime.parse(json['deletedAt'])
        : null,
  );

  SemesterModel copyWith({
    String? name,
    SemesterStatus? status,
    bool? isSynced,
  }) => SemesterModel(
    syncId: syncId,
    userId: userId,
    name: name ?? this.name,
    startDate: startDate,
    endDate: endDate,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isSynced: isSynced ?? this.isSynced,
    deletedAt: deletedAt,
  );
}
