import 'enums.dart';

/// Modelo de evento académico
class EventModel {
  final String syncId;
  final String subjectId;
  final String title;
  final String? notes;
  final EventType type;
  final DateTime dateTime;
  final int? durationMinutes;
  final bool hasReminder;
  final int? reminderMinutesBefore;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  EventModel({
    required this.syncId,
    required this.subjectId,
    required this.title,
    this.notes,
    required this.type,
    required this.dateTime,
    this.durationMinutes,
    this.hasReminder = false,
    this.reminderMinutesBefore,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  Map<String, dynamic> toJson() => {
    'syncId': syncId,
    'subjectId': subjectId,
    'title': title,
    'notes': notes,
    'type': type.name,
    'dateTime': dateTime.toIso8601String(),
    'hasReminder': hasReminder,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  EventModel copyWith({bool? isCompleted, bool? isSynced}) => EventModel(
    syncId: syncId,
    subjectId: subjectId,
    title: title,
    notes: notes,
    type: type,
    dateTime: dateTime,
    durationMinutes: durationMinutes,
    hasReminder: hasReminder,
    reminderMinutesBefore: reminderMinutesBefore,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isSynced: isSynced ?? this.isSynced,
    deletedAt: deletedAt,
  );
}
