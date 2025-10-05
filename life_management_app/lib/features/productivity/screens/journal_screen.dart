import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final journalEntriesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('journal_entries');
});

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book,
              subtitle: 'Start your journal',
              actionLabel: 'Write Entry',
              onAction: () => _showAddEntryDialog(context, ref),
            );
          }

          final entriesByDate = <String, List<Map<String, dynamic>>>{};
          for (final entry in entries) {
            final date = entry['entry_date'] != null 
                ? DateTime.parse(entry['entry_date'].toString())
                : DateTime.now();
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            if (!entriesByDate.containsKey(dateKey)) {
              entriesByDate[dateKey] = [];
            }
            entriesByDate[dateKey]!.add(entry);
          }

          final sortedDates = entriesByDate.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final date = DateTime.parse(dateKey);
              final dayEntries = entriesByDate[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...dayEntries.map((entry) => _buildJournalCard(context, ref, entry)),
                  const SizedBox(height: 16),
                ],
              );
            ),
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context, ref),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, WidgetRef ref, Map<String, dynamic> entry) {
    final title = entry['title']?.toString() ?? 'Untitled';
    final content = entry['content']?.toString() ?? '';
    final mood = entry['mood']?.toString();

    IconData? moodIcon;
    Color? moodColor;
    if (mood != null) {
      switch (mood.toLowerCase()) {
        case 'happy':
          moodIcon = Icons.sentiment_very_satisfied;
          moodColor = Colors.green;
          break;
        case 'neutral':
          moodIcon = Icons.sentiment_neutral;
          moodColor = Colors.grey;
          break;
        case 'sad':
          moodIcon = Icons.sentiment_dissatisfied;
          moodColor = Colors.blue;
          break;
        case 'anxious':
          moodIcon = Icons.sentiment_very_dissatisfied;
          moodColor = Colors.orange;
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEntryDetails(context, ref, entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  if (moodIcon != null) Icon(moodIcon, color: moodColor, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content.length > 150 ? '${content.substring(0, 150)}...' : content,
                style: const TextStyle(color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String mood = 'neutral';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Journal Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title (Optional)')),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'What\'s on your mind?', border: OutlineInputBorder()),
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mood,
                  decoration: const InputDecoration(labelText: 'How are you feeling?'),
                  items: const [
                    DropdownMenuItem(value: 'happy', child: Row(children: [Icon(Icons.sentiment_very_satisfied, color: Colors.green), SizedBox(width: 8), Text('Happy')])),
                    DropdownMenuItem(value: 'neutral', child: Row(children: [Icon(Icons.sentiment_neutral, color: Colors.grey), SizedBox(width: 8), Text('Neutral')])),
                    DropdownMenuItem(value: 'sad', child: Row(children: [Icon(Icons.sentiment_dissatisfied, color: Colors.blue), SizedBox(width: 8), Text('Sad')])),
                    DropdownMenuItem(value: 'anxious', child: Row(children: [Icon(Icons.sentiment_very_dissatisfied, color: Colors.orange), SizedBox(width: 8), Text('Anxious')])),
                  ],
                  onChanged: (value) => setState(() => mood = value ?? 'neutral'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.isEmpty) return;

                await DatabaseService().insert('journal_entries', {
                  'title': titleController.text.isEmpty ? 'Entry ${DateFormat('MMM dd').format(DateTime.now())}' : titleController.text,
                  'content': contentController.text,
                  'mood': mood,
                  'entry_date': DateTime.now().toIso8601String(),
                });

                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry['title']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry['entry_date'] != null 
                      ? DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.parse(entry['entry_date'].toString()))
                      : '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(entry['content']?.toString() ?? ''),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await DatabaseService().delete('journal_entries', entry['id']?.toString() ?? '');
                      Navigator.pop(context);
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete Entry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
