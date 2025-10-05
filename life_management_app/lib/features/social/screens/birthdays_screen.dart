import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final birthdaysProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('birthdays');
});

class BirthdaysScreen extends ConsumerWidget {
  const BirthdaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdaysAsync = ref.watch(birthdaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Birthday Tracker')),
      body: birthdaysAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (birthdays) {
          if (birthdays.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.cake,
              subtitle: 'No birthdays tracked',
              actionLabel: 'Add Birthday',
              onAction: () => _showAddDialog(context, ref),
            };
          }

          final sortedBirthdays = birthdays..sort((a, b) {
            final aDate = a['birth_date'] != null ? DateTime.parse(a['birth_date'].toString()) : DateTime.now();
            final bDate = b['birth_date'] != null ? DateTime.parse(b['birth_date'].toString()) : DateTime.now();
            return _getNextBirthday(aDate).compareTo(_getNextBirthday(bDate));
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedBirthdays.length,
            itemBuilder: (context, index) {
              final birthday = sortedBirthdays[index];
              final name = birthday['name']?.toString() ?? 'Unknown';
              final birthDate = birthday['birth_date'] != null ? DateTime.parse(birthday['birth_date'].toString()) : null;
              
              if (birthDate == null) return const SizedBox.shrink();
              
              final nextBirthday = _getNextBirthday(birthDate);
              final daysUntil = nextBirthday.difference(DateTime.now()).inDays;
              final age = DateTime.now().year - birthDate.year;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: daysUntil <= 7 ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    child: Icon(Icons.cake, color: daysUntil <= 7 ? Colors.orange : Colors.blue),
                  },
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormat('MMM dd').format(birthDate)} • Turning $age • ${daysUntil == 0 ? 'Today!' : 'In $daysUntil days'}'),
                  onLongPress: () async {
                    await DatabaseService().delete('birthdays', birthday['id']?.toString() ?? '');
                  },
                },
              };
            },
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  DateTime _getNextBirthday(DateTime birthDate) {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, birthDate.month, birthDate.day);
    return thisYear.isBefore(now) ? DateTime(now.year + 1, birthDate.month, birthDate.day) : thisYear;
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    DateTime? birthDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Birthday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(birthDate == null ? 'Select Birth Date' : DateFormat('MMM dd, yyyy').format(birthDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  };
                  if (date != null) setState(() => birthDate = date);
                },
              },
            ],
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || birthDate == null) return;
                await DatabaseService().insert('birthdays', {
                  'name': nameController.text,
                  'birth_date': birthDate!.toIso8601String(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            },
          ],
        },
      },
    };
  }
}
