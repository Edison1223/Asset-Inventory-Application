import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  final String assetId;    // Used internally to associate reports with an asset.
  final String assetName;  // Also used internally.
  final bool isAdmin;

  const ReportsPage({
    super.key,
    required this.assetId,
    required this.assetName,
    required this.isAdmin,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final TextEditingController _reportDetailsController = TextEditingController();

  Future<void> generateReport() async {
    final details = _reportDetailsController.text.trim();

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report details cannot be empty')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'assetId': widget.assetId,
        'assetName': widget.assetName,
        'details': details,
        'created_at': FieldValue.serverTimestamp(),
      });
      // Check if the widget is still mounted before updating the UI.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );
      _reportDetailsController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: Column(
        children: [
          // Report generation section shown only to admins.
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _reportDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Enter Report Details',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          if (widget.isAdmin)
            ElevatedButton(
              onPressed: generateReport,
              child: const Text('Generate Report'),
            ),
          const Divider(),
          // StreamBuilder to display reports associated with the selected asset.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('assetId', isEqualTo: widget.assetId)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reports available for this asset."));
                }
                final reports = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final data = reports[index].data() as Map<String, dynamic>;
                    final details = data['details'] ?? 'No Details';
                    final createdAt = data['created_at'] != null
                        ? (data['created_at'] as Timestamp).toDate()
                        : null;
                    return Card(
                      child: ListTile(
                        title: Text(details),
                        subtitle: Text(
                          createdAt != null
                              ? "Created at: ${DateFormat('MM/dd/yyyy HH:mm').format(createdAt)}"
                              : "Unknown date",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
