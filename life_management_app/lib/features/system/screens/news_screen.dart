import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockNews = List.generate(10, (index) => {
      'title': 'Breaking News Story ${index + 1}',
      'summary': 'This is a summary of the news article with important information about recent events.',
      'source': index % 2 == 0 ? 'Tech News' : 'Business Today',
      'time': DateTime.now().subtract(Duration(hours: index)),
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockNews.length,
        itemBuilder: (context, index) {
          final article = mockNews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['title'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article['summary'] as String,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.source, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            article['source'] as String,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('HH:mm').format(article['time'] as DateTime),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
