import 'package:flutter/material.dart';

class NotificationsAndAlertsPage extends StatelessWidget {
  const NotificationsAndAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications and Alerts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications and Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: const Text('Asset Missing Alert'),
                    subtitle: const Text('Details about missing assets.'),
                    onTap: () {
                      // Handle asset missing alert tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.build, color: Colors.blue),
                    title: const Text('Maintenance Alert'),
                    subtitle: const Text('Details about scheduled maintenance.'),
                    onTap: () {
                      // Handle maintenance alert tap
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Open alert configuration (for admin only)
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    final issueController = TextEditingController();
                    final descriptionController = TextEditingController();

                    return AlertDialog(
                      title: const Text('Configure Alert'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: issueController,
                            decoration: const InputDecoration(
                              labelText: 'Issue Type',
                              hintText: 'E.g., Maintenance, Asset Missing',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter details about the issue.',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alert configured successfully!'),
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.add_alert),
              label: const Text('Configure Alert'),
            ),
          ],
        ),
      ),
    );
  }
}
