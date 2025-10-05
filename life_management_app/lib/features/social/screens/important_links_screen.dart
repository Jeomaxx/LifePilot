import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final linksProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('important_links');
});

class ImportantLinksScreen extends ConsumerWidget {
  const ImportantLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Important Links')),
      body: linksAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (links) {
          if (links.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.link,
              subtitle: 'No links saved',
              actionLabel: 'Add Link',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final linksByCategory = <String, List<Map<String, dynamic>>>{};
          for (final link in links) {
            final category = link['category']?.toString() ?? 'Other';
            if (!linksByCategory.containsKey(category)) {
              linksByCategory[category] = [];
            }
            linksByCategory[category]!.add(link);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: linksByCategory.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...entry.value.map((link) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.link)),
                    title: Text(link['title']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(link['url']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _launchUrl(link['url']?.toString() ?? ''),
                    ),
                    onLongPress: () async {
                      await DatabaseService().delete('important_links', link['id']?.toString() ?? '');
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            )).toList(),
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String category = 'Work';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Work', child: Text('Work')),
                  DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'Learning', child: Text('Learning')),
                  DropdownMenuItem(value: 'Tools', child: Text('Tools')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'Work'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || urlController.text.isEmpty) return;
                await DatabaseService().insert('important_links', {
                  'title': titleController.text,
                  'url': urlController.text,
                  'category': category,
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
