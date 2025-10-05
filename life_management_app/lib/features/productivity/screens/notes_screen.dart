import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final notesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('notes');
});

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          },
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {},
          },
        ],
      },
      body: notesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.note,
              title: 'No Notes',
              subtitle: 'No notes yet',
              actionLabel: 'Create Note',
              onAction: () => _showAddNoteDialog(context, ref),
            };
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            },
            itemCount: notes.length,
            itemBuilder: (context, index) => _buildNoteCard(context, ref, notes[index]),
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? 'Untitled';
    final content = note['content']?.toString() ?? '';
    final color = note['color']?.toString() ?? 'blue';
    final updatedAt = note['updated_at'] != null ? DateTime.parse(note['updated_at'].toString()) : null;

    final colors = {
      'blue': Colors.blue.shade50,
      'green': Colors.green.shade50,
      'yellow': Colors.yellow.shade50,
      'pink': Colors.pink.shade50,
      'purple': Colors.purple.shade50,
      'orange': Colors.orange.shade50,
    };

    return Card(
      color: colors[color] ?? Colors.blue.shade50,
      child: InkWell(
        onTap: () => _showEditNoteDialog(context, ref, note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              },
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                },
              },
              if (updatedAt != null) ...[
                const Divider(),
                Text(
                  DateFormat('MMM dd, HH:mm').format(updatedAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                },
              ],
            ],
          },
        },
      },
    };
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                  maxLines: 6,
                },
                const SizedBox(height: 12),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['blue', 'green', 'yellow', 'pink', 'purple', 'orange'].map((color) {
                    final colors = {
                      'blue': Colors.blue,
                      'green': Colors.green,
                      'yellow': Colors.yellow,
                      'pink': Colors.pink,
                      'purple': Colors.purple,
                      'orange': Colors.orange,
                    };
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[color],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          },
                        },
                      },
                    };
                  }).toList(),
                },
              ],
            },
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty && contentController.text.isEmpty) return;

                await DatabaseService().insert('notes', {
                  'title': titleController.text.isEmpty ? 'Note ${DateFormat('MMM dd').format(DateTime.now())}' : titleController.text,
                  'content': contentController.text,
                  'color': selectedColor,
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            },
          ],
        },
      },
    };
  }

  void _showEditNoteDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> note) {
    final titleController = TextEditingController(text: note['title']?.toString() ?? '');
    final contentController = TextEditingController(text: note['content']?.toString() ?? '');
    String selectedColor = note['color']?.toString() ?? 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                  maxLines: 6,
                },
                const SizedBox(height: 12),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['blue', 'green', 'yellow', 'pink', 'purple', 'orange'].map((color) {
                    final colors = {
                      'blue': Colors.blue,
                      'green': Colors.green,
                      'yellow': Colors.yellow,
                      'pink': Colors.pink,
                      'purple': Colors.purple,
                      'orange': Colors.orange,
                    };
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[color],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          },
                        },
                      },
                    };
                  }).toList(),
                },
              ],
            },
          },
          actions: [
            TextButton(
              onPressed: () async {
                await DatabaseService().delete('notes', note['id']?.toString() ?? '');
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            },
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().update('notes', note['id']?.toString() ?? '', {
                  'title': titleController.text,
                  'content': contentController.text,
                  'color': selectedColor,
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            },
          ],
        },
      },
    };
  }
}
