import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanceTrackerScreen extends ConsumerWidget {
  const FinanceTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
      },
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(context),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _buildTransactionsList(context),
        ],
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      },
    };
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              },
            },
            const SizedBox(height: 8),
            Text(
              '\$12,450.00',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              },
            },
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Income',
                            style: Theme.of(context).textTheme.bodySmall,
                          },
                        ],
                      },
                      const SizedBox(height: 4),
                      Text(
                        '\$5,200',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        },
                      },
                    ],
                  },
                },
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.bodySmall,
                          },
                        ],
                      },
                      const SizedBox(height: 4),
                      Text(
                        '\$3,450',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        },
                      },
                    ],
                  },
                },
              ],
            },
          ],
        },
      },
    };
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.trending_up),
            label: const Text('Investments'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            },
          },
        },
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.currency_bitcoin),
            label: const Text('Crypto'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            },
          },
        },
      ],
    };
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          },
        },
        const SizedBox(height: 12),
        _buildTransactionItem(
          context,
          icon: Icons.shopping_cart,
          title: 'Grocery Shopping',
          category: 'Food',
          amount: -125.50,
          date: 'Today',
        },
        _buildTransactionItem(
          context,
          icon: Icons.payments,
          title: 'Freelance Payment',
          category: 'Income',
          amount: 1500.00,
          date: 'Yesterday',
        },
        _buildTransactionItem(
          context,
          icon: Icons.local_gas_station,
          title: 'Gas Station',
          category: 'Transportation',
          amount: -45.00,
          date: '2 days ago',
        },
      ],
    };
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String category,
    required double amount,
    required String date,
  }) {
    final isExpense = amount < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Colors.red.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          child: Icon(
            icon,
            color: isExpense ? Colors.red : Colors.green,
          },
        },
        title: Text(title),
        subtitle: Text(category),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '' : '+'}\$${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              },
            },
            Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              },
            },
          ],
        },
      },
    };
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: const Text('Transaction entry form would appear here with offline sync support.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          },
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          },
        ],
      },
    };
  }
}
