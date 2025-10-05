import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => context.push('/notifications')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push('/user-profile')),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 16),
          _buildQuickStats(context),
          const SizedBox(height: 24),
          _buildModuleCategory(context, 'Financial', _getFinancialModules(), Colors.green),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'Productivity', _getProductivityModules(), Colors.blue),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'Health & Wellness', _getHealthModules(), Colors.red),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'Lifestyle & Learning', _getLifestyleModules(), Colors.purple),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'Social & Contacts', _getSocialModules(), Colors.pink),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'Work & Business', _getWorkModules(), Colors.indigo),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'Home & Living', _getHomeModules(), Colors.brown),
          const SizedBox(height: 16),
          _buildModuleCategory(context, 'System & Tools', _getSystemModules(), Colors.teal),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ai-assistant'),
        child: const Icon(Icons.assistant),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Manage your entire life in one place', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, icon: Icons.check_circle_outline, title: 'Tasks', value: '12', color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, icon: Icons.flag, title: 'Goals', value: '5', color: Colors.purple)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, icon: Icons.local_fire_department, title: 'Streak', value: '7d', color: Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCategory(BuildContext context, String category, List<ModuleItem> modules, Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(category, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => context.push(module.route),
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: module.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(module.icon, color: module.color, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(module.title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<ModuleItem> _getFinancialModules() => [
    ModuleItem(title: 'Finance', icon: Icons.account_balance_wallet, color: Colors.green, route: '/finance'),
    ModuleItem(title: 'Investments', icon: Icons.trending_up, color: Colors.green.shade700, route: '/investments'),
    ModuleItem(title: 'Crypto', icon: Icons.currency_bitcoin, color: Colors.orange, route: '/crypto'),
    ModuleItem(title: 'Bills', icon: Icons.receipt, color: Colors.red, route: '/bills'),
    ModuleItem(title: 'Subscriptions', icon: Icons.subscriptions, color: Colors.purple, route: '/subscriptions'),
    ModuleItem(title: 'Budgets', icon: Icons.pie_chart, color: Colors.blue, route: '/budgets'),
    ModuleItem(title: 'Debts', icon: Icons.credit_card, color: Colors.deepOrange, route: '/debts'),
    ModuleItem(title: 'Assets', icon: Icons.business_center, color: Colors.teal, route: '/assets'),
    ModuleItem(title: 'Receipts', icon: Icons.receipt_long, color: Colors.brown, route: '/receipts'),
  ];

  List<ModuleItem> _getProductivityModules() => [
    ModuleItem(title: 'Tasks', icon: Icons.check_box, color: Colors.blue, route: '/tasks'),
    ModuleItem(title: 'Goals', icon: Icons.flag, color: Colors.purple, route: '/goals'),
    ModuleItem(title: 'Habits', icon: Icons.repeat, color: Colors.orange, route: '/habits'),
    ModuleItem(title: 'Time Track', icon: Icons.timer, color: Colors.cyan, route: '/time-tracking'),
    ModuleItem(title: 'Projects', icon: Icons.work, color: Colors.indigo, route: '/projects'),
    ModuleItem(title: 'Journal', icon: Icons.book, color: Colors.brown, route: '/journal'),
    ModuleItem(title: 'Notes', icon: Icons.note, color: Colors.amber, route: '/notes'),
    ModuleItem(title: 'Voice Notes', icon: Icons.mic, color: Colors.pink, route: '/voice-notes'),
  ];

  List<ModuleItem> _getHealthModules() => [
    ModuleItem(title: 'Health', icon: Icons.favorite, color: Colors.red, route: '/health'),
    ModuleItem(title: 'Medical History', icon: Icons.local_hospital, color: Colors.red.shade700, route: '/medical-history'),
    ModuleItem(title: 'Meal Planning', icon: Icons.restaurant, color: Colors.green, route: '/meal-planning'),
    ModuleItem(title: 'Mood Tracking', icon: Icons.sentiment_satisfied, color: Colors.purple, route: '/mood-tracking'),
  ];

  List<ModuleItem> _getLifestyleModules() => [
    ModuleItem(title: 'Learning', icon: Icons.school, color: Colors.purple, route: '/learning'),
    ModuleItem(title: 'Reading', icon: Icons.menu_book, color: Colors.brown, route: '/reading'),
    ModuleItem(title: 'Media', icon: Icons.movie, color: Colors.indigo, route: '/media'),
    ModuleItem(title: 'Hobbies', icon: Icons.sports_tennis, color: Colors.orange, route: '/hobbies'),
    ModuleItem(title: 'Travel', icon: Icons.flight, color: Colors.blue, route: '/travel'),
    ModuleItem(title: 'Events', icon: Icons.event, color: Colors.pink, route: '/events'),
    ModuleItem(title: 'Reflections', icon: Icons.auto_awesome, color: Colors.deepPurple, route: '/reflections'),
    ModuleItem(title: 'Skills', icon: Icons.star, color: Colors.amber, route: '/skills'),
  ];

  List<ModuleItem> _getSocialModules() => [
    ModuleItem(title: 'Contacts', icon: Icons.contacts, color: Colors.pink, route: '/contacts'),
    ModuleItem(title: 'Birthdays', icon: Icons.cake, color: Colors.orange, route: '/birthdays'),
    ModuleItem(title: 'Family Tree', icon: Icons.people, color: Colors.green, route: '/family-tree'),
    ModuleItem(title: 'Links', icon: Icons.link, color: Colors.blue, route: '/links'),
    ModuleItem(title: 'Social Events', icon: Icons.celebration, color: Colors.purple, route: '/social-events'),
  ];

  List<ModuleItem> _getWorkModules() => [
    ModuleItem(title: 'Job Apps', icon: Icons.work_outline, color: Colors.indigo, route: '/job-applications'),
    ModuleItem(title: 'Contracts', icon: Icons.assignment, color: Colors.blue, route: '/contracts'),
    ModuleItem(title: 'Tax Docs', icon: Icons.receipt_long, color: Colors.green, route: '/tax-documents'),
    ModuleItem(title: 'Career Notes', icon: Icons.note_alt, color: Colors.purple, route: '/career-notes'),
  ];

  List<ModuleItem> _getHomeModules() => [
    ModuleItem(title: 'Vehicles', icon: Icons.directions_car, color: Colors.brown, route: '/vehicles'),
    ModuleItem(title: 'Plant Care', icon: Icons.local_florist, color: Colors.green, route: '/plants'),
    ModuleItem(title: 'Maintenance', icon: Icons.home_repair_service, color: Colors.orange, route: '/home-maintenance'),
    ModuleItem(title: 'Recipes', icon: Icons.restaurant_menu, color: Colors.red, route: '/recipes'),
  ];

  List<ModuleItem> _getSystemModules() => [
    ModuleItem(title: 'Analytics', icon: Icons.analytics, color: Colors.teal, route: '/analytics'),
    ModuleItem(title: 'Passwords', icon: Icons.lock, color: Colors.red, route: '/password-manager'),
    ModuleItem(title: 'Weather', icon: Icons.wb_sunny, color: Colors.amber, route: '/weather'),
    ModuleItem(title: 'News', icon: Icons.newspaper, color: Colors.indigo, route: '/news'),
    ModuleItem(title: 'AI Assistant', icon: Icons.assistant, color: Colors.purple, route: '/ai-assistant'),
  ];
}

class ModuleItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  ModuleItem({required this.title, required this.icon, required this.color, required this.route});
}
