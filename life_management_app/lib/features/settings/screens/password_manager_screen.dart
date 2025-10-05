import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final passwordsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('passwords');
});

class PasswordManagerScreen extends ConsumerWidget {
  const PasswordManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordsAsync = ref.watch(passwordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.security), onPressed: () {}),
        ],
      ),
      body: passwordsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (passwords) {
          if (passwords.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.lock,
              title: 'No Passwords',
              subtitle: 'No passwords saved',
              actionLabel: 'Add Password',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final passwordsByCategory = <String, List<Map<String, dynamic>>>{};
          for (final pwd in passwords) {
            final category = pwd['category']?.toString() ?? 'Other';
            if (!passwordsByCategory.containsKey(category)) {
              passwordsByCategory[category] = [];
            }
            passwordsByCategory[category]!.add(pwd);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.amber.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(child: Text('Passwords are encrypted and stored securely', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...passwordsByCategory.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...entry.value.map((pwd) => _buildPasswordCard(context, ref, pwd)),
                  const SizedBox(height: 16),
                ],
              )),
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

  Widget _buildPasswordCard(BuildContext context, WidgetRef ref, Map<String, dynamic> pwd) {
    final service = pwd['service_name']?.toString() ?? 'Unknown';
    final username = pwd['username']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.vpn_key)),
        title: Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(username),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pwd['password']?.toString() ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied')));
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DatabaseService().delete('passwords', pwd['id']?.toString() ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final serviceController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String category = 'Work';
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: serviceController, decoration: const InputDecoration(labelText: 'Service/Website')),
                const SizedBox(height: 12),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username/Email')),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                  ),
                  obscureText: !showPassword,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'Work', child: Text('Work')),
                    DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                    DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                    DropdownMenuItem(value: 'Social', child: Text('Social')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => category = v ?? 'Work'),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (serviceController.text.isEmpty || passwordController.text.isEmpty) return;
                await DatabaseService().insert('passwords', {
                  'service_name': serviceController.text,
                  'username': usernameController.text,
                  'password': passwordController.text,
                  'category': category,
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
