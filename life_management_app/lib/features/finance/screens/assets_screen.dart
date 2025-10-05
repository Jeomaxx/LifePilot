import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final assetsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('assets');
});

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: assetsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (assets) {
          if (assets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2,
              title: 'No Assets',
              subtitle: 'No assets tracked',
              actionLabel: 'Add Asset',
              onAction: () => _showAddAssetDialog(context, ref),
            );
          }

          final totalValue = assets.fold<double>(0, (sum, a) => sum + ((a['value'] as num?)?.toDouble() ?? 0));
          final assetsByType = <String, List<Map<String, dynamic>>>{};
          
          for (final asset in assets) {
            final type = asset['type']?.toString() ?? 'Other';
            if (!assetsByType.containsKey(type)) {
              assetsByType[type] = [];
            }
            assetsByType[type]!.add(asset);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalValue, assets.length),
              const SizedBox(height: 24),
              ...assetsByType.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map((asset) => _buildAssetCard(context, ref, asset)),
                  const SizedBox(height: 16),
                ],
              )),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssetDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalValue, int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Asset Value', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('\$${totalValue.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$count ${count == 1 ? 'asset' : 'assets'} tracked', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, WidgetRef ref, Map<String, dynamic> asset) {
    final name = asset['name']?.toString() ?? 'Unknown';
    final type = asset['type']?.toString() ?? 'Other';
    final value = (asset['value'] as num?)?.toDouble() ?? 0;
    final purchaseDate = asset['purchase_date'] != null ? DateTime.parse(asset['purchase_date'].toString()) : null;

    IconData icon;
    Color color;
    
    switch (type.toLowerCase()) {
      case 'real estate':
        icon = Icons.home;
        color = Colors.blue;
        break;
      case 'vehicle':
        icon = Icons.directions_car;
        color = Colors.green;
        break;
      case 'electronics':
        icon = Icons.devices;
        color = Colors.purple;
        break;
      case 'jewelry':
        icon = Icons.diamond;
        color = Colors.pink;
        break;
      case 'art':
        icon = Icons.palette;
        color = Colors.orange;
        break;
      default:
        icon = Icons.inventory;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${value.toStringAsFixed(2)}'),
            if (purchaseDate != null) 
              Text('Purchased: ${DateFormat('MMM yyyy').format(purchaseDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showAssetOptions(context, ref, asset),
        ),
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    String assetType = 'Real Estate';
    DateTime? purchaseDate;

    final assetTypes = ['Real Estate', 'Vehicle', 'Electronics', 'Jewelry', 'Art', 'Collectibles', 'Equipment', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Asset Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: assetType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: assetTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setState(() => assetType = value ?? 'Other'),
                ),
                const SizedBox(height: 12),
                TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Current Value'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(purchaseDate == null ? 'Purchase Date (Optional)' : 'Purchased: ${DateFormat('MMM dd, yyyy').format(purchaseDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => purchaseDate = date);
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || valueController.text.isEmpty) return;

                await DatabaseService().insert('assets', {
                  'name': nameController.text,
                  'type': assetType,
                  'value': double.tryParse(valueController.text) ?? 0,
                  'purchase_date': purchaseDate?.toIso8601String(),
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

  void _showAssetOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> asset) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Value'),
              onTap: () {
                Navigator.pop(context);
                _showUpdateValueDialog(context, ref, asset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Asset', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref, asset['id']?.toString() ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateValueDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> asset) {
    final valueController = TextEditingController(text: asset['value']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Asset Value'),
        content: TextField(
          controller: valueController,
          decoration: const InputDecoration(labelText: 'New Value'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newValue = double.tryParse(valueController.text) ?? 0;
              await DatabaseService().update('assets', asset['id']?.toString() ?? '', {'value': newValue});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to remove this asset?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('assets', id);
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
