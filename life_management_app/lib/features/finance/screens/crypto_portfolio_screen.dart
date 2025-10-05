import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final cryptoPortfolioProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('crypto_portfolio');
});

final cryptoAlertsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('crypto_alerts');
});

class CryptoPortfolioScreen extends ConsumerWidget {
  const CryptoPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cryptoAsync = ref.watch(cryptoPortfolioProvider);
    final alertsAsync = ref.watch(cryptoAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showAlertsSheet(context, alertsAsync.value ?? []),
          ),
        ],
      ),
      body: cryptoAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (portfolio) {
          if (portfolio.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.currency_bitcoin,
              message: 'No crypto assets yet',
              actionLabel: 'Add Crypto',
              onAction: () => _showAddCryptoDialog(context, ref),
            );
          }

          final totalValue = portfolio.fold<double>(
            0,
            (sum, crypto) {
              final amount = (crypto['amount'] as num?)?.toDouble() ?? 0;
              final price = (crypto['current_price'] as num?)?.toDouble() ?? 0;
              return sum + (amount * price);
            },
          );

          final totalInvested = portfolio.fold<double>(
            0,
            (sum, crypto) {
              final amount = (crypto['amount'] as num?)?.toDouble() ?? 0;
              final purchasePrice = (crypto['purchase_price'] as num?)?.toDouble() ?? 0;
              return sum + (amount * purchasePrice);
            },
          );

          final profitLoss = totalValue - totalInvested;
          final profitLossPercent = totalInvested > 0 ? (profitLoss / totalInvested * 100) : 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalValue, totalInvested, profitLoss, profitLossPercent),
              const SizedBox(height: 24),
              Text(
                'Your Holdings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...portfolio.map((crypto) => _buildCryptoCard(context, ref, crypto)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCryptoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalValue, double invested, double profitLoss, double profitLossPercent) {
    final isProfit = profitLoss >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Portfolio Value', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
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
                      Text('\$${invested.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('P&L', style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)} (${profitLossPercent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: isProfit ? Colors.green : Colors.red,
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
      ),
    );
  }

  Widget _buildCryptoCard(BuildContext context, WidgetRef ref, Map<String, dynamic> crypto) {
    final symbol = crypto['symbol']?.toString().toUpperCase() ?? 'UNKNOWN';
    final amount = (crypto['amount'] as num?)?.toDouble() ?? 0;
    final purchasePrice = (crypto['purchase_price'] as num?)?.toDouble() ?? 0;
    final currentPrice = (crypto['current_price'] as num?)?.toDouble() ?? 0;
    final value = amount * currentPrice;
    final profitLoss = value - (amount * purchasePrice);
    final isProfit = profitLoss >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Text(symbol.substring(0, 1), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ),
        title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${amount.toStringAsFixed(4)} @ \$${currentPrice.toStringAsFixed(2)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
              style: TextStyle(color: isProfit ? Colors.green : Colors.red, fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showCryptoDetails(context, ref, crypto),
        onLongPress: () => _showDeleteDialog(context, ref, crypto['id']?.toString() ?? ''),
      ),
    );
  }

  void _showAddCryptoDialog(BuildContext context, WidgetRef ref) {
    final symbolController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Crypto Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: symbolController, decoration: const InputDecoration(labelText: 'Symbol (BTC, ETH, etc.)'), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 12),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Purchase Price (USD)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (symbolController.text.isEmpty || amountController.text.isEmpty) return;

              final amount = double.tryParse(amountController.text) ?? 0;
              final purchasePrice = double.tryParse(priceController.text) ?? 0;

              await DatabaseService().insert('crypto_portfolio', {
                'symbol': symbolController.text.toUpperCase(),
                'amount': amount,
                'purchase_price': purchasePrice,
                'current_price': purchasePrice,
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCryptoDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> crypto) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${crypto['symbol']} Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildDetailRow('Amount', '${(crypto['amount'] as num?)?.toDouble().toStringAsFixed(4) ?? '0'}'),
            _buildDetailRow('Purchase Price', '\$${(crypto['purchase_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0'}'),
            _buildDetailRow('Current Price', '\$${(crypto['current_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0'}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSetAlertDialog(context, ref, crypto['symbol']?.toString() ?? ''),
                child: const Text('Set Price Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSetAlertDialog(BuildContext context, WidgetRef ref, String symbol) {
    final priceController = TextEditingController();
    String condition = 'above';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Alert for $symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Target Price'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: const [
                DropdownMenuItem(value: 'above', child: Text('Price Above')),
                DropdownMenuItem(value: 'below', child: Text('Price Below')),
              ],
              onChanged: (value) => condition = value ?? 'above',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isEmpty) return;
              
              await DatabaseService().insert('crypto_alerts', {
                'symbol': symbol,
                'target_price': double.tryParse(priceController.text) ?? 0,
                'condition': condition,
                'triggered': false,
              });

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }

  void _showAlertsSheet(BuildContext context, List<Map<String, dynamic>> alerts) {
    showModalBottomSheet(
      context: context,
      builder: (context) => alerts.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No alerts set')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return ListTile(
                  leading: Icon(Icons.notifications_active, color: (alert['triggered'] as bool? ?? false) ? Colors.orange : Colors.grey),
                  title: Text('${alert['symbol']} ${alert['condition']} \$${alert['target_price']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await DatabaseService().delete('crypto_alerts', alert['id']?.toString() ?? '');
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Crypto Asset'),
        content: const Text('Are you sure you want to remove this asset from your portfolio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('crypto_portfolio', id);
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
