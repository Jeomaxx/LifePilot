import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final habitsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('habits');
});

final habitLogsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('habit_logs');
});

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final logsAsync = ref.watch(habitLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showCalendarView(context),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (habits) {
          if (habits.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.repeat,
              message: 'No habits tracked',
              actionLabel: 'Add Habit',
              onAction: () => _showAddHabitDialog(context, ref),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStreakSummary(context, habits),
              const SizedBox(height: 24),
              Text(
                'Today\'s Habits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...habits.map((habit) => _buildHabitCard(context, ref, habit, logsAsync.value ?? [])),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStreakSummary(BuildContext context, List<Map<String, dynamic>> habits) {
    final totalStreak = habits.fold<int>(0, (sum, h) => sum + ((h['streak'] as int?) ?? 0));
    final longestStreak = habits.fold<int>(0, (max, h) {
      final streak = (h['streak'] as int?) ?? 0;
      return streak > max ? streak : max;
    });

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 40),
                  const SizedBox(height: 8),
                  Text('$totalStreak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Total Streaks', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 40),
                  const SizedBox(height: 8),
                  Text('$longestStreak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Best Streak', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, WidgetRef ref, Map<String, dynamic> habit, List<Map<String, dynamic>> logs) {
    final name = habit['name']?.toString() ?? 'Unknown';
    final frequency = habit['frequency']?.toString() ?? 'daily';
    final streak = habit['streak'] as int? ?? 0;
    final lastCompleted = habit['last_completed'] != null ? DateTime.parse(habit['last_completed'].toString()) : null;

    final today = DateTime.now();
    final isCompletedToday = lastCompleted != null && 
        lastCompleted.year == today.year &&
        lastCompleted.month == today.month &&
        lastCompleted.day == today.day;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompletedToday ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: isCompletedToday 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(Icons.repeat, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(frequency),
            const SizedBox(width: 16),
            Icon(Icons.local_fire_department, size: 14, color: streak > 0 ? Colors.orange : Colors.grey),
            const SizedBox(width: 4),
            Text('$streak day${streak == 1 ? '' : 's'}'),
          ],
        ),
        trailing: !isCompletedToday
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => _markAsComplete(context, ref, habit),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
        onLongPress: () => _showHabitOptions(context, ref, habit),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String frequency = 'daily';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Habit Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (value) => setState(() => frequency = value ?? 'daily'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                await DatabaseService().insert('habits', {
                  'name': nameController.text,
                  'frequency': frequency,
                  'streak': 0,
                  'last_completed': null,
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        },
      ),
    );
  }

  void _markAsComplete(BuildContext context, WidgetRef ref, Map<String, dynamic> habit) async {
    final lastCompleted = habit['last_completed'] != null ? DateTime.parse(habit['last_completed'].toString()) : null;
    final currentStreak = habit['streak'] as int? ?? 0;
    
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final isConsecutive = lastCompleted != null &&
        lastCompleted.year == yesterday.year &&
        lastCompleted.month == yesterday.month &&
        lastCompleted.day == yesterday.day;

    final newStreak = isConsecutive ? currentStreak + 1 : 1;

    await DatabaseService().update('habits', habit['id']?.toString() ?? '', {
      'last_completed': DateTime.now().toIso8601String(),
      'streak': newStreak,
    });

    await DatabaseService().insert('habit_logs', {
      'habit_id': habit['id'],
      'completed_at': DateTime.now().toIso8601String(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Habit completed! $newStreak day streak 🔥'), backgroundColor: Colors.green),
      );
    }
  }

  void _showHabitOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> habit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(context);
                _showHabitHistory(context, habit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Habit', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await DatabaseService().delete('habits', habit['id']?.toString() ?? '');
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHabitHistory(BuildContext context, Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${habit['name']} History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Streak: ${habit['streak']} days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Last completed: ${habit['last_completed'] != null ? DateTime.parse(habit['last_completed'].toString()).toString().substring(0, 10) : 'Never'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showCalendarView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Habit Calendar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
