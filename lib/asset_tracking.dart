import 'package:flutter/material.dart';

class AssetTrackingPage extends StatelessWidget {
  const AssetTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Tracking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Track assets by location or status.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic for tracking assets
              },
              child: const Text('Track Assets'),
            ),
          ],
        ),
      ),
    );
  }
}
