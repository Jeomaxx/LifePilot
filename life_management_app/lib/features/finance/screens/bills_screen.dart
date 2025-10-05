import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final billsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('bills');
});

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {},
          ),
        ],
      ),
      body: billsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long,
              subtitle: 'No bills tracked',
              actionLabel: 'Add Bill',
              onAction: () => _showAddBillDialog(context, ref),
            );
          }

          final upcomingBills = bills.where((b) => b['status'] == 'pending').toList();
          final paidBills = bills.where((b) => b['status'] == 'paid').toList();

          final totalUpcoming = upcomingBills.fold<double>(
            0,
            (sum, bill) => sum + ((bill['amount'] as num?)?.toDouble() ?? 0),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalUpcoming, upcomingBills.length),
              const SizedBox(height: 24),
              if (upcomingBills.isNotEmpty) ...[
                Text(
                  'Upcoming Bills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...upcomingBills.map((bill) => _buildBillCard(context, ref, bill, true)),
                const SizedBox(height: 24),
              ],
              if (paidBills.isNotEmpty) ...[
                Text(
                  'Paid Bills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...paidBills.map((bill) => _buildBillCard(context, ref, bill, false)),
              ],
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalUpcoming, int billCount) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text('Upcoming Bills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${totalUpcoming.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('$billCount ${billCount == 1 ? 'bill' : 'bills'} to pay', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, WidgetRef ref, Map<String, dynamic> bill, bool isUpcoming) {
    final name = bill['name']?.toString() ?? 'Unknown';
    final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
    final dueDate = bill['due_date'] != null ? DateTime.parse(bill['due_date'].toString()) : null;
    final isRecurring = bill['recurring'] as bool? ?? false;
    final status = bill['status']?.toString() ?? 'pending';

    final daysUntilDue = dueDate?.difference(DateTime.now()).inDays ?? 0;
    final isOverdue = daysUntilDue < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red.withOpacity(0.1) : (isUpcoming ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
          child: Icon(
            isRecurring ? Icons.repeat : Icons.receipt,
            color: isOverdue ? Colors.red : (isUpcoming ? Colors.orange : Colors.green),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${amount.toStringAsFixed(2)}'),
            if (dueDate != null)
              Text(
                isOverdue
                    ? 'Overdue by ${daysUntilDue.abs()} days'
                    : isUpcoming
                        ? 'Due ${daysUntilDue == 0 ? 'today' : 'in $daysUntilDue days'}'
                        : 'Paid on ${DateFormat('MMM dd').format(dueDate)}',
                style: TextStyle(color: isOverdue ? Colors.red : null, fontSize: 12),
              ),
          ],
        ),
        trailing: status == 'pending'
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _markAsPaid(context, ref, bill['id']?.toString() ?? ''),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
        onLongPress: () => _showDeleteDialog(context, ref, bill['id']?.toString() ?? ''),
      ),
    );
  }

  void _showAddBillDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate;
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Bill Name')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null ? 'Select Due Date' : 'Due: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recurring bill'),
                  value: isRecurring,
                  onChanged: (value) => setState(() => isRecurring = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || amountController.text.isEmpty || selectedDate == null) return;

                await DatabaseService().insert('bills', {
                  'name': nameController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'due_date': selectedDate!.toIso8601String(),
                  'status': 'pending',
                  'recurring': isRecurring,
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

  void _markAsPaid(BuildContext context, WidgetRef ref, String id) async {
    await DatabaseService().update('bills', id, {'status': 'paid'});
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to delete this bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('bills', id);
              if (context.mounted) Navigator.pop(context);
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
