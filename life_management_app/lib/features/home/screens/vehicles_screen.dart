import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final vehiclesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('vehicles');
});

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Management')),
      body: vehiclesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.directions_car,
              subtitle: 'No vehicles tracked',
              actionLabel: 'Add Vehicle',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final make = vehicle['make']?.toString() ?? '';
              final model = vehicle['model']?.toString() ?? '';
              final year = vehicle['year'] as int? ?? 0;
              final mileage = vehicle['mileage'] as int? ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                  title: Text('$year $make $model', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${NumberFormat('#,###').format(mileage)} miles'),
                  trailing: IconButton(
                    icon: const Icon(Icons.build),
                    onPressed: () => _showMaintenanceDialog(context, ref, vehicle),
                  ),
                  onLongPress: () async {
                    await DatabaseService().delete('vehicles', vehicle['id']?.toString() ?? '');
                  ),
                ),
              );
            ),
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final mileageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: makeController, decoration: const InputDecoration(labelText: 'Make')),
            const SizedBox(height: 12),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model')),
            const SizedBox(height: 12),
            TextField(controller: yearController, decoration: const InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: mileageController, decoration: const InputDecoration(labelText: 'Mileage'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (makeController.text.isEmpty || modelController.text.isEmpty) return;
              await DatabaseService().insert('vehicles', {
                'make': makeController.text,
                'model': modelController.text,
                'year': int.tryParse(yearController.text) ?? DateTime.now().year,
                'mileage': int.tryParse(mileageController.text) ?? 0,
              });
              if (context.mounted) Navigator.pop(context);
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> vehicle) {
    final mileageController = TextEditingController(text: vehicle['mileage']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Mileage'),
        content: TextField(
          controller: mileageController,
          decoration: const InputDecoration(labelText: 'Current Mileage'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().update('vehicles', vehicle['id']?.toString() ?? '', {
                'mileage': int.tryParse(mileageController.text) ?? 0,
              });
              if (context.mounted) Navigator.pop(context);
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
