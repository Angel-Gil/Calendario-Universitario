/// Enumeraciones globales para la aplicación
library;

/// Estado del semestre
enum SemesterStatus {
  active,
  archived,
}

/// Estado de la materia según cálculo de notas
enum SubjectStatus {
  inProgress,  // En curso, aún tiene cortes pendientes
  approved,    // Aprobada
  atRisk,      // En riesgo - necesita más de 4.0 en los cortes restantes
  failed,      // Reprobada - imposible aprobar
}

/// Tipo de evento académico
enum EventType {
  partial,     // Parcial
  finalExam,   // Examen final
  assignment,  // Trabajo/Tarea
  quiz,        // Quiz
  project,     // Proyecto
  other,       // Otro
}

/// Días de la semana para horarios
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// Extensión para obtener nombres en español
extension WeekDayExtension on WeekDay {
  String get nameEs {
    switch (this) {
      case WeekDay.monday:
        return 'Lunes';
      case WeekDay.tuesday:
        return 'Martes';
      case WeekDay.wednesday:
        return 'Miércoles';
      case WeekDay.thursday:
        return 'Jueves';
      case WeekDay.friday:
        return 'Viernes';
      case WeekDay.saturday:
        return 'Sábado';
      case WeekDay.sunday:
        return 'Domingo';
    }
  }
  
  String get shortNameEs {
    switch (this) {
      case WeekDay.monday:
        return 'Lun';
      case WeekDay.tuesday:
        return 'Mar';
      case WeekDay.wednesday:
        return 'Mié';
      case WeekDay.thursday:
        return 'Jue';
      case WeekDay.friday:
        return 'Vie';
      case WeekDay.saturday:
        return 'Sáb';
      case WeekDay.sunday:
        return 'Dom';
    }
  }
}

extension EventTypeExtension on EventType {
  String get nameEs {
    switch (this) {
      case EventType.partial:
        return 'Parcial';
      case EventType.finalExam:
        return 'Examen Final';
      case EventType.assignment:
        return 'Trabajo';
      case EventType.quiz:
        return 'Quiz';
      case EventType.project:
        return 'Proyecto';
      case EventType.other:
        return 'Otro';
    }
  }
}

extension SubjectStatusExtension on SubjectStatus {
  String get nameEs {
    switch (this) {
      case SubjectStatus.inProgress:
        return 'En Curso';
      case SubjectStatus.approved:
        return 'Aprobada';
      case SubjectStatus.atRisk:
        return 'En Riesgo';
      case SubjectStatus.failed:
        return 'Reprobada';
    }
  }
}
