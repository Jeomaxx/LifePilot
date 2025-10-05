import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final budgetsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('budgets');
});

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_balance_wallet,
              subtitle: 'No budgets created',
              actionLabel: 'Create Budget',
              onAction: () => _showAddBudgetDialog(context, ref),
            );
          }

          final totalBudget = budgets.fold<double>(0, (sum, b) => sum + ((b['amount'] as num?)?.toDouble() ?? 0));
          final totalSpent = budgets.fold<double>(0, (sum, b) => sum + ((b['spent'] as num?)?.toDouble() ?? 0));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalBudget, totalSpent),
              const SizedBox(height: 16),
              _buildBudgetChart(context, budgets),
              const SizedBox(height: 24),
              Text(
                'Budget Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...budgets.map((budget) => _buildBudgetCard(context, ref, budget)),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double total, double spent) {
    final remaining = total - spent;
    final percentUsed = total > 0 ? (spent / total * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Budget', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(percentUsed > 90 ? Colors.red : percentUsed > 70 ? Colors.orange : Colors.green),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spent: \$${spent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                Text('Remaining: \$${remaining.toStringAsFixed(2)}', style: TextStyle(color: remaining < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetChart(BuildContext context, List<Map<String, dynamic>> budgets) {
    if (budgets.isEmpty) return const SizedBox.shrink();

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.indigo];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(
                    budgets.length > 8 ? 8 : budgets.length,
                    (index) {
                      final budget = budgets[index];
                      final amount = (budget['amount'] as num?)?.toDouble() ?? 0;
                      return PieChartSectionData(
                        value: amount,
                        title: budget['category']?.toString() ?? '',
                        color: colors[index % colors.length],
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    ),
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref, Map<String, dynamic> budget) {
    final category = budget['category']?.toString() ?? 'Unknown';
    final amount = (budget['amount'] as num?)?.toDouble() ?? 0;
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
    final period = budget['period']?.toString() ?? 'monthly';
    final remaining = amount - spent;
    final percentUsed = amount > 0 ? (spent / amount * 100) : 0;

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
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '\$${spent.toStringAsFixed(2)} / \$${amount.toStringAsFixed(2)}',
                  style: TextStyle(color: percentUsed > 100 ? Colors.red : Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentUsed > 100 ? 1.0 : percentUsed / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(percentUsed > 100 ? Colors.red : percentUsed > 90 ? Colors.orange : Colors.green),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(period.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  remaining >= 0 ? '\$${remaining.toStringAsFixed(2)} left' : 'Over by \$${remaining.abs().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: remaining < 0 ? Colors.red : Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    String period = 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category (Food, Transport, etc.)')),
              const SizedBox(height: 12),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Budget Amount'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) => setState(() => period = value ?? 'monthly'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (categoryController.text.isEmpty || amountController.text.isEmpty) return;

                await DatabaseService().insert('budgets', {
                  'category': categoryController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'period': period,
                  'spent': 0,
                });

                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
