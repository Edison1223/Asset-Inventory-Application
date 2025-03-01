import 'package:flutter/material.dart';

class AssetScanningPage extends StatelessWidget {
  const AssetScanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Scanning'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan an asset to retrieve details.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic for scanning assets
              },
              child: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
