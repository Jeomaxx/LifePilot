import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final notificationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('notifications');
});

class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final db = DatabaseService();
              final notifications = await notificationsAsync.value;
              if (notifications != null) {
                for (final notif in notifications) {
                  if (notif['read'] == false) {
                    await db.update('notifications', notif['id']?.toString() ?? '', {'read': true});
                  }
                }
              }
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              subtitle: 'No notifications',
            );
          }

          final unread = notifications.where((n) => n['read'] == false).toList();
          final read = notifications.where((n) => n['read'] == true).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (unread.isNotEmpty) ...[
                const Text('Unread', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...unread.map((notif) => _buildNotificationCard(context, ref, notif, false)),
                const SizedBox(height: 16),
              ],
              if (read.isNotEmpty) ...[
                const Text('Read', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...read.map((notif) => _buildNotificationCard(context, ref, notif, true)),
              ],
            ],
          );
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, Map<String, dynamic> notif, bool isRead) {
    final title = notif['title']?.toString() ?? 'Notification';
    final message = notif['message']?.toString() ?? '';
    final createdAt = notif['created_at'] != null ? DateTime.parse(notif['created_at'].toString()) : null;
    final type = notif['type']?.toString() ?? 'info';

    IconData icon;
    Color color;
    
    switch (type.toLowerCase()) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'error':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (createdAt != null) Text(DateFormat('MMM dd, HH:mm').format(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: !isRead ? IconButton(
          icon: const Icon(Icons.done),
          onPressed: () async {
            await DatabaseService().update('notifications', notif['id']?.toString() ?? '', {'read': true});
          ),
        ) : null,
        onLongPress: () async {
          await DatabaseService().delete('notifications', notif['id']?.toString() ?? '');
        ),
      ),
    );
  }
}
