import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final travelLogsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('travel_logs');
});

class TravelPlannerScreen extends ConsumerWidget {
  const TravelPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(travelLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Planner')),
      body: tripsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (trips) {
          if (trips.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.flight,
              title: 'No Trips',
              subtitle: 'No trips planned',
              actionLabel: 'Plan Trip',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final upcoming = trips.where((t) {
            final start = t['start_date'] != null ? DateTime.parse(t['start_date'].toString()) : null;
            return start != null && start.isAfter(DateTime.now());
          }).toList();
          final past = trips.where((t) {
            final start = t['start_date'] != null ? DateTime.parse(t['start_date'].toString()) : null;
            return start != null && start.isBefore(DateTime.now());
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Text('Upcoming Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...upcoming.map((trip) => _buildTripCard(context, ref, trip, true)),
                const SizedBox(height: 16),
              ],
              if (past.isNotEmpty) ...[
                const Text('Past Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...past.map((trip) => _buildTripCard(context, ref, trip, false)),
              ],
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, WidgetRef ref, Map<String, dynamic> trip, bool isUpcoming) {
    final destination = trip['destination']?.toString() ?? 'Unknown';
    final startDate = trip['start_date'] != null ? DateTime.parse(trip['start_date'].toString()) : null;
    final endDate = trip['end_date'] != null ? DateTime.parse(trip['end_date'].toString()) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUpcoming ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(Icons.flight, color: isUpcoming ? Colors.blue : Colors.grey),
        ),
        title: Text(destination, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: startDate != null && endDate != null
            ? Text('${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}')
            : null,
        onLongPress: () async {
          await DatabaseService().delete('travel_logs', trip['id']?.toString() ?? '');
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final destinationController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Plan Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: destinationController, decoration: const InputDecoration(labelText: 'Destination')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startDate == null ? 'Start Date' : DateFormat('MMM dd, yyyy').format(startDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(endDate == null ? 'End Date' : DateFormat('MMM dd, yyyy').format(endDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (destinationController.text.isEmpty || startDate == null || endDate == null) return;
                await DatabaseService().insert('travel_logs', {
                  'destination': destinationController.text,
                  'start_date': startDate!.toIso8601String(),
                  'end_date': endDate!.toIso8601String(),
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
}
