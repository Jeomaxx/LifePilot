import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final socialEventsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('social_events');
});

class SocialEventsScreen extends ConsumerWidget {
  const SocialEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(socialEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Social Events')),
      body: eventsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.group,
              message: 'No social events',
              actionLabel: 'Add Event',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final upcoming = events.where((e) {
            final date = e['event_date'] != null ? DateTime.parse(e['event_date'].toString()) : null;
            return date != null && date.isAfter(DateTime.now());
          }).toList();
          final past = events.where((e) {
            final date = e['event_date'] != null ? DateTime.parse(e['event_date'].toString()) : null;
            return date != null && date.isBefore(DateTime.now());
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...upcoming.map((event) => _buildEventCard(context, ref, event, true)),
                const SizedBox(height: 16),
              ],
              if (past.isNotEmpty) ...[
                const Text('Past Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...past.map((event) => _buildEventCard(context, ref, event, false)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, WidgetRef ref, Map<String, dynamic> event, bool isUpcoming) {
    final name = event['name']?.toString() ?? 'Unknown';
    final date = event['event_date'] != null ? DateTime.parse(event['event_date'].toString()) : null;
    final location = event['location']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUpcoming ? Colors.purple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(Icons.celebration, color: isUpcoming ? Colors.purple : Colors.grey),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date != null) Text(DateFormat('MMM dd, yyyy HH:mm').format(date)),
            if (location != null) Text(location, style: const TextStyle(fontSize: 12)),
          ],
        ),
        onLongPress: () async {
          await DatabaseService().delete('social_events', event['id']?.toString() ?? '');
        },
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
          title: const Text('Add Social Event'),
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
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || eventDate == null) return;
                await DatabaseService().insert('social_events', {
                  'name': nameController.text,
                  'location': locationController.text,
                  'event_date': eventDate!.toIso8601String(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        },
      ),
    );
  }
}
