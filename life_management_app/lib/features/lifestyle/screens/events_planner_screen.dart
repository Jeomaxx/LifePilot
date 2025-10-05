import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final eventsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('events');
});

class EventsPlannerScreen extends ConsumerWidget {
  const EventsPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events Planner')),
      body: eventsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.event,
              subtitle: 'No events planned',
              actionLabel: 'Add Event',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final sortedEvents = events..sort((a, b) {
            final aDate = a['event_date'] != null ? DateTime.parse(a['event_date'].toString()) : DateTime.now();
            final bDate = b['event_date'] != null ? DateTime.parse(b['event_date'].toString()) : DateTime.now();
            return aDate.compareTo(bDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
              final event = sortedEvents[index];
              final name = event['name']?.toString() ?? 'Unknown';
              final date = event['event_date'] != null ? DateTime.parse(event['event_date'].toString()) : null;
              final location = event['location']?.toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.event)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (date != null) Text(DateFormat('MMM dd, yyyy HH:mm').format(date)),
                      if (location != null) Text(location, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  onLongPress: () async {
                    await DatabaseService().delete('events', event['id']?.toString() ?? '');
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
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? eventDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Event Name')),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(eventDate == null ? 'Event Date & Time' : DateFormat('MMM dd, yyyy HH:mm').format(eventDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || eventDate == null) return;
                await DatabaseService().insert('events', {
                  'name': nameController.text,
                  'location': locationController.text,
                  'event_date': eventDate!.toIso8601String(),
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
}
