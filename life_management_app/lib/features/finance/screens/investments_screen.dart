import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final investmentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('investments');
});

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: investmentsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (investments) {
          if (investments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.trending_up,
              message: 'No investments yet',
              actionLabel: 'Add Investment',
              onAction: () => _showAddInvestmentDialog(context, ref),
            );
          }

          final totalValue = investments.fold<double>(
            0,
            (sum, inv) => sum + ((inv['current_value'] as num?)?.toDouble() ?? 0),
          );
          final totalInvested = investments.fold<double>(
            0,
            (sum, inv) => sum + ((inv['amount'] as num?)?.toDouble() ?? 0),
          );
          final totalReturns = totalValue - totalInvested;
          final returnsPercent = totalInvested > 0 ? (totalReturns / totalInvested * 100) : 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalValue, totalInvested, totalReturns, returnsPercent),
              const SizedBox(height: 16),
              _buildPerformanceChart(context, investments),
              const SizedBox(height: 24),
              Text(
                'Your Investments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...investments.map((investment) => _buildInvestmentCard(context, ref, investment)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddInvestmentDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalValue, double totalInvested, double returns, double returnsPercent) {
    final isPositive = returns >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Portfolio Value', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '\$${totalValue.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invested', style: Theme.of(context).textTheme.bodySmall),
                    Text('\$${totalInvested.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Returns', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '${isPositive ? '+' : ''}\$${returns.toStringAsFixed(2)} (${returnsPercent.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context, List<Map<String, dynamic>> investments) {
    if (investments.isEmpty) return const SizedBox.shrink();

    final chartData = investments.map((inv) {
      final returns = ((inv['returns'] as num?)?.toDouble() ?? 0);
      return returns;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(
                    chartData.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: chartData[index],
                          color: chartData[index] >= 0 ? Colors.green : Colors.red,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < investments.length) {
                            final name = investments[value.toInt()]['name']?.toString() ?? '';
                            return Text(name.length > 8 ? '${name.substring(0, 8)}...' : name, style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, WidgetRef ref, Map<String, dynamic> investment) {
    final name = investment['name']?.toString() ?? 'Unknown';
    final type = investment['type']?.toString() ?? 'Other';
    final amount = (investment['amount'] as num?)?.toDouble() ?? 0;
    final currentValue = (investment['current_value'] as num?)?.toDouble() ?? 0;
    final returns = (investment['returns'] as num?)?.toDouble() ?? 0;
    final isPositive = returns >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$type • Invested: \$${amount.toStringAsFixed(2)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${currentValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '${isPositive ? '+' : ''}${returns.toStringAsFixed(1)}%',
              style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12),
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(context, ref, investment['id']?.toString() ?? ''),
      ),
    );
  }

  void _showAddInvestmentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'Stocks');
    final amountController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Investment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Investment Name')),
              const SizedBox(height: 12),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type (Stocks, Bonds, Real Estate, etc.)')),
              const SizedBox(height: 12),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount Invested'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Current Value'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || amountController.text.isEmpty) return;
              
              final amount = double.tryParse(amountController.text) ?? 0;
              final currentValue = double.tryParse(valueController.text) ?? amount;
              final returns = amount > 0 ? ((currentValue - amount) / amount * 100) : 0;

              await DatabaseService().insert('investments', {
                'name': nameController.text,
                'type': typeController.text,
                'amount': amount,
                'current_value': currentValue,
                'returns': returns,
              });
              
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: const Text('Are you sure you want to delete this investment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('investments', id);
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
