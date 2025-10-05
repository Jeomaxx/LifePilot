import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final plantsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('plants');
});

class PlantCareScreen extends ConsumerWidget {
  const PlantCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Care')),
      body: plantsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (plants) {
          if (plants.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.local_florist,
              title: 'No Plants',
              subtitle: 'No plants tracked',
              actionLabel: 'Add Plant',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              final name = plant['name']?.toString() ?? 'Unknown';
              final species = plant['species']?.toString() ?? '';
              final lastWatered = plant['last_watered'] != null ? DateTime.parse(plant['last_watered'].toString()) : null;
              final wateringFreq = plant['watering_frequency'] as int? ?? 7;

              final daysUntilWater = lastWatered != null 
                  ? wateringFreq - DateTime.now().difference(lastWatered).inDays 
                  : 0;
              final needsWater = daysUntilWater <= 0;

              return Card(
                color: needsWater ? Colors.orange.shade50 : null,
                child: InkWell(
                  onTap: () => _showPlantDetails(context, ref, plant),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_florist, size: 48, color: needsWater ? Colors.orange : Colors.green),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        if (species.isNotEmpty) Text(species, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          needsWater ? 'Water now!' : 'Water in ${daysUntilWater}d',
                          style: TextStyle(
                            fontSize: 12,
                            color: needsWater ? Colors.orange : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final speciesController = TextEditingController();
    int wateringFreq = 7;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Plant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Plant Name')),
              const SizedBox(height: 12),
              TextField(controller: speciesController, decoration: const InputDecoration(labelText: 'Species')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: wateringFreq,
                items: [1, 3, 7, 14, 30].map((days) => DropdownMenuItem(value: days, child: Text('Every $days days'))).toList(),
                onChanged: (v) => setState(() => wateringFreq = v ?? 7),
                decoration: const InputDecoration(labelText: 'Watering Frequency'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('plants', {
                  'name': nameController.text,
                  'species': speciesController.text,
                  'watering_frequency': wateringFreq,
                  'last_watered': DateTime.now().toIso8601String(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> plant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plant['name']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DatabaseService().update('plants', plant['id']?.toString() ?? '', {
                    'last_watered': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.water_drop),
                label: const Text('Mark as Watered'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await DatabaseService().delete('plants', plant['id']?.toString() ?? '');
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Plant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
