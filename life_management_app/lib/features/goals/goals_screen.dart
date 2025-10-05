import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/empty_state_widget.dart';

final goalsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('goals');
});

final milestonesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('milestones');
});

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final milestonesAsync = ref.watch(milestonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(icon: const Icon(Icons.analytics), onPressed: () {}),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.flag,
              subtitle: 'No goals set',
              actionLabel: 'Create Goal',
              onAction: () => _showAddGoalDialog(context, ref),
            );
          }

          final filteredGoals = selectedCategory == 'all'
              ? goals
              : goals.where((g) => g['category']?.toString().toLowerCase() == selectedCategory).toList();

          final activeGoals = filteredGoals.where((g) => g['status'] == 'active').toList();
          final completedGoals = filteredGoals.where((g) => g['status'] == 'completed').toList();

          return Column(
            children: [
              _buildCategoryTabs(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProgressSummary(context, goals),
                    const SizedBox(height: 24),
                    if (activeGoals.isNotEmpty) ...[
                      Text('Active Goals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...activeGoals.map((goal) => milestonesAsync.when(
                        data: (milestones) => _buildGoalCard(context, ref, goal, milestones),
                        loading: () => _buildGoalCard(context, ref, goal, []),
                        error: (_, __) => _buildGoalCard(context, ref, goal, []),
                      )),
                      const SizedBox(height: 24),
                    ],
                    if (completedGoals.isNotEmpty) ...[
                      Text('Completed Goals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...completedGoals.map((goal) => _buildCompletedGoalTile(context, ref, goal)),
                    ],
                  ],
                ),
              ),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['all', 'personal', 'career', 'health', 'financial', 'learning'];
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.substring(0, 1).toUpperCase() + category.substring(1)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => selectedCategory = category);
              ),
            ),
          );
        ),
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context, List<Map<String, dynamic>> goals) {
    final active = goals.where((g) => g['status'] == 'active').length;
    final completed = goals.where((g) => g['status'] == 'completed').length;
    final total = goals.length;
    final successRate = total > 0 ? (completed / total * 100).toInt() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildProgressStat('$active', 'Active', Colors.blue),
            _buildProgressStat('$completed', 'Completed', Colors.green),
            _buildProgressStat('$successRate%', 'Success Rate', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Map<String, dynamic> goal, List<Map<String, dynamic>> allMilestones) {
    final title = goal['title']?.toString() ?? 'Unknown';
    final category = goal['category']?.toString() ?? 'Personal';
    final targetDate = goal['target_date'] != null ? DateTime.parse(goal['target_date'].toString()) : null;
    final progress = goal['progress'] as num? ?? 0;
    
    final goalMilestones = allMilestones.where((m) => m['goal_id'] == goal['id']).toList();
    final completedMilestones = goalMilestones.where((m) => m['completed'] == true).length;

    Color categoryColor;
    switch (category.toLowerCase()) {
      case 'health':
        categoryColor = Colors.red;
        break;
      case 'career':
        categoryColor = Colors.blue;
        break;
      case 'financial':
        categoryColor = Colors.green;
        break;
      case 'learning':
        categoryColor = Colors.purple;
        break;
      default:
        categoryColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showGoalDetails(context, ref, goal, goalMilestones),
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
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showGoalOptions(context, ref, goal),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(categoryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${progress.toInt()}%', style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (targetDate != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM dd, yyyy').format(targetDate), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  if (goalMilestones.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$completedMilestones/${goalMilestones.length} milestones', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedGoalTile(BuildContext context, WidgetRef ref, Map<String, dynamic> goal) {
    final title = goal['title']?.toString() ?? 'Unknown';
    final completedAt = goal['completed_at'] != null ? DateTime.parse(goal['completed_at'].toString()) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(title, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
        subtitle: completedAt != null ? Text('Completed on ${DateFormat('MMM dd, yyyy').format(completedAt)}') : null,
        onLongPress: () async {
          await DatabaseService().delete('goals', goal['id']?.toString() ?? '');
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'personal';
    DateTime? targetDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Goal Title')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'personal', child: Text('Personal')),
                    DropdownMenuItem(value: 'career', child: Text('Career')),
                    DropdownMenuItem(value: 'health', child: Text('Health')),
                    DropdownMenuItem(value: 'financial', child: Text('Financial')),
                    DropdownMenuItem(value: 'learning', child: Text('Learning')),
                  ],
                  onChanged: (v) => setState(() => category = v ?? 'personal'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(targetDate == null ? 'Target Date' : DateFormat('MMM dd, yyyy').format(targetDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) setState(() => targetDate = date);
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || targetDate == null) return;
                await DatabaseService().insert('goals', {
                  'title': titleController.text,
                  'description': descController.text,
                  'category': category,
                  'target_date': targetDate!.toIso8601String(),
                  'progress': 0,
                  'status': 'active',
                });
                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> goal, List<Map<String, dynamic>> milestones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: Text(goal['title']?.toString() ?? ''),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (goal['description'] != null) ...[
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(goal['description'].toString()),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Milestones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showAddMilestoneDialog(context, ref, goal['id']?.toString() ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (milestones.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No milestones yet', style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    ...milestones.map((milestone) => CheckboxListTile(
                      title: Text(milestone['title']?.toString() ?? 'Unknown'),
                      value: milestone['completed'] == true,
                      onChanged: (value) async {
                        await DatabaseService().update('milestones', milestone['id']?.toString() ?? '', {'completed': value});
                        _updateGoalProgress(ref, goal['id']?.toString() ?? '', milestones);
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, WidgetRef ref, String goalId) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Milestone'),
        content: TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Milestone Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              await DatabaseService().insert('milestones', {
                'goal_id': goalId,
                'title': titleController.text,
                'completed': false,
              });
              if (context.mounted) Navigator.pop(context);
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGoalProgress(WidgetRef ref, String goalId, List<Map<String, dynamic>> milestones) async {
    if (milestones.isEmpty) return;
    
    final completed = milestones.where((m) => m['completed'] == true).length;
    final progress = (completed / milestones.length * 100).toInt();
    
    await DatabaseService().update('goals', goalId, {'progress': progress});
    
    if (progress == 100) {
      await DatabaseService().update('goals', goalId, {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      });
    }
  }

  void _showGoalOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Mark as Complete'),
              onTap: () async {
                await DatabaseService().update('goals', goal['id']?.toString() ?? '', {
                  'status': 'completed',
                  'progress': 100,
                  'completed_at': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await DatabaseService().delete('goals', goal['id']?.toString() ?? '');
                Navigator.pop(context);
              ),
            ),
          ],
        ),
      ),
    );
  }
}
