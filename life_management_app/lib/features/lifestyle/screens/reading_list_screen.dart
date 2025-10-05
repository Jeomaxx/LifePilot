import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final readingListProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('reading_list');
});

class ReadingListScreen extends ConsumerWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(readingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reading List')),
      body: booksAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (books) {
          if (books.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book,
              subtitle: 'No books in your list',
              actionLabel: 'Add Book',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final reading = books.where((b) => b['status'] == 'reading').toList();
          final toRead = books.where((b) => b['status'] == 'to_read').toList();
          final finished = books.where((b) => b['status'] == 'finished').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (reading.isNotEmpty) ...[
                const Text('Currently Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...reading.map((book) => _buildBookCard(context, ref, book)),
                const SizedBox(height: 16),
              ],
              if (toRead.isNotEmpty) ...[
                const Text('Want to Read', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...toRead.map((book) => _buildBookCard(context, ref, book)),
                const SizedBox(height: 16),
              ],
              if (finished.isNotEmpty) ...[
                const Text('Finished', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...finished.map((book) => _buildBookCard(context, ref, book)),
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

  Widget _buildBookCard(BuildContext context, WidgetRef ref, Map<String, dynamic> book) {
    final title = book['title']?.toString() ?? 'Unknown';
    final author = book['author']?.toString() ?? 'Unknown Author';
    final status = book['status']?.toString() ?? 'to_read';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.book)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(author),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'reading', child: Text('Mark as Reading')),
            const PopupMenuItem(value: 'finished', child: Text('Mark as Finished')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              await DatabaseService().delete('reading_list', book['id']?.toString() ?? '');
            } else {
              await DatabaseService().update('reading_list', book['id']?.toString() ?? '', {'status': value});
            }
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Author')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              await DatabaseService().insert('reading_list', {
                'title': titleController.text,
                'author': authorController.text,
                'status': 'to_read',
              });
              if (context.mounted) Navigator.pop(context);
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
