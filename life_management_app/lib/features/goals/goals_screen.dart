import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GoalCategory { personal, career, health, financial, learning }

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalCategory _selectedCategory = GoalCategory.personal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProgressSummary(),
                const SizedBox(height: 24),
                _buildActiveGoals(),
                const SizedBox(height: 24),
                _buildCompletedGoals(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: GoalCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getCategoryName(category)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ProgressStat(
              value: '8',
              label: 'Active',
              color: Colors.blue,
            ),
            _ProgressStat(
              value: '12',
              label: 'Completed',
              color: Colors.green,
            ),
            _ProgressStat(
              value: '64%',
              label: 'Success Rate',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Goals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _GoalCard(
          title: 'Learn Flutter Development',
          category: 'Learning',
          progress: 0.65,
          deadline: 'Dec 31, 2025',
          color: Colors.purple,
        ),
        _GoalCard(
          title: 'Save \$10,000',
          category: 'Financial',
          progress: 0.42,
          deadline: 'Jun 30, 2026',
          color: Colors.green,
        ),
        _GoalCard(
          title: 'Run a Marathon',
          category: 'Health',
          progress: 0.28,
          deadline: 'Oct 15, 2025',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildCompletedGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Goals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _CompletedGoalTile(
          title: 'Launch Personal Website',
          completedDate: 'Nov 15, 2024',
          icon: Icons.check_circle,
        ),
        _CompletedGoalTile(
          title: 'Read 24 Books',
          completedDate: 'Dec 28, 2024',
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  String _getCategoryName(GoalCategory category) {
    switch (category) {
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.financial:
        return 'Financial';
      case GoalCategory.learning:
        return 'Learning';
    }
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g., Learn Spanish',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GoalCategory>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: GoalCategory.personal,
              items: GoalCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryName(category)),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Target Date',
                hintText: 'MM/DD/YYYY',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal created!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ProgressStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String category;
  final double progress;
  final String deadline;
  final Color color;

  const _GoalCard({
    required this.title,
    required this.category,
    required this.progress,
    required this.deadline,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  deadline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedGoalTile extends StatelessWidget {
  final String title;
  final String completedDate;
  final IconData icon;

  const _CompletedGoalTile({
    required this.title,
    required this.completedDate,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(
          title,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
          ),
        ),
        subtitle: Text('Completed on $completedDate'),
      ),
    );
  }
}
