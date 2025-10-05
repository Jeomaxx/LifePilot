import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny, size: 120, color: Colors.orange),
            const SizedBox(height: 32),
            const Text('72°F', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
            const Text('Sunny', style: TextStyle(fontSize: 24, color: Colors.grey)),
            const SizedBox(height: 48),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWeatherRow('Humidity', '45%', Icons.water_drop),
                    const Divider(),
                    _buildWeatherRow('Wind Speed', '12 mph', Icons.air),
                    const Divider(),
                    _buildWeatherRow('UV Index', '6', Icons.wb_sunny_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('7-Day Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(days[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Icon(Icons.wb_sunny, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text('${70 + index}°'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
