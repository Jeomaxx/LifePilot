import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final medicalHistoryProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('medical_history');
});

class MedicalHistoryScreen extends ConsumerWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicalAsync = ref.watch(medicalHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital_outlined),
            onPressed: () {},
          },
        ],
      },
      body: medicalAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (records) {
          if (records.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.medical_services,
              title: 'No Medical Records',
              subtitle: 'No medical records',
              actionLabel: 'Add Record',
              onAction: () => _showAddRecordDialog(context, ref),
            };
          }

          final recordsByType = <String, List<Map<String, dynamic>>>{};
          for (final record in records) {
            final type = record['type']?.toString() ?? 'Other';
            if (!recordsByType.containsKey(type)) {
              recordsByType[type] = [];
            }
            recordsByType[type]!.add(record);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHealthSummary(context, records),
              const SizedBox(height: 24),
              ...recordsByType.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  },
                  const SizedBox(height: 12),
                  ...entry.value.map((record) => _buildRecordCard(context, ref, record)),
                  const SizedBox(height: 16),
                ],
              )),
            ],
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  Widget _buildHealthSummary(BuildContext context, List<Map<String, dynamic>> records) {
    final conditions = records.where((r) => r['type'] == 'Condition').length;
    final medications = records.where((r) => r['type'] == 'Medication').length;
    final allergies = records.where((r) => r['type'] == 'Allergy').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(Icons.healing, '$conditions', 'Conditions', Colors.blue),
            _buildSummaryItem(Icons.medication, '$medications', 'Meds', Colors.green),
            _buildSummaryItem(Icons.warning_amber, '$allergies', 'Allergies', Colors.orange),
          ],
        },
      },
    };
  }

  Widget _buildSummaryItem(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    };
  }

  Widget _buildRecordCard(BuildContext context, WidgetRef ref, Map<String, dynamic> record) {
    final type = record['type']?.toString() ?? 'Other';
    final name = record['name']?.toString() ?? 'Unknown';
    final description = record['description']?.toString();
    final date = record['date'] != null ? DateTime.parse(record['date'].toString()) : null;

    IconData icon;
    Color color;
    
    switch (type.toLowerCase()) {
      case 'condition':
        icon = Icons.healing;
        color = Colors.blue;
        break;
      case 'medication':
        icon = Icons.medication;
        color = Colors.green;
        break;
      case 'allergy':
        icon = Icons.warning_amber;
        color = Colors.orange;
        break;
      case 'surgery':
        icon = Icons.medical_services;
        color = Colors.red;
        break;
      case 'vaccination':
        icon = Icons.vaccines;
        color = Colors.purple;
        break;
      default:
        icon = Icons.note_add;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        },
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (date != null) Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        },
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showRecordOptions(context, ref, record),
        },
      },
    };
  }

  void _showAddRecordDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String recordType = 'Condition';
    DateTime? recordDate;

    final types = ['Condition', 'Medication', 'Allergy', 'Surgery', 'Vaccination', 'Test Result', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Medical Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: recordType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setState(() => recordType = value ?? 'Condition'),
                },
                const SizedBox(height: 12),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name/Title')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description/Notes'), maxLines: 3),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(recordDate == null ? 'Date (Optional)' : 'Date: ${DateFormat('MMM dd, yyyy').format(recordDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    };
                    if (date != null) setState(() => recordDate = date);
                  },
                },
              ],
            },
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                await DatabaseService().insert('medical_history', {
                  'type': recordType,
                  'name': nameController.text,
                  'description': descController.text,
                  'date': recordDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
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

  void _showRecordOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showRecordDetails(context, record);
              },
            },
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Record', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await DatabaseService().delete('medical_history', record['id']?.toString() ?? '');
                if (context.mounted) Navigator.pop(context);
              },
            },
          ],
        },
      },
    };
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record['name']?.toString() ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', record['type']?.toString() ?? ''),
            if (record['description'] != null) _buildDetailRow('Description', record['description'].toString()),
            if (record['date'] != null) _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(DateTime.parse(record['date'].toString()))),
          ],
        },
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      },
    };
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      },
    };
  }
}
