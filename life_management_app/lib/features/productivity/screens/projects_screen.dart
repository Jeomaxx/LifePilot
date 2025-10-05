import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final projectsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('projects');
});

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.work_outline,
              subtitle: 'No projects yet',
              actionLabel: 'Create Project',
              onAction: () => _showAddProjectDialog(context, ref),
            );
          }

          final activeProjects = projects.where((p) => p['status'] == 'active').toList();
          final completedProjects = projects.where((p) => p['status'] == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProjectsSummary(context, activeProjects.length, completedProjects.length),
              const SizedBox(height: 24),
              if (activeProjects.isNotEmpty) ...[
                Text(
                  'Active Projects',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...activeProjects.map((project) => _buildProjectCard(context, ref, project)),
                const SizedBox(height: 24),
              ],
              if (completedProjects.isNotEmpty) ...[
                Text(
                  'Completed Projects',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...completedProjects.map((project) => _buildProjectCard(context, ref, project)),
              ],
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectsSummary(BuildContext context, int active, int completed) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(Icons.work, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(height: 8),
                Text('$active', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Active', style: TextStyle(color: Colors.grey)),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.check_circle, size: 32, color: Colors.green),
                const SizedBox(height: 8),
                Text('$completed', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Completed', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, WidgetRef ref, Map<String, dynamic> project) {
    final name = project['name']?.toString() ?? 'Unknown';
    final description = project['description']?.toString();
    final deadline = project['deadline'] != null ? DateTime.parse(project['deadline'].toString()) : null;
    final progress = project['progress'] as int? ?? 0;
    final status = project['status']?.toString() ?? 'active';

    final daysLeft = deadline?.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft != null && daysLeft < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProjectDetails(context, ref, project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'completed' ? Colors.green : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(status == 'completed' ? Colors.green : Colors.blue),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$progress% complete', style: const TextStyle(fontSize: 12)),
                  if (deadline != null)
                    Text(
                      isOverdue ? 'Overdue by ${daysLeft!.abs()} days' : '$daysLeft days left',
                      style: TextStyle(fontSize: 12, color: isOverdue ? Colors.red : Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Project Name')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(deadline == null ? 'Set Deadline' : 'Deadline: ${DateFormat('MMM dd, yyyy').format(deadline!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => deadline = date);
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                await DatabaseService().insert('projects', {
                  'name': nameController.text,
                  'description': descController.text,
                  'deadline': deadline?.toIso8601String(),
                  'progress': 0,
                  'status': 'active',
                });

                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(project['name']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                if (project['description'] != null) ...[
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(project['description'].toString()),
                  const SizedBox(height: 16),
                ],
                const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Slider(
                  value: (project['progress'] as int? ?? 0).toDouble(),
                  max: 100,
                  divisions: 20,
                  label: '${project['progress']}%',
                  onChanged: (value) async {
                    await DatabaseService().update('projects', project['id']?.toString() ?? '', {'progress': value.toInt()});
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await DatabaseService().update('projects', project['id']?.toString() ?? '', {
                            'status': project['status'] == 'active' ? 'completed' : 'active',
                            'progress': project['status'] == 'active' ? 100 : project['progress'],
                          });
                          Navigator.pop(context);
                        ),
                        child: Text(project['status'] == 'active' ? 'Mark Complete' : 'Reopen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await DatabaseService().delete('projects', project['id']?.toString() ?? '');
                          Navigator.pop(context);
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
