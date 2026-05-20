import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import 'admin_muscle_group_screen.dart';

class AdminMuscleGroupsScreen extends StatefulWidget {
  const AdminMuscleGroupsScreen({super.key});

  @override
  State<AdminMuscleGroupsScreen> createState() => _AdminMuscleGroupsScreenState();
}

class _AdminMuscleGroupsScreenState extends State<AdminMuscleGroupsScreen> {
  List<SupabaseMuscleGroup> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final groups = await SupabaseService().getAllMuscleGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGroup(SupabaseMuscleGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить группу мышц'),
        content: Text(
          'Удалить группу «${group.name}»? Связанные видео упражнений тоже будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService().deleteMuscleGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Группа «${group.name}» удалена')),
        );
      }
      await _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка удаления: $e. '
              'Проверьте full_portable_setup.sql в Supabase.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'infants':
        return 'Младенцы';
      case 'basic':
        return 'Беременные';
      case 'standard':
        return 'Молодежь';
      case 'gentle':
        return 'Взрослые';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы мышц'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const AdminMuscleGroupScreen(),
            ),
          );
          if (created == true) {
            await _loadGroups();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadGroups,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : _groups.isEmpty
                  ? const Center(child: Text('Группы мышц пока не созданы'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return Card(
                          child: ListTile(
                            title: Text(group.name),
                            subtitle: Text(
                              '${_categoryLabel(group.category)} · ${group.exercises.length} упражн.',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Удалить',
                              onPressed: () => _deleteGroup(group),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
