import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final receiptsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('expense_receipts');
});

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Receipts')),
      body: receiptsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (receipts) {
          if (receipts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Receipts',
              subtitle: 'No receipts saved',
              actionLabel: 'Add Receipt',
              onAction: () => _showAddDialog(context, ref),
            };
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              final merchant = receipt['merchant']?.toString() ?? 'Unknown';
              final amount = receipt['amount'] as num? ?? 0;
              final date = receipt['expense_date'] != null ? DateTime.parse(receipt['expense_date'].toString()) : null;
              final category = receipt['category']?.toString() ?? 'Other';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt)),
                  title: Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category),
                      if (date != null) Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontSize: 12)),
                    ],
                  },
                  trailing: Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onLongPress: () async {
                    await DatabaseService().delete('expense_receipts', receipt['id']?.toString() ?? '');
                  },
                },
              };
            },
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Food';
    DateTime? expenseDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Receipt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: merchantController, decoration: const InputDecoration(labelText: 'Merchant')),
              const SizedBox(height: 12),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                  DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                  DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'Food'),
                decoration: const InputDecoration(labelText: 'Category'),
              },
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expenseDate == null ? 'Expense Date' : DateFormat('MMM dd, yyyy').format(expenseDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  };
                  if (date != null) setState(() => expenseDate = date);
                },
              },
            ],
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (merchantController.text.isEmpty || amountController.text.isEmpty || expenseDate == null) return;
                await DatabaseService().insert('expense_receipts', {
                  'merchant': merchantController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'category': category,
                  'expense_date': expenseDate!.toIso8601String(),
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
