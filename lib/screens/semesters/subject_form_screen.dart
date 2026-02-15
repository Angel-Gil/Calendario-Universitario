import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/local_database_service.dart';

/// Pantalla para agregar/editar una materia con horarios
class SubjectFormScreen extends StatefulWidget {
  final String semesterId;
  final SubjectModel? existing;

  const SubjectFormScreen({super.key, required this.semesterId, this.existing});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _db = LocalDatabaseService.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _professorController;
  late TextEditingController _creditsController;
  late TextEditingController _passingGradeController;

  int _selectedColorValue = AppTheme.subjectColors[0].value;
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _professorController = TextEditingController(
      text: widget.existing?.professor ?? '',
    );
    _creditsController = TextEditingController(
      text: widget.existing?.credits?.toString() ?? '',
    );
    _passingGradeController = TextEditingController(
      text: widget.existing?.passingGrade.toString() ?? '3.0',
    );
    _selectedColorValue =
        widget.existing?.colorValue ?? AppTheme.subjectColors[0].value;

    if (widget.existing != null) {
      _schedules = _db.getSchedules(widget.existing!.syncId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professorController.dispose();
    _creditsController.dispose();
    _passingGradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Materia' : 'Nueva Materia'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información básica',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la materia *',
                        hintText: 'Ej: Cálculo Diferencial',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _professorController,
                      decoration: const InputDecoration(
                        labelText: 'Profesor (opcional)',
                        hintText: 'Ej: Dr. Juan Pérez',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _creditsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Créditos',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _passingGradeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nota mínima',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Color', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppTheme.subjectColors
                          .map(
                            (color) => GestureDetector(
                              onTap: () => setState(
                                () => _selectedColorValue = color.value,
                              ),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: _selectedColorValue == color.value
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: _selectedColorValue == color.value
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Horarios
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Horarios de clase',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addSchedule,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                    if (_schedules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Sin horarios agregados',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._schedules.asMap().entries.map(
                        (entry) => _ScheduleTile(
                          schedule: entry.value,
                          onEdit: () => _editSchedule(entry.key),
                          onDelete: () => _removeSchedule(entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Guardar cambios' : 'Crear materia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSchedule() {
    _showScheduleDialog();
  }

  void _editSchedule(int index) {
    _showScheduleDialog(_schedules[index], index);
  }

  void _removeSchedule(int index) {
    setState(() => _schedules.removeAt(index));
  }

  void _showScheduleDialog([ScheduleModel? existing, int? index]) {
    int selectedDay = existing?.dayOfWeek ?? 1;
    TimeOfDay startTime = existing != null
        ? TimeOfDay(
            hour: int.parse(existing.startTime.split(':')[0]),
            minute: int.parse(existing.startTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = existing != null
        ? TimeOfDay(
            hour: int.parse(existing.endTime.split(':')[0]),
            minute: int.parse(existing.endTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 10, minute: 0);
    final classroomController = TextEditingController(
      text: existing?.classroom ?? '',
    );

    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Agregar horario' : 'Editar horario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Día de la semana',
                ),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(value: i + 1, child: Text(days[i])),
                ),
                onChanged: (value) =>
                    setDialogState(() => selectedDay = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null)
                          setDialogState(() => startTime = time);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Hora inicio',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) setDialogState(() => endTime = time);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Hora fin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: classroomController,
                decoration: const InputDecoration(
                  labelText: 'Aula (opcional)',
                  hintText: 'Ej: Salón 301',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final schedule = ScheduleModel(
                  syncId: existing?.syncId ?? const Uuid().v4(),
                  subjectId: widget.existing?.syncId ?? '',
                  dayOfWeek: selectedDay,
                  startTime:
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                  endTime:
                      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  classroom: classroomController.text.isEmpty
                      ? null
                      : classroomController.text,
                );

                setState(() {
                  if (index != null) {
                    _schedules[index] = schedule;
                  } else {
                    _schedules.add(schedule);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final subjectId = widget.existing?.syncId ?? const Uuid().v4();

    final subject = SubjectModel(
      syncId: subjectId,
      semesterId: widget.semesterId,
      name: _nameController.text,
      professor: _professorController.text.isEmpty
          ? null
          : _professorController.text,
      colorValue: _selectedColorValue,
      passingGrade: double.tryParse(_passingGradeController.text) ?? 3.0,
      credits: int.tryParse(_creditsController.text),
      createdAt: widget.existing?.createdAt,
      isSynced: false,
    );

    await _db.saveSubject(subject);

    // Guardar horarios
    if (widget.existing != null) {
      await _db.deleteSchedulesForSubject(subjectId);
    }

    for (final schedule in _schedules) {
      final updatedSchedule = ScheduleModel(
        syncId: schedule.syncId,
        subjectId: subjectId,
        dayOfWeek: schedule.dayOfWeek,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        classroom: schedule.classroom,
        isSynced: false,
      );
      await _db.saveSchedule(updatedSchedule);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _ScheduleTile extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleTile({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            schedule.shortDayName,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text('${schedule.dayName}'),
        subtitle: Text(
          '${schedule.startTime} - ${schedule.endTime}${schedule.classroom != null ? ' • ${schedule.classroom}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: AppTheme.errorColor,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
