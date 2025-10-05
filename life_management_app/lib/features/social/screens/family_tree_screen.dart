import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final familyMembersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('family_members');
});

class FamilyTreeScreen extends ConsumerWidget {
  const FamilyTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Tree')),
      body: membersAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (members) {
          if (members.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.people,
              message: 'No family members added',
              actionLabel: 'Add Member',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final membersByRelation = <String, List<Map<String, dynamic>>>{};
          for (final member in members) {
            final relation = member['relationship']?.toString() ?? 'Other';
            if (!membersByRelation.containsKey(relation)) {
              membersByRelation[relation] = [];
            }
            membersByRelation[relation]!.add(member);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: membersByRelation.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...entry.value.map((member) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(member['name']?.toString().substring(0, 1).toUpperCase() ?? '?')),
                    title: Text(member['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(member['phone']?.toString() ?? 'No phone'),
                    onLongPress: () async {
                      await DatabaseService().delete('family_members', member['id']?.toString() ?? '');
                    },
                  ),
                )),
                const SizedBox(height: 16),
              ],
            )).toList(),
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String relationship = 'Parent';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Family Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: relationship,
                items: const [
                  DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                  DropdownMenuItem(value: 'Child', child: Text('Child')),
                  DropdownMenuItem(value: 'Grandparent', child: Text('Grandparent')),
                  DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => relationship = v ?? 'Parent'),
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('family_members', {
                  'name': nameController.text,
                  'relationship': relationship,
                  'phone': phoneController.text,
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
}
