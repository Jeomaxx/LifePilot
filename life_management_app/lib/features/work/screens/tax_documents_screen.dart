import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final taxDocumentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('tax_documents');
});

class TaxDocumentsScreen extends ConsumerWidget {
  const TaxDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(taxDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tax Documents')),
      body: docsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (docs) {
          if (docs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Tax Documents',
              subtitle: 'No tax documents',
              actionLabel: 'Add Document',
              onAction: () => _showAddDialog(context, ref),
            };
          }

          final docsByYear = <int, List<Map<String, dynamic>>>{};
          for (final doc in docs) {
            final year = doc['tax_year'] as int? ?? DateTime.now().year;
            if (!docsByYear.containsKey(year)) {
              docsByYear[year] = [];
            }
            docsByYear[year]!.add(doc);
          }

          final sortedYears = docsByYear.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: sortedYears.map((year) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tax Year $year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...docsByYear[year]!.map((doc) => _buildDocCard(context, ref, doc)),
                const SizedBox(height: 16),
              ],
            )).toList(),
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  Widget _buildDocCard(BuildContext context, WidgetRef ref, Map<String, dynamic> doc) {
    final name = doc['document_name']?.toString() ?? 'Unknown';
    final type = doc['document_type']?.toString() ?? 'Other';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.description)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(type),
        onLongPress: () async {
          await DatabaseService().delete('tax_documents', doc['id']?.toString() ?? '');
        },
      },
    };
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int taxYear = DateTime.now().year;
    String docType = 'W-2';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Tax Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Document Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: docType,
                items: const [
                  DropdownMenuItem(value: 'W-2', child: Text('W-2')),
                  DropdownMenuItem(value: '1099', child: Text('1099')),
                  DropdownMenuItem(value: 'Tax Return', child: Text('Tax Return')),
                  DropdownMenuItem(value: 'Receipt', child: Text('Receipt')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => docType = v ?? 'W-2'),
                decoration: const InputDecoration(labelText: 'Type'),
              },
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: taxYear,
                items: List.generate(10, (i) => DateTime.now().year - i).map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
                onChanged: (v) => setState(() => taxYear = v ?? DateTime.now().year),
                decoration: const InputDecoration(labelText: 'Tax Year'),
              },
            ],
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('tax_documents', {
                  'document_name': nameController.text,
                  'document_type': docType,
                  'tax_year': taxYear,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            },
          ],
        },
      },
    };
  }
}
