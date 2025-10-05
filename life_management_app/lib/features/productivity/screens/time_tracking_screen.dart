import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final timeTrackingProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('time_tracking');
});

class TimeTrackingScreen extends ConsumerStatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  ConsumerState<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends ConsumerState<TimeTrackingScreen> {
  DateTime? activeStartTime;
  String? activeTask;

  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(timeTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {},
          ),
        ],
      ),
      body: trackingAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (entries) {
          final todayEntries = entries.where((e) {
            final date = e['start_time'] != null ? DateTime.parse(e['start_time'].toString()) : null;
            final today = DateTime.now();
            return date != null && date.year == today.year && date.month == today.month && date.day == today.day;
          }).toList();

          final todayTotal = todayEntries.fold<double>(0, (sum, e) => sum + ((e['duration'] as num?)?.toDouble() ?? 0));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildActiveTimer(),
              const SizedBox(height: 16),
              _buildTodaySummary(context, todayTotal, todayEntries.length),
              const SizedBox(height: 16),
              _buildWeeklyChart(context, entries),
              const SizedBox(height: 24),
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const EmptyStateWidget(icon: Icons.timer, title: 'No Time Tracked', subtitle: 'No time tracked yet', actionLabel: null)
              else
                ...entries.take(10).map((entry) => _buildTimeEntry(context, entry)),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: activeStartTime == null ? _startTracking : _stopTracking,
        icon: Icon(activeStartTime == null ? Icons.play_arrow : Icons.stop),
        label: Text(activeStartTime == null ? 'Start' : 'Stop'),
      ),
    );
  }

  Widget _buildActiveTimer() {
    if (activeStartTime == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.timer, size: 48, color: Colors.green.shade700),
            const SizedBox(height: 12),
            Text('Tracking: $activeTask', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                final duration = DateTime.now().difference(activeStartTime!);
                final hours = duration.inHours.toString().padLeft(2, '0');
                final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
                final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
                return Text('$hours:$minutes:$seconds', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, double hours, int sessions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(Icons.access_time, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(height: 8),
                Text('${hours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Today', style: TextStyle(color: Colors.grey)),
              ],
            ),
            Column(
              children: [
                Icon(Icons.psychology, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(height: 8),
                Text('$sessions', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Sessions', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<Map<String, dynamic>> entries) {
    final weekData = <int, double>{0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    final now = DateTime.now();

    for (final entry in entries) {
      final date = entry['start_time'] != null ? DateTime.parse(entry['start_time'].toString()) : null;
      if (date != null && now.difference(date).inDays < 7) {
        final dayOfWeek = date.weekday % 7;
        weekData[dayOfWeek] = (weekData[dayOfWeek] ?? 0) + ((entry['duration'] as num?)?.toDouble() ?? 0);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: weekData.entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(toY: e.value, color: Colors.blue, width: 20)],
                  )).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntry(BuildContext context, Map<String, dynamic> entry) {
    final activity = entry['activity']?.toString() ?? 'Unknown';
    final project = entry['project']?.toString();
    final duration = (entry['duration'] as num?)?.toDouble() ?? 0;
    final startTime = entry['start_time'] != null ? DateTime.parse(entry['start_time'].toString()) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${duration.toStringAsFixed(0)}h'),
        ),
        title: Text(activity, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project != null) Text(project),
            if (startTime != null) Text(DateFormat('MMM dd, HH:mm').format(startTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _startTracking() {
    final taskController = TextEditingController();
    final projectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: taskController, decoration: const InputDecoration(labelText: 'Activity/Task')),
            const SizedBox(height: 12),
            TextField(controller: projectController, decoration: const InputDecoration(labelText: 'Project (Optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (taskController.text.isEmpty) return;
              setState(() {
                activeStartTime = DateTime.now();
                activeTask = taskController.text;
              });
              Navigator.pop(context);
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _stopTracking() async {
    if (activeStartTime == null) return;

    final duration = DateTime.now().difference(activeStartTime!).inHours.toDouble() +
        DateTime.now().difference(activeStartTime!).inMinutes.remainder(60) / 60.0;

    await DatabaseService().insert('time_tracking', {
      'activity': activeTask ?? 'Unknown',
      'project': null,
      'start_time': activeStartTime!.toIso8601String(),
      'end_time': DateTime.now().toIso8601String(),
      'duration': duration,
    });

    setState(() {
      activeStartTime = null;
      activeTask = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tracked ${duration.toStringAsFixed(1)} hours'), backgroundColor: Colors.green),
      );
    }
  }
}
