import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final mediaTrackerProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('media_tracker');
});

class MediaTrackerScreen extends ConsumerWidget {
  const MediaTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(mediaTrackerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Media Tracker')),
      body: mediaAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (media) {
          if (media.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.movie,
              subtitle: 'No media tracked',
              actionLabel: 'Add Media',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: media.length,
            itemBuilder: (context, index) {
              final item = media[index];
              final title = item['title']?.toString() ?? 'Unknown';
              final type = item['type']?.toString() ?? 'Movie';
              final status = item['status']?.toString() ?? 'watching';
              final rating = item['rating'] as int? ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(type == 'Movie' ? Icons.movie : Icons.tv)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$type • $status'),
                      if (rating > 0) Row(children: List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < rating ? Colors.amber : Colors.grey))),
                    ],
                  ),
                  onLongPress: () async {
                    await DatabaseService().delete('media_tracker', item['id']?.toString() ?? '');
                  ),
                ),
              );
            ),
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String type = 'Movie';
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Media'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'Movie', child: Text('Movie')),
                  DropdownMenuItem(value: 'TV Show', child: Text('TV Show')),
                  DropdownMenuItem(value: 'Anime', child: Text('Anime')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'Movie'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Rating: '),
                  ...List.generate(5, (i) => IconButton(
                    icon: Icon(Icons.star, color: i < rating ? Colors.amber : Colors.grey),
                    onPressed: () => setState(() => rating = i + 1),
                  )),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                await DatabaseService().insert('media_tracker', {
                  'title': titleController.text,
                  'type': type,
                  'status': 'watching',
                  'rating': rating,
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
