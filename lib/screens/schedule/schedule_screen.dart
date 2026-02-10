import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/local_database_service.dart';

/// Pantalla de horario semanal con colores de materias
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _db = LocalDatabaseService.instance;
  final List<String> _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final List<_ScheduleBlock> _blocks = [];
  bool _isLoading = true;

  // Configuración de horario
  final double _startHour = 7.0; // 7:00 AM
  final double _endHour = 22.0; // Hasta 10 PM
  final int _slotDurationMinutes = 110; // 1 hora 50 minutos
  late double _pixelsPerMinute;
  late double _slotHeight;
  List<double> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _pixelsPerMinute =
        0.45; // Reducido para que ocupe menos altura (aprox mitad de pantalla)
    _slotHeight = _slotDurationMinutes * _pixelsPerMinute;
    _generateTimeSlots();
    _loadSchedule();
  }

  void _generateTimeSlots() {
    _timeSlots.clear();
    double currentMinutes = _startHour * 60;
    final endMinutes = _endHour * 60;

    while (currentMinutes < endMinutes) {
      _timeSlots.add(currentMinutes / 60.0); // Guardar como horas decimales
      currentMinutes += _slotDurationMinutes;
    }
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    final user = _db.getCurrentUser();
    if (user != null) {
      final semesters = _db.getSemesters(user.uid);
      if (semesters.isNotEmpty) {
        final activeSemester = semesters.first;
        final schedules = _db.getAllSchedulesForSemester(activeSemester.syncId);

        final blocks = <_ScheduleBlock>[];

        for (final schedule in schedules) {
          final subject = _db.getSubject(schedule.subjectId);
          if (subject != null) {
            blocks.add(
              _ScheduleBlock(
                id: schedule.syncId,
                subjectName: subject.name,
                classroom: schedule.classroom ?? '',
                dayIndex: schedule.dayOfWeek - 1,
                startHour: _parseTime(schedule.startTime),
                endHour: _parseTime(schedule.endTime),
                color: Color(subject.colorValue),
                model: schedule,
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            _blocks.clear();
            _blocks.addAll(blocks);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _parseTime(String time) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h + (m / 60.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario Semanal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              // TODO: Scroll al día actual
            },
            tooltip: 'Ir a hoy',
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeColumn(theme),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                children: List.generate(
                  _days.length,
                  (i) => Expanded(child: _buildDayColumn(theme, i)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Edita las materias para cambiar el horario'),
            ),
          );
        },
        icon: const Icon(Icons.edit_calendar),
        label: const Text('Gestionar'),
      ),
    );
  }

  Widget _buildTimeColumn(ThemeData theme) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: 60, // Un poco más ancho para horas largas
        child: Column(
          children: [
            const SizedBox(height: 44), // Header spacer
            ..._timeSlots.map(
              (time) => Container(
                height: _slotHeight,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTime(time + (_slotDurationMinutes / 60.0)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(ThemeData theme, int dayIndex) {
    final dayBlocks = _blocks.where((b) => b.dayIndex == dayIndex).toList();
    final isToday = DateTime.now().weekday == dayIndex + 1;

    return Container(
      margin: const EdgeInsets.only(left: 1),
      child: Column(
        children: [
          // Header del día
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 1)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              _days[dayIndex],
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? theme.colorScheme.primary : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Cuerpo con bloques
          Stack(
            children: [
              // Grilla de fondo
              Column(
                children: _timeSlots
                    .map(
                      (_) => Container(
                        height: _slotHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                            left: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // Bloques de clase
              ...dayBlocks.map((block) => _buildScheduleBlock(theme, block)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleBlock(ThemeData theme, _ScheduleBlock block) {
    // Calcular posición basada en minutos desde _startHour
    final startMinutes = (block.startHour - _startHour) * 60;
    final durationMinutes = (block.endHour - block.startHour) * 60;

    final top = startMinutes * _pixelsPerMinute;
    final height = durationMinutes * _pixelsPerMinute;

    // Evitar bloques negativos o muy pequeños
    if (height <= 0) return const SizedBox();

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height > 2 ? height - 2 : height,
      child: GestureDetector(
        onTap: () {
          context.push('/subject/${block.model.subjectId}');
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: block.color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                block.subjectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (block.classroom.isNotEmpty)
                Text(
                  block.classroom,
                  style: const TextStyle(color: Colors.white70, fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(double time) {
    final h = time.floor();
    final m = ((time - h) * 60).round();

    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);

    return '$hour12:${m.toString().padLeft(2, '0')}'; // Sin period para ahorrar espacio en subtítulo
  }
}

class _ScheduleBlock {
  final String id;
  final String subjectName;
  final String classroom;
  final int dayIndex;
  final double startHour;
  final double endHour;
  final Color color;
  final ScheduleModel model;

  _ScheduleBlock({
    required this.id,
    required this.subjectName,
    required this.classroom,
    required this.dayIndex,
    required this.startHour,
    required this.endHour,
    required this.color,
    required this.model,
  });
}
