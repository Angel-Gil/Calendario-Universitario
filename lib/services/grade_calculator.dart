import '../models/models.dart';

/// Servicio para cálculo de notas académicas
class GradeCalculator {
  /// Calcula la nota final actual basada en los cortes con calificación
  ///
  /// Retorna la nota ponderada de los cortes que ya tienen nota.
  /// Si ningún corte tiene nota, retorna 0.
  static double calculateCurrentGrade(List<GradePeriodModel> periods) {
    if (periods.isEmpty) return 0.0;

    double totalGrade = 0.0;
    double totalPercentage = 0.0;

    for (final period in periods) {
      if (period.obtainedGrade != null) {
        totalGrade += period.obtainedGrade! * period.percentage;
        totalPercentage += period.percentage;
      }
    }

    // Si no hay cortes calificados, retornar 0
    if (totalPercentage == 0) return 0.0;

    // Retornar la nota ponderada normalizada
    return totalGrade / totalPercentage;
  }

  /// Calcula la nota acumulada (suma de nota * porcentaje para cada corte)
  ///
  /// Esta es la nota real acumulada, no la proyección.
  static double calculateAccumulatedGrade(List<GradePeriodModel> periods) {
    if (periods.isEmpty) return 0.0;

    double accumulated = 0.0;

    for (final period in periods) {
      if (period.obtainedGrade != null) {
        accumulated += period.obtainedGrade! * period.percentage;
      }
    }

    return accumulated;
  }

  /// Calcula la nota necesaria en los cortes restantes para aprobar
  ///
  /// [periods] - Lista de cortes de la materia
  /// [passingGrade] - Nota mínima para aprobar (ej: 3.0)
  /// [maxGrade] - Nota máxima posible (ej: 5.0 o 10.0)
  ///
  /// Retorna la nota que necesita sacar EN PROMEDIO en los cortes restantes.
  /// Si ya aprobó o es imposible aprobar, retorna valores especiales.
  static double calculateRequiredGrade({
    required List<GradePeriodModel> periods,
    required double passingGrade,
    double maxGrade = 5.0,
  }) {
    if (periods.isEmpty) return passingGrade;

    double earnedPoints = 0.0;
    double remainingPercentage = 0.0;

    for (final period in periods) {
      if (period.obtainedGrade != null) {
        earnedPoints += period.obtainedGrade! * period.percentage;
      } else {
        remainingPercentage += period.percentage;
      }
    }

    // Si no hay cortes pendientes, ya no se puede hacer nada
    if (remainingPercentage == 0) {
      return 0.0;
    }

    // Calcular nota necesaria
    final neededPoints = passingGrade - earnedPoints;
    final requiredGrade = neededPoints / remainingPercentage;

    return requiredGrade;
  }

  /// Determina el estado actual de la materia
  ///
  /// Estados posibles:
  /// - [SubjectStatus.approved]: Nota final >= nota mínima (ya terminó)
  /// - [SubjectStatus.failed]: Imposible aprobar incluso con nota máxima
  /// - [SubjectStatus.atRisk]: Necesita más de cierto umbral para aprobar
  /// - [SubjectStatus.inProgress]: Normal, puede aprobar cómodamente
  static SubjectStatus determineStatus({
    required List<GradePeriodModel> periods,
    required double passingGrade,
    double maxGrade = 5.0,
    double riskThreshold = 0.8, // 80% de la nota máxima
  }) {
    if (periods.isEmpty) return SubjectStatus.inProgress;

    final allGraded = periods.every((p) => p.obtainedGrade != null);
    final accumulatedGrade = calculateAccumulatedGrade(periods);

    // Si todos los cortes están calificados
    if (allGraded) {
      return accumulatedGrade >= passingGrade
          ? SubjectStatus.approved
          : SubjectStatus.failed;
    }

    final required = calculateRequiredGrade(
      periods: periods,
      passingGrade: passingGrade,
      maxGrade: maxGrade,
    );

    // Imposible aprobar (necesita más de la nota máxima)
    if (required > maxGrade) {
      return SubjectStatus.failed;
    }

    // En riesgo (necesita una nota alta)
    if (required > maxGrade * riskThreshold) {
      return SubjectStatus.atRisk;
    }

    return SubjectStatus.inProgress;
  }

  /// Calcula el porcentaje completado de la materia
  static double calculateCompletionPercentage(List<GradePeriodModel> periods) {
    if (periods.isEmpty) return 0.0;

    double completedPercentage = 0.0;

    for (final period in periods) {
      if (period.obtainedGrade != null) {
        completedPercentage += period.percentage;
      }
    }

    return completedPercentage * 100; // Retornar como porcentaje 0-100
  }

  /// Valida que los porcentajes de los cortes sumen 100%
  static bool validatePercentages(List<GradePeriodModel> periods) {
    if (periods.isEmpty) return false;

    double total = 0.0;
    for (final period in periods) {
      total += period.percentage;
    }

    // Permitir un pequeño margen de error por redondeo
    return (total - 1.0).abs() < 0.001;
  }

  /// Genera un resumen del estado académico de la materia
  static GradeSummary generateSummary({
    required List<GradePeriodModel> periods,
    required double passingGrade,
    double maxGrade = 5.0,
  }) {
    return GradeSummary(
      currentGrade: calculateCurrentGrade(periods),
      accumulatedGrade: calculateAccumulatedGrade(periods),
      requiredGrade: calculateRequiredGrade(
        periods: periods,
        passingGrade: passingGrade,
        maxGrade: maxGrade,
      ),
      status: determineStatus(
        periods: periods,
        passingGrade: passingGrade,
        maxGrade: maxGrade,
      ),
      completionPercentage: calculateCompletionPercentage(periods),
      remainingPeriods: periods.where((p) => p.obtainedGrade == null).length,
      totalPeriods: periods.length,
    );
  }
}

/// Resumen de calificaciones de una materia
class GradeSummary {
  /// Nota actual (promedio ponderado de cortes calificados)
  final double currentGrade;

  /// Nota acumulada (suma de nota * porcentaje)
  final double accumulatedGrade;

  /// Nota requerida en cortes restantes para aprobar
  final double requiredGrade;

  /// Estado actual de la materia
  final SubjectStatus status;

  /// Porcentaje completado de la materia (0-100)
  final double completionPercentage;

  /// Número de cortes pendientes
  final int remainingPeriods;

  /// Número total de cortes
  final int totalPeriods;

  const GradeSummary({
    required this.currentGrade,
    required this.accumulatedGrade,
    required this.requiredGrade,
    required this.status,
    required this.completionPercentage,
    required this.remainingPeriods,
    required this.totalPeriods,
  });

  /// Indica si es posible aprobar la materia
  bool get canPass => status != SubjectStatus.failed;

  /// Indica si la materia está completamente calificada
  bool get isComplete => remainingPeriods == 0;
}
