/// Modelo para un bloque de horario de clase
class ScheduleSlot {
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? classroom;

  ScheduleSlot({
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.classroom,
  });

  String get startTimeFormatted {
    final h = startMinutes ~/ 60;
    final m = startMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get endTimeFormatted {
    final h = endMinutes ~/ 60;
    final m = endMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'classroom': classroom,
  };

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
    dayOfWeek: json['dayOfWeek'],
    startMinutes: json['startMinutes'],
    endMinutes: json['endMinutes'],
    classroom: json['classroom'],
  );
}
