import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final reflectionsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('daily_reflections');
});

class DailyReflectionsScreen extends ConsumerWidget {
  const DailyReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reflectionsAsync = ref.watch(reflectionsProvider);

    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reflections')),
      body: reflectionsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (reflections) {
          final todayReflection = reflections.where((r) {
            final date = r['reflection_date'] != null ? DateTime.parse(r['reflection_date'].toString()) : null;
            return date != null && DateFormat('yyyy-MM-dd').format(date) == todayKey;
          }).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Reflection', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (todayReflection == null)
                        ElevatedButton(
                          onPressed: () => _showAddDialog(context, ref),
                          child: const Text('Write Today\'s Reflection'),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildReflectionSection('Grateful For', todayReflection['grateful_for']?.toString()),
                            _buildReflectionSection('Highlights', todayReflection['highlights']?.toString()),
                            _buildReflectionSection('Learnings', todayReflection['learnings']?.toString()),
                          ],
                        },
                    ],
                  },
                },
              },
              const SizedBox(height: 24),
              const Text('Past Reflections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...reflections.where((r) => r != todayReflection).take(10).map((r) => _buildReflectionCard(context, ref, r)),
            ],
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.edit),
      },
    };
  }

  Widget _buildReflectionSection(String title, String? content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content ?? 'Not filled', style: const TextStyle(color: Colors.grey)),
        ],
      },
    };
  }

  Widget _buildReflectionCard(BuildContext context, WidgetRef ref, Map<String, dynamic> reflection) {
    final date = reflection['reflection_date'] != null ? DateTime.parse(reflection['reflection_date'].toString()) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
        title: Text(date != null ? DateFormat('EEEE, MMM dd, yyyy').format(date) : 'Unknown Date'),
        subtitle: Text(reflection['grateful_for']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        onLongPress: () async {
          await DatabaseService().delete('daily_reflections', reflection['id']?.toString() ?? '');
        },
      },
    };
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final gratefulController = TextEditingController();
    final highlightsController = TextEditingController();
    final learningsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Reflection'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: gratefulController, decoration: const InputDecoration(labelText: 'What are you grateful for?'), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: highlightsController, decoration: const InputDecoration(labelText: 'Today\'s highlights'), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: learningsController, decoration: const InputDecoration(labelText: 'What did you learn?'), maxLines: 2),
            ],
          },
        },
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().insert('daily_reflections', {
                'grateful_for': gratefulController.text,
                'highlights': highlightsController.text,
                'learnings': learningsController.text,
                'reflection_date': DateTime.now().toIso8601String(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          },
        ],
      },
    };
  }
}
