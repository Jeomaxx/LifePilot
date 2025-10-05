import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final hobbiesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('hobbies');
});

class HobbiesTrackerScreen extends ConsumerWidget {
  const HobbiesTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hobbiesAsync = ref.watch(hobbiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hobbies Tracker')),
      body: hobbiesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (hobbies) {
          if (hobbies.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.sports_tennis,
              message: 'No hobbies tracked',
              actionLabel: 'Add Hobby',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: hobbies.length,
            itemBuilder: (context, index) {
              final hobby = hobbies[index];
              final name = hobby['name']?.toString() ?? 'Unknown';
              final category = hobby['category']?.toString() ?? 'Other';

              return Card(
                child: InkWell(
                  onTap: () => _showHobbyDetails(context, ref, hobby),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getIconForCategory(category), size: 48),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        Text(category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
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

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Icons.sports_tennis;
      case 'arts':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'gaming':
        return Icons.videogame_asset;
      case 'cooking':
        return Icons.restaurant;
      default:
        return Icons.interests;
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String category = 'Sports';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Hobby'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Hobby Name')),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                  DropdownMenuItem(value: 'Arts', child: Text('Arts')),
                  DropdownMenuItem(value: 'Music', child: Text('Music')),
                  DropdownMenuItem(value: 'Gaming', child: Text('Gaming')),
                  DropdownMenuItem(value: 'Cooking', child: Text('Cooking')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'Sports'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('hobbies', {
                  'name': nameController.text,
                  'category': category,
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

  void _showHobbyDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> hobby) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hobby['name']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(hobby['category']?.toString() ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await DatabaseService().delete('hobbies', hobby['id']?.toString() ?? '');
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Hobby'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
