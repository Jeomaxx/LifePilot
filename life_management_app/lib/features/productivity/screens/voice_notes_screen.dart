import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final voiceNotesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('voice_notes');
});

class VoiceNotesScreen extends ConsumerStatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  ConsumerState<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends ConsumerState<VoiceNotesScreen> {
  bool isRecording = false;
  DateTime? recordingStartTime;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(voiceNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (isRecording) _buildRecordingIndicator(),
          Expanded(
            child: notesAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => CustomErrorWidget(message: error.toString()),
              data: (notes) {
                if (notes.isEmpty && !isRecording) {
                  return EmptyStateWidget(
                    icon: Icons.mic,
                    title: 'No Voice Notes',
                    subtitle: 'No voice notes yet',
                    actionLabel: 'Record',
                    onAction: _startRecording,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => _buildVoiceNoteCard(context, notes[index]),
                );
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isRecording ? _stopRecording : _startRecording,
        backgroundColor: isRecording ? Colors.red : null,
        child: Icon(isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.red.shade50,
      child: Column(
        children: [
          Icon(Icons.mic, size: 64, color: Colors.red.shade700),
          const SizedBox(height: 12),
          const Text('Recording...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              if (recordingStartTime == null) return const Text('00:00');
              final duration = DateTime.now().difference(recordingStartTime!);
              final minutes = duration.inMinutes.toString().padLeft(2, '0');
              final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
              return Text('$minutes:$seconds', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNoteCard(BuildContext context, Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? 'Voice Note';
    final duration = note['duration'] as int? ?? 0;
    final createdAt = note['created_at'] != null ? DateTime.parse(note['created_at'].toString()) : null;

    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.mic, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: $minutes:$seconds'),
            if (createdAt != null) Text(DateFormat('MMM dd, yyyy HH:mm').format(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playVoiceNote(note),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteVoiceNote(note),
            ),
          ],
        ),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      recordingStartTime = DateTime.now();
    });
  }

  void _stopRecording() async {
    if (recordingStartTime == null) return;

    final duration = DateTime.now().difference(recordingStartTime!).inSeconds;

    final titleController = TextEditingController(text: 'Voice Note ${DateFormat('MMM dd, HH:mm').format(DateTime.now())}');

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Voice Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              Text('Duration: ${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  isRecording = false;
                  recordingStartTime = null;
                });
                Navigator.pop(context);
              ),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().insert('voice_notes', {
                  'title': titleController.text,
                  'file_path': '/mock/path/to/audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
                  'duration': duration,
                  'transcript': null,
                });

                setState(() {
                  isRecording = false;
                  recordingStartTime = null;
                });

                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  void _playVoiceNote(Map<String, dynamic> note) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing: ${note['title']}')),
    );
  }

  void _deleteVoiceNote(Map<String, dynamic> note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Note'),
        content: const Text('Are you sure you want to delete this voice note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().delete('voice_notes', note['id']?.toString() ?? '');
    }
  }
}
