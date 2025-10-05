import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final contactsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('contacts');
});

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: contactsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (contacts) {
          if (contacts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.contacts,
              message: 'No contacts yet',
              actionLabel: 'Add Contact',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final name = contact['name']?.toString() ?? 'Unknown';
              final phone = contact['phone']?.toString();
              final email = contact['email']?.toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (phone != null) Text(phone),
                      if (email != null) Text(email, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  onLongPress: () async {
                    await DatabaseService().delete('contacts', contact['id']?.toString() ?? '');
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await DatabaseService().insert('contacts', {
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
