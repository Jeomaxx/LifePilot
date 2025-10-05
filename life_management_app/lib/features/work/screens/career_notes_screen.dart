import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final careerNotesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('notes').asyncMap((notes) async {
    return notes.where((n) => (n['category']?.toString() ?? '').toLowerCase().contains('career')).toList();
  });
});

class CareerNotesScreen extends ConsumerWidget {
  const CareerNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(careerNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Career Notes')),
      body: notesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.sticky_note_2,
              message: 'No career notes',
              actionLabel: 'Add Note',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final title = note['title']?.toString() ?? 'Untitled';
              final content = note['content']?.toString() ?? '';
              final updatedAt = note['updated_at'] != null ? DateTime.parse(note['updated_at'].toString()) : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.note)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (updatedAt != null) Text(DateFormat('MMM dd, yyyy').format(updatedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => _showEditDialog(context, ref, note),
                  onLongPress: () async {
                    await DatabaseService().delete('notes', note['id']?.toString() ?? '');
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Career Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              maxLines: 6,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              await DatabaseService().insert('notes', {
                'title': titleController.text,
                'content': contentController.text,
                'color': 'blue',
                'category': 'career',
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> note) {
    final titleController = TextEditingController(text: note['title']?.toString() ?? '');
    final contentController = TextEditingController(text: note['content']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              maxLines: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await DatabaseService().delete('notes', note['id']?.toString() ?? '');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().update('notes', note['id']?.toString() ?? '', {
                'title': titleController.text,
                'content': contentController.text,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
