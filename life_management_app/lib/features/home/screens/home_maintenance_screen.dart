import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final maintenanceProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('home_maintenance');
});

class HomeMaintenanceScreen extends ConsumerWidget {
  const HomeMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(maintenanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home Maintenance')),
      body: tasksAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (tasks) {
          if (tasks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.home_repair_service,
              subtitle: 'No maintenance tasks',
              actionLabel: 'Add Task',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final pending = tasks.where((t) => t['status'] == 'pending').toList();
          final completed = tasks.where((t) => t['status'] == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                const Text('Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...pending.map((task) => _buildTaskCard(context, ref, task, false)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                const Text('Completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...completed.map((task) => _buildTaskCard(context, ref, task, true)),
              ],
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Map<String, dynamic> task, bool isCompleted) {
    final name = task['task_name']?.toString() ?? 'Unknown';
    final dueDate = task['due_date'] != null ? DateTime.parse(task['due_date'].toString()) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) async {
            await DatabaseService().update('home_maintenance', task['id']?.toString() ?? '', {
              'status': value == true ? 'completed' : 'pending',
            });
          ),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: dueDate != null ? Text('Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}') : null,
        onLongPress: () async {
          await DatabaseService().delete('home_maintenance', task['id']?.toString() ?? '');
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Maintenance Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Task Name')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dueDate == null ? 'Due Date (Optional)' : DateFormat('MMM dd, yyyy').format(dueDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => dueDate = date);
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('home_maintenance', {
                  'task_name': nameController.text,
                  'due_date': dueDate?.toIso8601String(),
                  'status': 'pending',
                });
                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
