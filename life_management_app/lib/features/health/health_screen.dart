import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'health_provider.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/empty_state_widget.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(healthStatsProvider);
    final entriesAsync = ref.watch(healthEntriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {},
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const LoadingWidget(message: 'Loading health data...'),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(healthEntriesProvider),
        ),
        data: (entries) => entries.isEmpty
            ? EmptyStateWidget(
                icon: Icons.favorite,
                title: 'No Health Entries',
                subtitle: 'Start tracking your health metrics',
                onAction: () => _showAddEntryDialog(context),
                actionLabel: 'Add Entry',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  statsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (stats) => _buildQuickStats(stats),
                  ),
                  const SizedBox(height: 24),
                  _buildWeightChart(entries),
                  const SizedBox(height: 24),
                  _buildActivitySummary(),
                  const SizedBox(height: 24),
                  _buildRecentEntries(entries),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Entry'),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.monitor_weight,
            label: 'Weight',
            value: '${stats['weight']} kg',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            label: 'Heart Rate',
            value: '${stats['heartRate']} bpm',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> entries) {
    final weightEntries = entries
        .where((e) => e['type'] == 'weight')
        .take(7)
        .toList()
        .reversed
        .toList();
    
    final spots = weightEntries.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['value'] as num).toDouble(),
      );
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Trend (Last ${spots.length} Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: spots.isEmpty
                  ? const Center(child: Text('No weight data'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _ActivityItem(
              icon: Icons.directions_walk,
              label: 'Steps',
              value: '8,432',
              goal: '10,000',
              progress: 0.84,
            ),
            const SizedBox(height: 12),
            _ActivityItem(
              icon: Icons.local_fire_department,
              label: 'Calories',
              value: '432',
              goal: '500',
              progress: 0.86,
            ),
            const SizedBox(height: 12),
            _ActivityItem(
              icon: Icons.water_drop,
              label: 'Water',
              value: '6',
              goal: '8 glasses',
              progress: 0.75,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(List<Map<String, dynamic>> entries) {
    final recent = entries.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Entries',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...recent.map((entry) => _HealthEntryTile(
          date: _formatDate(entry['created_at'] as String),
          type: _formatType(entry['type'] as String),
          value: entry['value'].toString(),
          icon: _getIconForType(entry['type'] as String),
          onDelete: () async {
            await ref.read(healthNotifierProvider.notifier).deleteEntry(entry['id']);
            ref.invalidate(healthEntriesProvider);
          },
        )),
      ],
    );
  }
  
  String _formatDate(String date) {
    final dt = DateTime.parse(date);
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
  
  String _formatType(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'weight': return Icons.monitor_weight;
      case 'heart_rate': return Icons.favorite;
      case 'blood_pressure': return Icons.favorite;
      case 'sleep': return Icons.bedtime;
      case 'exercise': return Icons.fitness_center;
      default: return Icons.healing;
    }
  }

  void _showAddEntryDialog(BuildContext context) {
    String selectedType = 'weight';
    final valueController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Health Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Entry Type'),
              value: selectedType,
              items: const [
                DropdownMenuItem(value: 'weight', child: Text('Weight (kg)')),
                DropdownMenuItem(value: 'heart_rate', child: Text('Heart Rate (bpm)')),
                DropdownMenuItem(value: 'blood_pressure', child: Text('Blood Pressure')),
                DropdownMenuItem(value: 'sleep', child: Text('Sleep (hours)')),
                DropdownMenuItem(value: 'exercise', child: Text('Exercise (minutes)')),
              ],
              onChanged: (value) => selectedType = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Value'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (valueController.text.isNotEmpty) {
                await ref.read(healthNotifierProvider.notifier).addEntry(
                  type: selectedType,
                  value: double.parse(valueController.text),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(healthEntriesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry saved!')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String goal;
  final double progress;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$value / $goal',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HealthEntryTile extends StatelessWidget {
  final String date;
  final String type;
  final String value;
  final IconData icon;
  final VoidCallback? onDelete;

  const _HealthEntryTile({
    required this.date,
    required this.type,
    required this.value,
    required this.icon,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(type),
        subtitle: Text(date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
