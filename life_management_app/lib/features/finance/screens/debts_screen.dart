import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final debtsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('debts');
});

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: debtsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (debts) {
          if (debts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.money_off,
              title: 'No Debts',
              subtitle: 'No debts tracked',
              actionLabel: 'Add Debt',
              onAction: () => _showAddDebtDialog(context, ref),
            );
          }

          final totalDebt = debts.fold<double>(0, (sum, d) => sum + ((d['amount'] as num?)?.toDouble() ?? 0));
          final totalInterest = debts.fold<double>(0, (sum, d) {
            final amount = (d['amount'] as num?)?.toDouble() ?? 0;
            final rate = (d['interest_rate'] as num?)?.toDouble() ?? 0;
            return sum + (amount * rate / 100);
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalDebt, totalInterest, debts.length),
              const SizedBox(height: 24),
              Text(
                'Your Debts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...debts.map((debt) => _buildDebtCard(context, ref, debt)),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double total, double interest, int count) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('Total Debt', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$count ${count == 1 ? 'debt' : 'debts'}', style: Theme.of(context).textTheme.bodyMedium),
                Text('~\$${interest.toStringAsFixed(2)} annual interest', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, WidgetRef ref, Map<String, dynamic> debt) {
    final creditor = debt['creditor']?.toString() ?? 'Unknown';
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final interestRate = (debt['interest_rate'] as num?)?.toDouble() ?? 0;
    final dueDate = debt['due_date'] != null ? DateTime.parse(debt['due_date'].toString()) : null;

    final monthlyInterest = amount * interestRate / 100 / 12;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: Icon(Icons.credit_card, color: Colors.red.shade700),
        ),
        title: Text(creditor, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${amount.toStringAsFixed(2)} @ ${interestRate.toStringAsFixed(2)}% APR'),
            if (dueDate != null) Text('Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Monthly interest: ~\$${monthlyInterest.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showDebtOptions(context, ref, debt),
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, WidgetRef ref) {
    final creditorController = TextEditingController();
    final amountController = TextEditingController();
    final rateController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: creditorController, decoration: const InputDecoration(labelText: 'Creditor / Lender')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount Owed'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Interest Rate (% APR)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dueDate == null ? 'Due Date (Optional)' : 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) setState(() => dueDate = date);
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (creditorController.text.isEmpty || amountController.text.isEmpty) return;

                await DatabaseService().insert('debts', {
                  'creditor': creditorController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'interest_rate': double.tryParse(rateController.text) ?? 0,
                  'due_date': dueDate?.toIso8601String(),
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

  void _showDebtOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> debt) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Make Payment'),
              onTap: () {
                Navigator.pop(context);
                _showPaymentDialog(context, ref, debt);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Debt', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref, debt['id']?.toString() ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> debt) {
    final paymentController = TextEditingController();
    final currentAmount = (debt['amount'] as num?)?.toDouble() ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current debt: \$${currentAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(controller: paymentController, decoration: const InputDecoration(labelText: 'Payment Amount'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final payment = double.tryParse(paymentController.text) ?? 0;
              if (payment <= 0 || payment > currentAmount) return;

              final newAmount = currentAmount - payment;
              
              if (newAmount <= 0) {
                await DatabaseService().delete('debts', debt['id']?.toString() ?? '');
              } else {
                await DatabaseService().update('debts', debt['id']?.toString() ?? '', {'amount': newAmount});
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text('Are you sure you want to remove this debt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('debts', id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
