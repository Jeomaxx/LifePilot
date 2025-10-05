import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final moodTrackingProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('mood_tracking');
});

class MoodTrackingScreen extends ConsumerWidget {
  const MoodTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodAsync = ref.watch(moodTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {},
          ),
        ],
      ),
      body: moodAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (moods) {
          if (moods.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.sentiment_satisfied_alt,
              subtitle: 'Start tracking your mood',
              actionLabel: 'Log Mood',
              onAction: () => _showLogMoodDialog(context, ref),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMoodSummary(context, moods),
              const SizedBox(height: 16),
              _buildWeeklyChart(context, moods),
              const SizedBox(height: 24),
              Text(
                'Recent Entries',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...moods.take(20).map((mood) => _buildMoodCard(context, ref, mood)),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogMoodDialog(context, ref),
        child: const Icon(Icons.add_reaction),
      ),
    );
  }

  Widget _buildMoodSummary(BuildContext context, List<Map<String, dynamic>> moods) {
    final weekMoods = moods.where((m) {
      final date = m['recorded_at'] != null ? DateTime.parse(m['recorded_at'].toString()) : null;
      return date != null && DateTime.now().difference(date).inDays < 7;
    }).toList();

    final avgMood = weekMoods.isEmpty ? 3 : weekMoods.fold<int>(0, (sum, m) => sum + ((m['mood_level'] as int?) ?? 3)) / weekMoods.length;

    String moodText;
    Color moodColor;
    IconData moodIcon;
    
    if (avgMood >= 4) {
      moodText = 'Great';
      moodColor = Colors.green;
      moodIcon = Icons.sentiment_very_satisfied;
    } else if (avgMood >= 3) {
      moodText = 'Good';
      moodColor = Colors.blue;
      moodIcon = Icons.sentiment_satisfied;
    } else if (avgMood >= 2) {
      moodText = 'Okay';
      moodColor = Colors.orange;
      moodIcon = Icons.sentiment_neutral;
    } else {
      moodText = 'Low';
      moodColor = Colors.red;
      moodIcon = Icons.sentiment_dissatisfied;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(moodIcon, size: 64, color: moodColor),
            const SizedBox(height: 12),
            Text('This Week: $moodText', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: moodColor)),
            const SizedBox(height: 8),
            Text('${weekMoods.length} mood ${weekMoods.length == 1 ? 'entry' : 'entries'} logged', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<Map<String, dynamic>> moods) {
    final weekData = <int, List<int>>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      weekData[6 - i] = [];
    }

    for (final mood in moods) {
      final date = mood['recorded_at'] != null ? DateTime.parse(mood['recorded_at'].toString()) : null;
      if (date != null) {
        final daysAgo = now.difference(date).inDays;
        if (daysAgo < 7) {
          final dayIndex = 6 - daysAgo;
          weekData[dayIndex]?.add((mood['mood_level'] as int?) ?? 3);
        }
      }
    }

    final avgData = weekData.map((key, values) {
      final avg = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
      return MapEntry(key, avg);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 Days', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: avgData.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = now.subtract(Duration(days: 6 - value.toInt()));
                          return Text(DateFormat('EEE').format(date), style: const TextStyle(fontSize: 12));
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: 0,
                  maxY: 5,
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

  Widget _buildMoodCard(BuildContext context, WidgetRef ref, Map<String, dynamic> mood) {
    final level = mood['mood_level'] as int? ?? 3;
    final note = mood['note']?.toString();
    final recordedAt = mood['recorded_at'] != null ? DateTime.parse(mood['recorded_at'].toString()) : null;

    IconData icon;
    Color color;
    String label;
    
    switch (level) {
      case 5:
        icon = Icons.sentiment_very_satisfied;
        color = Colors.green;
        label = 'Excellent';
        break;
      case 4:
        icon = Icons.sentiment_satisfied_alt;
        color = Colors.lightGreen;
        label = 'Good';
        break;
      case 3:
        icon = Icons.sentiment_neutral;
        color = Colors.orange;
        label = 'Neutral';
        break;
      case 2:
        icon = Icons.sentiment_dissatisfied;
        color = Colors.deepOrange;
        label = 'Low';
        break;
      case 1:
        icon = Icons.sentiment_very_dissatisfied;
        color = Colors.red;
        label = 'Very Low';
        break;
      default:
        icon = Icons.sentiment_neutral;
        color = Colors.grey;
        label = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note != null && note.isNotEmpty) Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (recordedAt != null) Text(DateFormat('MMM dd, HH:mm').format(recordedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await DatabaseService().delete('mood_tracking', mood['id']?.toString() ?? '');
          ),
        ),
      ),
    );
  }

  void _showLogMoodDialog(BuildContext context, WidgetRef ref) {
    int moodLevel = 3;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('How are you feeling?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 4, 5].map((level) {
                  IconData icon;
                  Color color;
                  
                  switch (level) {
                    case 5:
                      icon = Icons.sentiment_very_satisfied;
                      color = Colors.green;
                      break;
                    case 4:
                      icon = Icons.sentiment_satisfied_alt;
                      color = Colors.lightGreen;
                      break;
                    case 3:
                      icon = Icons.sentiment_neutral;
                      color = Colors.orange;
                      break;
                    case 2:
                      icon = Icons.sentiment_dissatisfied;
                      color = Colors.deepOrange;
                      break;
                    case 1:
                      icon = Icons.sentiment_very_dissatisfied;
                      color = Colors.red;
                      break;
                    default:
                      icon = Icons.sentiment_neutral;
                      color = Colors.grey;
                  }

                  return GestureDetector(
                    onTap: () => setState(() => moodLevel = level),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: moodLevel == level ? color.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 40, color: color),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Add a note (optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().insert('mood_tracking', {
                  'mood_level': moodLevel,
                  'note': noteController.text,
                  'recorded_at': DateTime.now().toIso8601String(),
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
}
