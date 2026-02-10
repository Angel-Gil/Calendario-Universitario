/// Modelo de horario/sesión de clase
class ScheduleModel {
  final String syncId;
  final String subjectId;
  final int dayOfWeek; // 1 = Lunes, 7 = Domingo
  final String startTime; // "08:00"
  final String endTime; // "10:00"
  final String? classroom;
  final DateTime createdAt;
  final bool isSynced;
  final DateTime? deletedAt;

  ScheduleModel({
    required this.syncId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroom,
    DateTime? createdAt,
    this.isSynced = false,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'syncId': syncId,
    'subjectId': subjectId,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'classroom': classroom,
    'createdAt': createdAt.toIso8601String(),
    'isSynced': isSynced,
  };

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    syncId: json['syncId'],
    subjectId: json['subjectId'],
    dayOfWeek: json['dayOfWeek'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    classroom: json['classroom'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    isSynced: json['isSynced'] ?? false,
    deletedAt: json['deletedAt'] != null
        ? DateTime.parse(json['deletedAt'])
        : null,
  );

  ScheduleModel copyWith({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroom,
    bool? isSynced,
  }) => ScheduleModel(
    syncId: syncId,
    subjectId: subjectId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    classroom: classroom ?? this.classroom,
    createdAt: createdAt,
    isSynced: isSynced ?? this.isSynced,
    deletedAt: deletedAt,
  );

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  String get shortDayName {
    switch (dayOfWeek) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mié';
      case 4:
        return 'Jue';
      case 5:
        return 'Vie';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
  }
}
