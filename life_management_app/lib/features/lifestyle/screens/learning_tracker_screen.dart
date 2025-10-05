import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final learningResourcesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('learning_resources');
});

class LearningTrackerScreen extends ConsumerWidget {
  const LearningTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningAsync = ref.watch(learningResourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Tracker')),
      body: learningAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (resources) {
          if (resources.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.school,
              message: 'No learning resources',
              actionLabel: 'Add Resource',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              final title = resource['title']?.toString() ?? 'Unknown';
              final type = resource['type']?.toString() ?? 'Course';
              final progress = resource['progress'] as int? ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_getIconForType(type))),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type),
                      LinearProgressIndicator(value: progress / 100),
                      Text('$progress% complete'),
                    ],
                  ),
                  onLongPress: () async {
                    await DatabaseService().delete('learning_resources', resource['id']?.toString() ?? '');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'course':
        return Icons.school;
      case 'book':
        return Icons.book;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.article;
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String type = 'Course';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Learning Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'Course', child: Text('Course')),
                  DropdownMenuItem(value: 'Book', child: Text('Book')),
                  DropdownMenuItem(value: 'Video', child: Text('Video')),
                  DropdownMenuItem(value: 'Article', child: Text('Article')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'Course'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                await DatabaseService().insert('learning_resources', {
                  'title': titleController.text,
                  'type': type,
                  'progress': 0,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
