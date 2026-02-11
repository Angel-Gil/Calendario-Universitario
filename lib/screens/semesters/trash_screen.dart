import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/local_database_service.dart';
import '../../services/auth_service.dart';

/// Pantalla de papelera - elementos eliminados
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final _db = LocalDatabaseService.instance;
  List<SemesterModel> _deletedSemesters = [];
  List<SubjectModel> _deletedSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  void _loadTrash() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    setState(() {
      _deletedSemesters = _db.getDeletedSemesters(user.uid);
      _deletedSubjects = _db.getDeletedSubjects();
      // Filter out subjects whose parent semester is also deleted (avoid duplicates)
      final deletedSemesterIds = _deletedSemesters.map((s) => s.syncId).toSet();
      _deletedSubjects = _deletedSubjects
          .where((s) => !deletedSemesterIds.contains(s.semesterId))
          .toList();
    });
  }

  bool get _isEmpty => _deletedSemesters.isEmpty && _deletedSubjects.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papelera'),
        actions: [
          if (!_isEmpty)
            TextButton.icon(
              onPressed: _emptyTrash,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Vaciar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La papelera está vacía',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los elementos eliminados aparecerán aquí',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_deletedSemesters.isNotEmpty) ...[
                  Text(
                    'Semestres',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._deletedSemesters.map(
                    (s) => _buildDeletedSemesterCard(context, s),
                  ),
                ],
                if (_deletedSubjects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Materias',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._deletedSubjects.map(
                    (s) => _buildDeletedSubjectCard(context, s),
                  ),
                ],
              ],
            ),
    );
  }

  String _timeAgo(DateTime deletedAt) {
    final diff = DateTime.now().difference(deletedAt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }

  Widget _buildDeletedSemesterCard(
    BuildContext context,
    SemesterModel semester,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_outlined, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semestre ${semester.name}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Eliminado ${_timeAgo(semester.deletedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _permanentlyDeleteSemester(semester),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _restoreSemester(semester),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restaurar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedSubjectCard(BuildContext context, SubjectModel subject) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(subject.colorValue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.book_outlined,
                    color: Color(subject.colorValue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Eliminada ${_timeAgo(subject.deletedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _permanentlyDeleteSubject(subject),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _restoreSubject(subject),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restaurar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _restoreSemester(SemesterModel semester) async {
    await _db.restoreSemester(semester.syncId);
    _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semestre "${semester.name}" restaurado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _restoreSubject(SubjectModel subject) async {
    await _db.restoreSubject(subject.syncId);
    _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Materia "${subject.name}" restaurada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _permanentlyDeleteSemester(SemesterModel semester) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar permanentemente?'),
        content: const Text(
          'Esta acción no se puede deshacer. El semestre y todas sus materias se eliminarán para siempre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar para siempre'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.permanentlyDeleteSemester(semester.syncId);
      _loadTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado permanentemente')),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteSubject(SubjectModel subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar permanentemente?'),
        content: Text(
          'La materia "${subject.name}" se eliminará para siempre con todas sus notas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar para siempre'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.permanentlyDeleteSubject(subject.syncId);
      _loadTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado permanentemente')),
        );
      }
    }
  }

  Future<void> _emptyTrash() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar papelera?'),
        content: const Text(
          'Se eliminarán permanentemente todos los elementos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Vaciar todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await _db.emptyTrash(user.uid);
        _loadTrash();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Papelera vaciada')));
        }
      }
    }
  }
}
