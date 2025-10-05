import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final contractsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('contracts');
});

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contract Manager')),
      body: contractsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (contracts) {
          if (contracts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.description,
              title: 'No Contracts',
              subtitle: 'No contracts',
              actionLabel: 'Add Contract',
              onAction: () => _showAddDialog(context, ref),
            };
          }

          final active = contracts.where((c) => c['status'] == 'active').toList();
          final expired = contracts.where((c) => c['status'] == 'expired').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const Text('Active Contracts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...active.map((contract) => _buildContractCard(context, ref, contract, true)),
                const SizedBox(height: 16),
              ],
              if (expired.isNotEmpty) ...[
                const Text('Expired Contracts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...expired.map((contract) => _buildContractCard(context, ref, contract, false)),
              ],
            ],
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  Widget _buildContractCard(BuildContext context, WidgetRef ref, Map<String, dynamic> contract, bool isActive) {
    final name = contract['name']?.toString() ?? 'Unknown';
    final startDate = contract['start_date'] != null ? DateTime.parse(contract['start_date'].toString()) : null;
    final endDate = contract['end_date'] != null ? DateTime.parse(contract['end_date'].toString()) : null;
    final value = contract['value'] as num? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(Icons.assignment, color: isActive ? Colors.green : Colors.grey),
        },
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (value > 0) Text('\$${value.toStringAsFixed(2)}'),
            if (startDate != null && endDate != null)
              Text('${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}', style: const TextStyle(fontSize: 12)),
          ],
        },
        onLongPress: () async {
          await DatabaseService().delete('contracts', contract['id']?.toString() ?? '');
        },
      },
    };
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Contract'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Contract Name')),
                const SizedBox(height: 12),
                TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Value'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startDate == null ? 'Start Date' : DateFormat('MMM dd, yyyy').format(startDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    };
                    if (date != null) setState(() => startDate = date);
                  },
                },
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
                    };
                    if (date != null) setState(() => endDate = date);
                  },
                },
              ],
            },
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || startDate == null || endDate == null) return;
                await DatabaseService().insert('contracts', {
                  'name': nameController.text,
                  'start_date': startDate!.toIso8601String(),
                  'end_date': endDate!.toIso8601String(),
                  'value': double.tryParse(valueController.text) ?? 0,
                  'status': endDate!.isAfter(DateTime.now()) ? 'active' : 'expired',
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
