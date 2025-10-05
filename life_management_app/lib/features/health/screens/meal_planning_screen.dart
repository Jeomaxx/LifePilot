import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final mealPlansProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('meal_plans');
});

class MealPlanningScreen extends ConsumerStatefulWidget {
  const MealPlanningScreen({super.key});

  @override
  ConsumerState<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends ConsumerState<MealPlanningScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(mealPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {},
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (meals) {
          final selectedDayMeals = meals.where((m) {
            final mealDate = m['meal_date'] != null ? DateTime.parse(m['meal_date'].toString()) : null;
            return mealDate != null && 
                mealDate.year == selectedDay.year &&
                mealDate.month == selectedDay.month &&
                mealDate.day == selectedDay.day;
          }).toList();

          return Column(
            children: [
              _buildCalendar(meals),
              const Divider(height: 1),
              Expanded(
                child: selectedDayMeals.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.restaurant,
                        subtitle: 'No meals planned for ${DateFormat('MMM dd').format(selectedDay)}',
                        actionLabel: 'Plan Meal',
                        onAction: () => _showAddMealDialog(context, ref),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildNutritionSummary(context, selectedDayMeals),
                          const SizedBox(height: 16),
                          ...selectedDayMeals.map((meal) => _buildMealCard(context, ref, meal)),
                        ],
                      ),
              ),
            ],
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(List<Map<String, dynamic>> meals) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        calendarFormat: CalendarFormat.week,
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDay = selected;
            focusedDay = focused;
          });
        ),
        eventLoader: (day) {
          return meals.where((m) {
            final mealDate = m['meal_date'] != null ? DateTime.parse(m['meal_date'].toString()) : null;
            return mealDate != null && isSameDay(mealDate, day);
          }).toList();
        ),
      ),
    );
  }

  Widget _buildNutritionSummary(BuildContext context, List<Map<String, dynamic>> meals) {
    final totalCalories = meals.fold<double>(0, (sum, m) => sum + ((m['calories'] as num?)?.toDouble() ?? 0));
    final totalProtein = meals.fold<double>(0, (sum, m) => sum + ((m['protein'] as num?)?.toDouble() ?? 0));
    final totalCarbs = meals.fold<double>(0, (sum, m) => sum + ((m['carbs'] as num?)?.toDouble() ?? 0));
    final totalFat = meals.fold<double>(0, (sum, m) => sum + ((m['fat'] as num?)?.toDouble() ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Totals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientCircle('${totalCalories.toInt()}', 'Calories', Colors.orange),
                _buildNutrientCircle('${totalProtein.toInt()}g', 'Protein', Colors.blue),
                _buildNutrientCircle('${totalCarbs.toInt()}g', 'Carbs', Colors.green),
                _buildNutrientCircle('${totalFat.toInt()}g', 'Fat', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, Map<String, dynamic> meal) {
    final mealType = meal['meal_type']?.toString() ?? 'Meal';
    final name = meal['name']?.toString() ?? 'Unknown';
    final calories = meal['calories'] as int? ?? 0;

    IconData icon;
    Color color;
    
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        icon = Icons.breakfast_dining;
        color = Colors.orange;
        break;
      case 'lunch':
        icon = Icons.lunch_dining;
        color = Colors.blue;
        break;
      case 'dinner':
        icon = Icons.dinner_dining;
        color = Colors.purple;
        break;
      case 'snack':
        icon = Icons.cookie;
        color = Colors.brown;
        break;
      default:
        icon = Icons.restaurant;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$mealType • $calories cal'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await DatabaseService().delete('meal_plans', meal['id']?.toString() ?? '');
          ),
        ),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String mealType = 'Breakfast';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Plan Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: mealType,
                  decoration: const InputDecoration(labelText: 'Meal Type'),
                  items: const [
                    DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                    DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                  ],
                  onChanged: (value) => setState(() => mealType = value ?? 'Breakfast'),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Meal Name')),
                const SizedBox(height: 12),
                TextField(controller: caloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: proteinController, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: carbsController, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: fatController, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                await DatabaseService().insert('meal_plans', {
                  'name': nameController.text,
                  'meal_type': mealType,
                  'meal_date': selectedDay.toIso8601String(),
                  'calories': int.tryParse(caloriesController.text) ?? 0,
                  'protein': double.tryParse(proteinController.text) ?? 0,
                  'carbs': double.tryParse(carbsController.text) ?? 0,
                  'fat': double.tryParse(fatController.text) ?? 0,
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
