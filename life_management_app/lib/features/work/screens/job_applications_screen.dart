import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final jobApplicationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('job_applications');
});

class JobApplicationsScreen extends ConsumerWidget {
  const JobApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Applications')),
      body: jobsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (jobs) {
          if (jobs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.work,
              message: 'No job applications',
              actionLabel: 'Add Application',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final active = jobs.where((j) => j['status'] != 'rejected' && j['status'] != 'accepted').toList();
          final closed = jobs.where((j) => j['status'] == 'rejected' || j['status'] == 'accepted').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const Text('Active Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...active.map((job) => _buildJobCard(context, ref, job)),
                const SizedBox(height: 16),
              ],
              if (closed.isNotEmpty) ...[
                const Text('Closed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...closed.map((job) => _buildJobCard(context, ref, job)),
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

  Widget _buildJobCard(BuildContext context, WidgetRef ref, Map<String, dynamic> job) {
    final company = job['company']?.toString() ?? 'Unknown';
    final position = job['position']?.toString() ?? 'Unknown';
    final status = job['status']?.toString() ?? 'applied';
    final appliedDate = job['applied_date'] != null ? DateTime.parse(job['applied_date'].toString()) : null;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'applied':
        statusColor = Colors.blue;
        break;
      case 'interviewing':
        statusColor = Colors.orange;
        break;
      case 'offered':
        statusColor = Colors.purple;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.work, color: statusColor),
        ),
        title: Text(position, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company),
            Text('Status: $status • ${appliedDate != null ? DateFormat('MMM dd').format(appliedDate) : ''}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'interviewing', child: Text('Mark Interviewing')),
            const PopupMenuItem(value: 'offered', child: Text('Mark Offered')),
            const PopupMenuItem(value: 'accepted', child: Text('Mark Accepted')),
            const PopupMenuItem(value: 'rejected', child: Text('Mark Rejected')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              await DatabaseService().delete('job_applications', job['id']?.toString() ?? '');
            } else {
              await DatabaseService().update('job_applications', job['id']?.toString() ?? '', {'status': value});
            }
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final companyController = TextEditingController();
    final positionController = TextEditingController();
    DateTime? appliedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Job Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company')),
              const SizedBox(height: 12),
              TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Position')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(appliedDate == null ? 'Applied Date' : DateFormat('MMM dd, yyyy').format(appliedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => appliedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (companyController.text.isEmpty || positionController.text.isEmpty) return;
                await DatabaseService().insert('job_applications', {
                  'company': companyController.text,
                  'position': positionController.text,
                  'status': 'applied',
                  'applied_date': (appliedDate ?? DateTime.now()).toIso8601String(),
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
