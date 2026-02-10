import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../models/enums.dart'; // Importante para SubjectStatus
import '../../services/auth_service.dart';
import '../../services/local_database_service.dart';

/// Pantalla de detalle de una materia
class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = LocalDatabaseService.instance;
  late TabController _tabController;

  SubjectModel? _subject;
  List<GradePeriodModel> _periods = [];
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final subject = _db.getSubject(widget.subjectId);
    if (subject != null) {
      var periods = _db.getGradePeriods(subject.syncId);
      final events = _db.getEvents(subject.syncId);

      // Si no hay cortes, inicializar los por defecto (Universidad Colombiana típico)
      if (periods.isEmpty) {
        final defaults = [
          GradePeriodModel(
            syncId: const Uuid().v4(),
            subjectId: subject.syncId,
            name: 'Primer Corte',
            percentage: 0.30,
            order: 1,
          ),
          GradePeriodModel(
            syncId: const Uuid().v4(),
            subjectId: subject.syncId,
            name: 'Segundo Corte',
            percentage: 0.35,
            order: 2,
          ),
          GradePeriodModel(
            syncId: const Uuid().v4(),
            subjectId: subject.syncId,
            name: 'Tercer Corte',
            percentage: 0.35,
            order: 3,
          ),
        ];

        for (final p in defaults) {
          await _db.saveGradePeriod(p);
        }
        periods = defaults;
      }

      setState(() {
        _subject = subject;
        _periods = periods;
        _events = events;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _currentGrade {
    double total = 0, pct = 0;
    for (final p in _periods) {
      if (p.obtainedGrade != null) {
        total += p.obtainedGrade! * p.percentage;
        pct += p.percentage;
      }
    }
    return pct > 0 ? total / pct : 0;
  }

  double get _accumulated {
    return _periods
        .where((p) => p.obtainedGrade != null)
        .fold(0.0, (s, p) => s + p.obtainedGrade! * p.percentage);
  }

  double get _required {
    if (_subject == null) return 0;
    final rem = _periods
        .where((p) => p.obtainedGrade == null)
        .fold(0.0, (s, p) => s + p.percentage);
    return rem > 0 ? (_subject!.passingGrade - _accumulated) / rem : 0;
  }

  SubjectStatus get _status {
    if (_subject == null) return SubjectStatus.inProgress;

    if (_periods.every((p) => p.obtainedGrade != null)) {
      return _accumulated >= _subject!.passingGrade
          ? SubjectStatus.approved
          : SubjectStatus.failed;
    }

    // Asumimos escala 0-5
    final maxGrade = AuthService.instance.currentUser?.gradeScaleMax ?? 5.0;

    if (_required > maxGrade) return SubjectStatus.failed;
    if (_required > maxGrade * 0.8) return SubjectStatus.atRisk;
    return SubjectStatus.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_subject == null)
      return const Scaffold(body: Center(child: Text('Materia no encontrada')));

    return Scaffold(
      appBar: AppBar(
        title: Text(_subject!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notas'),
            Tab(text: 'Eventos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_gradesTab(), _eventsTab()],
      ),
    );
  }

  Widget _gradesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryCard(),
          const SizedBox(height: 24),
          _statusCard(),
          const SizedBox(height: 24),
          Text(
            'Cortes de evaluación',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._periods.map((p) => _periodCard(p)),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final completed = _periods
        .where((p) => p.obtainedGrade != null)
        .fold(0.0, (s, p) => s + p.percentage);

    final color = Color(_subject!.colorValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subject!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_subject!.professor != null)
                      Text(
                        _subject!.professor!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _currentGrade.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nota actual',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: completed,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final (color, icon, title, desc) = switch (_status) {
      SubjectStatus.approved => (
        AppTheme.successColor,
        Icons.check_circle,
        '¡Aprobada!',
        'Felicitaciones',
      ),
      SubjectStatus.failed => (
        AppTheme.errorColor,
        Icons.cancel,
        'Reprobada',
        'No se alcanzó el mínimo',
      ),
      SubjectStatus.atRisk => (
        AppTheme.warningColor,
        Icons.warning_amber,
        'En riesgo',
        'Necesitas promediar ${_required.toStringAsFixed(2)} en lo restante',
      ),
      SubjectStatus.inProgress => (
        AppTheme.infoColor,
        Icons.trending_up,
        'En curso',
        'Necesitas promediar ${_required.toStringAsFixed(2)} en lo restante',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(desc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodCard(GradePeriodModel p) {
    final color = Color(_subject!.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Text(
            '${(p.percentage * 100).toInt()}%',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
        title: Text(p.name),
        subtitle: Text(
          p.obtainedGrade != null
              ? 'Puntos: ${(p.obtainedGrade! * p.percentage).toStringAsFixed(2)}'
              : 'Sin calificar',
        ),
        trailing: p.obtainedGrade != null
            ? Text(
                p.obtainedGrade!.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            : TextButton(
                onPressed: () => _editGrade(p),
                child: const Text('Ingresar'),
              ),
        onTap: () => _editGrade(p),
      ),
    );
  }

  void _editGrade(GradePeriodModel p) {
    final maxGrade = AuthService.instance.currentUser?.gradeScaleMax ?? 5.0;

    final gradeCtrl = TextEditingController(
      text: p.obtainedGrade?.toStringAsFixed(1) ?? '',
    );
    final percentageCtrl = TextEditingController(
      text: (p.percentage * 100).toStringAsFixed(0),
    );
    final nameCtrl = TextEditingController(text: p.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Corte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: percentageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje (%)',
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: gradeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nota',
                      suffixText: '/ $maxGrade',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gText = gradeCtrl.text.replaceAll(',', '.').trim();
              final pText = percentageCtrl.text.replaceAll(',', '.').trim();

              final g = gText.isEmpty ? null : double.tryParse(gText);
              final pct = double.tryParse(pText);

              if (pct != null && pct > 0 && pct <= 100) {
                if (g != null && (g < 0 || g > maxGrade)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nota inválida')),
                  );
                  return;
                }

                // Crear copia con nuevos datos
                final updated = GradePeriodModel(
                  syncId: p.syncId,
                  subjectId: p.subjectId,
                  name: nameCtrl.text.isEmpty ? p.name : nameCtrl.text,
                  percentage: pct / 100.0,
                  obtainedGrade: g,
                  order: p.order,
                  dueDate: p.dueDate,
                  createdAt: p.createdAt,
                  updatedAt: DateTime.now(),
                  isSynced: false,
                );

                await _db.saveGradePeriod(updated);

                // Recargar datos
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Porcentaje inválido')),
                );
                return;
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _eventsTab() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Sin eventos para esta materia'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          child: ListTile(
            leading: Icon(
              (event.type == EventType.partial ||
                      event.type == EventType.finalExam)
                  ? Icons.quiz_outlined
                  : Icons.assignment_outlined,
              color: Color(_subject!.colorValue),
            ),
            title: Text(event.title),
            subtitle: Text(
              '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} - ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
    );
  }
}
