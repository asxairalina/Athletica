import 'package:flutter/material.dart';
import 'dart:async';
import '../models/daily_task.dart';
import '../services/task_service.dart';
import '../services/progress_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<DailyTask> _dailyTasks = [];
  bool _isLoading = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _refreshTasks();
    });
  }

  Future<void> _loadDailyTasks() async {
    setState(() {
      _isLoading = true;
    });

    final userChanged = await TaskService.initializeDailyTasks();
    if (userChanged) {
      ProgressService.resetDailyProgress();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _dailyTasks = TaskService.getDailyTasks();
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshTasks();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshTasks() {
    setState(() {
      _dailyTasks = TaskService.getDailyTasks();
    });
  }

  int get _totalExperience {
    return TaskService.getTotalExperience(_dailyTasks);
  }

  int get _completedTasks {
    return _dailyTasks.where((t) => t.isCompleted).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildTasksList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Ежедневные задания',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Выполнено', '$_completedTasks/${_dailyTasks.length}'),
              _buildStat('Опыт', '$_totalExperience XP'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    if (_dailyTasks.isEmpty) {
      return const Center(
        child: Text('На сегодня заданий нет'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dailyTasks.length,
      itemBuilder: (context, index) {
        final task = _dailyTasks[index];
        return TaskCard(
          task: task,
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final DailyTask task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.difficultyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.difficultyText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: task.difficultyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+${task.experience} XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.isCompleted ? Icons.check_circle : Icons.schedule,
                        size: 16,
                        color: task.isCompleted ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.isCompleted ? 'Выполнено' : 'В процессе',
                        style: TextStyle(
                          color: task.isCompleted ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
