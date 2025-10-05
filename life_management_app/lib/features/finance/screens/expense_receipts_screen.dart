import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final receiptsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('expense_receipts');
});

class ExpenseReceiptsScreen extends ConsumerWidget {
  const ExpenseReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (receipts) {
          if (receipts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt,
              message: 'No receipts saved',
              actionLabel: 'Add Receipt',
              onAction: () => _showAddReceiptDialog(context, ref),
            );
          }

          final totalAmount = receipts.fold<double>(0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, totalAmount, receipts.length),
              const SizedBox(height: 24),
              Text(
                'All Receipts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...receipts.map((receipt) => _buildReceiptCard(context, ref, receipt)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReceiptDialog(context, ref),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double total, int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Expenses', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$count ${count == 1 ? 'receipt' : 'receipts'} saved', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, WidgetRef ref, Map<String, dynamic> receipt) {
    final merchant = receipt['merchant']?.toString() ?? 'Unknown Merchant';
    final amount = (receipt['amount'] as num?)?.toDouble() ?? 0;
    final category = receipt['category']?.toString() ?? 'Uncategorized';
    final imageUrl = receipt['image_url']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: imageUrl != null && imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(Icons.receipt, size: 50),
                ),
              )
            : const CircleAvatar(
                child: Icon(Icons.receipt),
              ),
        title: Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(category),
        trailing: Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () => _showReceiptDetails(context, ref, receipt),
        onLongPress: () => _showDeleteDialog(context, ref, receipt['id']?.toString() ?? ''),
      ),
    );
  }

  void _showAddReceiptDialog(BuildContext context, WidgetRef ref) {
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Receipt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imagePath != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: const Center(child: Text('Receipt image selected')),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.camera);
                      if (image != null) setState(() => imagePath = image.path);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                const SizedBox(height: 16),
                TextField(controller: merchantController, decoration: const InputDecoration(labelText: 'Merchant Name')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (merchantController.text.isEmpty || amountController.text.isEmpty) return;

                String? uploadedUrl;
                if (imagePath != null) {
                  uploadedUrl = await StorageService().uploadFile(
                    imagePath!,
                    'receipts/${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                }

                await DatabaseService().insert('expense_receipts', {
                  'merchant': merchantController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'category': categoryController.text,
                  'image_url': uploadedUrl,
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        },
      ),
    );
  }

  void _showReceiptDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> receipt) {
    final imageUrl = receipt['image_url']?.toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(Icons.receipt, size: 100),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(24),
                child: Icon(Icons.receipt, size: 100),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(receipt['merchant']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('\$${(receipt['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(receipt['category']?.toString() ?? 'Uncategorized', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('expense_receipts', id);
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
