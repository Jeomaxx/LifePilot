import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final skillsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('skills');
});

class SkillsDevelopmentScreen extends ConsumerWidget {
  const SkillsDevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skills Development')),
      body: skillsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (skills) {
          if (skills.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.star,
              subtitle: 'No skills tracked',
              actionLabel: 'Add Skill',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final skillsByCategory = <String, List<Map<String, dynamic>>>{};
          for (final skill in skills) {
            final category = skill['category']?.toString() ?? 'Other';
            if (!skillsByCategory.containsKey(category)) {
              skillsByCategory[category] = [];
            }
            skillsByCategory[category]!.add(skill);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: skillsByCategory.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...entry.value.map((skill) => _buildSkillCard(context, ref, skill)),
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

  Widget _buildSkillCard(BuildContext context, WidgetRef ref, Map<String, dynamic> skill) {
    final name = skill['name']?.toString() ?? 'Unknown';
    final level = skill['level'] as int? ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getLevelText(level),
                    style: TextStyle(color: _getLevelColor(level), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: level / 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_getLevelColor(level)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level $level/5', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: () async {
                    if (level < 5) {
                      await DatabaseService().update('skills', skill['id']?.toString() ?? '', {'level': level + 1});
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelText(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Learning';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String category = 'Technical';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Skill Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Technical', child: Text('Technical')),
                  DropdownMenuItem(value: 'Language', child: Text('Language')),
                  DropdownMenuItem(value: 'Soft Skills', child: Text('Soft Skills')),
                  DropdownMenuItem(value: 'Creative', child: Text('Creative')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'Technical'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('skills', {
                  'name': nameController.text,
                  'category': category,
                  'level': 1,
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
