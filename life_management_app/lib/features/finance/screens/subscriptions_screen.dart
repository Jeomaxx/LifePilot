import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final subscriptionsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('subscriptions');
});

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {},
          },
        ],
      },
      body: subscriptionsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (subscriptions) {
          if (subscriptions.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.subscriptions,
              title: 'No Subscriptions',
              subtitle: 'No subscriptions tracked',
              actionLabel: 'Add Subscription',
              onAction: () => _showAddSubscriptionDialog(context, ref),
            };
          }

          final monthlyTotal = subscriptions.fold<double>(0, (sum, sub) {
            final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
            final cycle = sub['billing_cycle']?.toString() ?? 'monthly';
            return sum + (cycle == 'monthly' ? amount : cycle == 'yearly' ? amount / 12 : amount * 12);
          });

          final yearlyTotal = monthlyTotal * 12;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, monthlyTotal, yearlyTotal, subscriptions.length),
              const SizedBox(height: 24),
              Text(
                'Active Subscriptions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              },
              const SizedBox(height: 12),
              ...subscriptions.map((subscription) => _buildSubscriptionCard(context, ref, subscription)),
            ],
          };
        },
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionDialog(context, ref),
        child: const Icon(Icons.add),
      },
    };
  }

  Widget _buildSummaryCard(BuildContext context, double monthly, double yearly, int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Cost', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('\$${monthly.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                },
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Yearly Cost', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('\$${yearly.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                },
              ],
            },
            const SizedBox(height: 12),
            Text('$count active ${count == 1 ? 'subscription' : 'subscriptions'}', style: Theme.of(context).textTheme.bodySmall),
          ],
        },
      },
    };
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, Map<String, dynamic> subscription) {
    final name = subscription['name']?.toString() ?? 'Unknown';
    final amount = (subscription['amount'] as num?)?.toDouble() ?? 0;
    final cycle = subscription['billing_cycle']?.toString() ?? 'monthly';
    final nextPayment = subscription['next_payment'] != null ? DateTime.parse(subscription['next_payment'].toString()) : null;

    final daysUntilPayment = nextPayment?.difference(DateTime.now()).inDays ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        },
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${amount.toStringAsFixed(2)} / $cycle'),
            if (nextPayment != null)
              Text(
                daysUntilPayment == 0 ? 'Next payment today' : 'Next payment in $daysUntilPayment days',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              },
          ],
        },
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog(context, ref, subscription['id']?.toString() ?? '');
            }
          },
        },
      },
    };
  }

  void _showAddSubscriptionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String billingCycle = 'monthly';
    DateTime? nextPaymentDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Service Name')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: billingCycle,
                  decoration: const InputDecoration(labelText: 'Billing Cycle'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (value) => setState(() => billingCycle = value ?? 'monthly'),
                },
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(nextPaymentDate == null ? 'Next Payment Date' : DateFormat('MMM dd, yyyy').format(nextPaymentDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    };
                    if (date != null) setState(() => nextPaymentDate = date);
                  },
                },
              ],
            },
          },
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || amountController.text.isEmpty) return;

                await DatabaseService().insert('subscriptions', {
                  'name': nameController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'billing_cycle': billingCycle,
                  'next_payment': nextPaymentDate?.toIso8601String() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to remove this subscription?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().delete('subscriptions', id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          },
        ],
      },
    };
  }
}
