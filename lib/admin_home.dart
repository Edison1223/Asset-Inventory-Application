
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'user_management.dart';
import 'notifications_and_alerts.dart';
import 'main.dart'; 
import 'asset_registration.dart';
import 'asset_scanning.dart';
import 'asset_tracking.dart';
import 'asset_categorization.dart';
import 'reports_page.dart';
import 'notification_service.dart';
import 'dart:math'; 

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  final Logger logger = Logger();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService().init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Reusable method to show a message dialog (success or error)
  void _showMessageDialog(BuildContext context, {required String title, required String message, required bool isSuccess, VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSuccess) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: title == 'Not Found'
                      ? Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              color: Color(0xFF5B7A6D),
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              message,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Text(
                          message,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7A6D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (onClose != null) onClose();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7A6D).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: const Text(
                  'Log Out Confirmation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF5B7A6D), width: 2),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'NO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7A6D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'YES',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> performSearch() async {
    setState(() {
      isLoading = true;
    });

    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() => isLoading = false);
      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Error',
          message: 'Please enter a search query',
          isSuccess: false,
        );
      }
      return;
    }

    try {
      final nameSnapshot = await FirebaseFirestore.instance
          .collection('assets')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final idSnapshot = await FirebaseFirestore.instance
          .collection('assets')
          .where('asset_id', isGreaterThanOrEqualTo: query)
          .where('asset_id', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      final searchResults = <Map<String, dynamic>>[];
      final seenDocIds = <String>{};

      for (var doc in nameSnapshot.docs) {
        if (!seenDocIds.contains(doc.id)) {
          final data = doc.data();
          data['docId'] = doc.id;
          searchResults.add(data);
          seenDocIds.add(doc.id);
        }
      }

      for (var doc in idSnapshot.docs) {
        if (!seenDocIds.contains(doc.id)) {
          final data = doc.data();
          data['docId'] = doc.id;
          searchResults.add(data);
          seenDocIds.add(doc.id);
        }
      }

      if (searchResults.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B7A6D).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Search Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Color(0xFF5B7A6D),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No assets found for your search query.',
                            style: TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7A6D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Close',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final BuildContext currentContext = context;
      showDialog(
        context: currentContext,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                        tooltip: 'Back',
                      ),
                      const Text(
                        'Search Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final asset = searchResults[index];
                      final docId = asset['docId'] as String;
                      final assetId = asset['asset_id'] ?? '-';
                      final assetName = asset['name'] ?? '-';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? const Color(0xFFF5F5F5) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Asset ID: $assetId', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                Text('Name: $assetName', style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                Text('Status: ${asset['status'] ?? '-'}', style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.report, color: Colors.red),
                                  onPressed: () => _showReportDialog(assetId, assetName),
                                  tooltip: 'Reports',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF5B7A6D)),
                                  onPressed: () => _viewDetails(asset),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.green),
                                  onPressed: () => _editAsset(docId, asset),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAsset(docId),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Error',
          message: 'Error occurred: $e',
          isSuccess: false,
        );
      }
    }
  }

  void _showReportDialog(String assetId, String assetName) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7A6D).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Reports',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ReportsDialog(
                      assetId: assetId,
                      assetName: assetName,
                      isAdmin: true,
                      onReportGenerated: () {
                        Navigator.pop(dialogContext);
                        _showReportDialog(assetId, assetName);
                      },
                      onViewDetails: _showReportDetails,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7A6D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final createdAt = report['created_at'] != null
        ? (report['created_at'] as Timestamp).toDate()
        : null;
    final maintenanceDate = report['maintenance_date'] != null
        ? (report['maintenance_date'] as Timestamp).toDate()
        : null;
    final nextMaintenanceDate = report['next_maintenance_date'] != null
        ? (report['next_maintenance_date'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7A6D).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: const Text(
                  'Report Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Table(
                  border: const TableBorder.symmetric(outside: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow('Report ID', report['report_id'] ?? '-', isGrey: true),
                    _buildTableRow('Type', report['report_type'] ?? '-'),
                    _buildTableRow('Asset ID', report['assetId'] ?? '-', isGrey: true),
                    _buildTableRow('Asset Name', report['assetName'] ?? '-'),
                    _buildTableRow('Details', report['details'] ?? '-', isGrey: true),
                    _buildTableRow(
                      'Created At',
                      createdAt != null ? DateFormat('MM/dd/yyyy HH:mm').format(createdAt) : '-',
                    ),
                    if (report['maintenance_date'] != null)
                      _buildTableRow(
                        'Maintenance Date',
                        maintenanceDate != null ? DateFormat('MM/dd/yyyy').format(maintenanceDate) : '-',
                        isGrey: true,
                      ),
                    if (report['next_maintenance_date'] != null)
                      _buildTableRow(
                        'Next Maintenance',
                        nextMaintenanceDate != null ? DateFormat('MM/dd/yyyy').format(nextMaintenanceDate) : '-',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7A6D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP')),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value, {bool isGrey = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isGrey ? const Color(0xFFE0E0E0) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
          ),
        ),
      ],
    );
  }

  void _viewDetails(Map<String, dynamic> asset) {
    final purchaseDate = asset['purchase_date'] != null
        ? (asset['purchase_date'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Asset Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Table(
                    border: const TableBorder.symmetric(outside: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    columnWidths: const {
                      0: FlexColumnWidth(1.5),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      _buildTableRow("Asset ID", asset['asset_id'] ?? '-', isGrey: true),
                      _buildTableRow("RFID ID", asset['rfid_id'] ?? '-'),
                      _buildTableRow("Asset Name", asset['name'] ?? '-', isGrey: true),
                      _buildTableRow("Status", asset['status'] ?? '-'),
                      _buildTableRow(
                        "Purchase Date",
                        purchaseDate != null ? DateFormat('MM/dd/yyyy').format(purchaseDate) : '-',
                        isGrey: true,
                      ),
                      _buildTableRow("Lifetime (Years)", asset['lifetime']?.toString() ?? '-'),
                      _buildTableRow("Value (RM)", asset['value']?.toString() ?? '-', isGrey: true),
                      _buildTableRow("Location", asset['location'] ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7A6D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP')),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _updateAsset(String docId, Map<String, dynamic> updatedData) async {
    try {
      logger.i("Attempting to update asset with ID: $docId");
      await FirebaseFirestore.instance.collection('assets').doc(docId).update(updatedData);
      return true;
    } catch (e) {
      logger.e("Error updating asset: $e");
      return false;
    }
  }

  void _editAsset(String docId, Map<String, dynamic> asset) {
    String? selectedStatus = asset['status'] ?? 'Active';
    final TextEditingController locationController = TextEditingController(text: asset['location'] ?? '');

    final BuildContext mainContext = context;

    showDialog<bool>(
      context: mainContext,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Edit Asset',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF5B7A6D), width: 1.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                  child: DropdownButton<String>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    items: ['Active', 'Inactive', 'Under Maintenance']
                                        .map((status) => DropdownMenuItem<String>(
                                              value: status,
                                              child: Text(
                                                status,
                                                style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedStatus = value;
                                      });
                                    },
                                    underline: const SizedBox.shrink(),
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5B7A6D)),
                                    dropdownColor: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: locationController,
                            style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              labelStyle: TextStyle(color: Color(0xFF5B7A6D), fontFamily: 'NotoSansJP'),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF5B7A6D), width: 2),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7A6D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (selectedStatus == null || locationController.text.trim().isEmpty) {
                              if (mounted) {
                                _showMessageDialog(
                                  mainContext,
                                  title: 'Error',
                                  message: 'All fields must be filled',
                                  isSuccess: false,
                                );
                              }
                              return;
                            }

                            final updatedData = {
                              'status': selectedStatus!,
                              'location': locationController.text.trim(),
                            };

                            final success = await _updateAsset(docId, updatedData);

                            if (!mounted) return;

                            Navigator.pop(dialogContext, success);

                            if (success ?? false) {
                              _showMessageDialog(
                                mainContext,
                                title: 'Success',
                                message: 'Asset updated successfully!',
                                isSuccess: true,
                                onClose: () {
                                  setState(() {});
                                },
                              );
                            } else {
                              _showMessageDialog(
                                mainContext,
                                title: 'Error',
                                message: 'Error updating asset',
                                isSuccess: false,
                              );
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              'Save',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _deleteAssetFromFirestore(String docId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('assets').doc(docId).get();
      if (!docSnapshot.exists) {
        return false;
      }

      logger.i('Attempting to delete asset with ID: $docId');
      await FirebaseFirestore.instance.collection('assets').doc(docId).delete();
      return true;
    } catch (e) {
      logger.e('Error deleting asset: $e');
      return false;
    }
  }

  void _deleteAsset(String docId) {
    final BuildContext currentContext = context;

    showDialog<bool>(
      context: currentContext,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Delete Confirmation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Are you sure you want to delete this asset?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF5B7A6D), width: 2),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'NO',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7A6D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext, true);

                        final success = await _deleteAssetFromFirestore(docId);

                        if (!mounted) return;

                        _showMessageDialog(
                          currentContext,
                          title: success ?? false ? 'Success' : 'Error',
                          message: success ?? false
                              ? 'Asset deleted successfully!'
                              : 'Error deleting asset or asset does not exist',
                          isSuccess: success ?? false,
                          onClose: () {
                            if (success ?? false) {
                              setState(() {});
                            }
                          },
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'YES',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for styled Drawer items
  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5B7A6D), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF3A4F41)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A4F41),
                    fontFamily: 'NotoSansJP',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ADMIN HOME',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF3A4F41)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                width: double.infinity,
                child: const Text(
                  'Menu',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                ),
              ),
              const SizedBox(height: 10),
              _buildDrawerItem(
                icon: Icons.people,
                title: 'Manage User',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementPage())),
              ),
              _buildDrawerItem(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(isAdmin: true, userId: 'admin123'),
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Log Out',
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE0E0E0).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          const CherryBlossomParticles(),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WaveBackground(),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                          decoration: InputDecoration(
                            hintText: 'Search here... (Asset Name or ID)',
                            hintStyle: const TextStyle(color: Color(0xFF5B7A6D), fontFamily: 'NotoSansJP'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF5B7A6D), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF5B7A6D), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF3A4F41), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7A6D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        onPressed: performSearch,
                        child: const Text(
                          'SEARCH',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'NotoSansJP'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 2)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'List of Assets Registered',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, fontFamily: 'NotoSansJP'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('assets').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7A6D)));
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No assets registered yet.',
                                    style: TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                                  ),
                                );
                              }

                              final assets = snapshot.data!.docs;

                              return ListView.builder(
                                itemCount: assets.length,
                                itemBuilder: (context, index) {
                                  final doc = assets[index];
                                  final asset = doc.data() as Map<String, dynamic>;
                                  final docId = doc.id;
                                  final assetId = asset['asset_id'] ?? '-';
                                  final assetName = asset['name'] ?? '-';
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: index % 2 == 0 ? const Color(0xFFF5F5F5) : const Color(0xFFE0E0E0),
                                      borderRadius: BorderRadius.circular(8),
                                      border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Asset ID: $assetId', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                            Text('Name: $assetName', style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                            Text('Status: ${asset['status'] ?? '-'}', style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.report, color: Colors.red),
                                              onPressed: () => _showReportDialog(assetId, assetName),
                                              tooltip: 'Reports',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.visibility, color: Color(0xFF5B7A6D)),
                                              onPressed: () => _viewDetails(asset),
                                              tooltip: 'View Details',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.green),
                                              onPressed: () => _editAsset(docId, asset),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteAsset(docId),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton('Register', Icons.add_box, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetRegistrationPage()));
                      }, const Color(0xFFDAB894)),
                      _buildActionButton('Scanning', Icons.qr_code, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AssetScanner()));
                      }, const Color(0xFF5B7A6D)),
                      _buildActionButton('Tracking', Icons.location_on, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AssetTracking()));
                      }, const Color(0xFF3A4F41)),
                      _buildActionButton('Categorize', Icons.category, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AssetCategorizationPage(isAdmin: true)),
                        );
                      }, const Color(0xFFDAB894)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 2)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B7A6D).withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
            ),
          ],
        ),
      ),
    );
  }
}

// Cherry Blossom Particle Animation
class CherryBlossomParticles extends StatefulWidget {
  const CherryBlossomParticles({super.key});

  @override
  State<CherryBlossomParticles> createState() => _CherryBlossomParticlesState();
}

class _CherryBlossomParticlesState extends State<CherryBlossomParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initializeParticles();
  }

  void _initializeParticles() {
    const int particleCount = 20;
    for (int i = 0; i < particleCount; i++) {
      particles.add(Particle(
        x: Random().nextDouble() * 400,
        y: Random().nextDouble() * 800,
        speedX: Random().nextDouble() * 2 - 1,
        speedY: Random().nextDouble() * 2 + 1,
        size: Random().nextDouble() * 10 + 5,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var particle in particles) {
          particle.update();
          if (particle.y > 800) {
            particle.y = 0;
            particle.x = Random().nextDouble() * 400;
          }
        }
        return CustomPaint(
          painter: CherryBlossomPainter(particles),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;

  Particle({required this.x, required this.y, required this.speedX, required this.speedY, required this.size});

  void update() {
    x += speedX;
    y += speedY;
    if (y > 800) {
      y = -20;
      x = Random().nextDouble() * 500;
      speedX = (Random().nextDouble() - 0.5) * 0.5;
      speedY = Random().nextDouble() * 1 + 0.5;
    }
  }
}

class CherryBlossomPainter extends CustomPainter {
  final List<Particle> particles;

  CherryBlossomPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB6C1).withOpacity(0.8);
    for (var particle in particles) {
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Wavy Background
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: CustomPaint(
        painter: WavePainter(),
        child: Container(),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5B7A6D).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, size.height * 0.5 + sin((i / size.width) * 2 * pi) * 20);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}