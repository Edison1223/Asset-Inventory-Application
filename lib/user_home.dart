import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notifications_and_alerts.dart';
import 'user_manage_profile.dart';
import 'main.dart'; 
import 'asset_scanning.dart';
import 'asset_tracking.dart';
import 'asset_categorization.dart';

class RegularUserHomePage extends StatefulWidget {
  final String userId;

  const RegularUserHomePage({super.key, required this.userId});

  @override
  State<RegularUserHomePage> createState() => _RegularUserHomePageState();
}

class _RegularUserHomePageState extends State<RegularUserHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Consistent color scheme from AdminHomePage
  static const Color primaryGradientStart = Color(0xFFDAB894);
  static const Color primaryGradientEnd = Color(0xFF5B7A6D);
  static const Color textColor = Color(0xFF3A4F41);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _showMessageDialog(BuildContext context,
      {required String title,
      required String message,
      required bool isSuccess,
      VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGradientEnd.withOpacity(0.3),
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
                      colors: [primaryGradientStart, primaryGradientEnd],
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
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP',
                        ),
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
                            const Icon(Icons.search_off,
                                color: primaryGradientEnd, size: 50),
                            const SizedBox(height: 10),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 16,
                                color: textColor,
                                fontFamily: 'NotoSansJP',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Text(
                          message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontFamily: 'NotoSansJP',
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGradientEnd,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                      ),
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

  void logOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGradientEnd.withOpacity(0.3),
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
                    colors: [primaryGradientStart, primaryGradientEnd],
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSansJP',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'NotoSansJP',
                ),
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
                        side: const BorderSide(color: primaryGradientEnd, width: 2),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'NO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'NotoSansJP',
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGradientEnd,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP',
                        ),
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
      if (!mounted) return;
      _showMessageDialog(
        context,
        title: 'Error',
        message: 'Please enter a search query',
        isSuccess: false,
      );
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

      final searchResults = [
        ...nameSnapshot.docs.map((doc) => doc.data()),
        ...idSnapshot.docs.map((doc) => doc.data())
      ];

      if (searchResults.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGradientEnd.withOpacity(0.3),
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
                        colors: [primaryGradientStart, primaryGradientEnd],
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Icon(Icons.search_off,
                            color: primaryGradientEnd, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'No assets found for your search query.',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontFamily: 'NotoSansJP',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGradientEnd,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGradientEnd.withOpacity(0.3),
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
                      colors: [primaryGradientStart, primaryGradientEnd],
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP',
                        ),
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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final asset = searchResults[index];
                        final assetId = asset['asset_id'] ?? '-';
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? backgroundColor
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border.fromBorderSide(
                                BorderSide(color: primaryGradientEnd, width: 1.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asset ID: $assetId',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                  ),
                                  Text(
                                    'Name: ${asset['name'] ?? '-'}',
                                    style: const TextStyle(
                                      color: textColor,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                  ),
                                  Text(
                                    'Status: ${asset['status'] ?? '-'}',
                                    style: const TextStyle(
                                      color: textColor,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: primaryGradientEnd),
                                    onPressed: () => _viewDetails(asset),
                                    tooltip: 'View Details',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.report,
                                        color: Colors.red),
                                    onPressed: () => _viewReport(assetId),
                                    tooltip: 'View Report',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
      _showMessageDialog(
        context,
        title: 'Error',
        message: 'Error occurred: $e',
        isSuccess: false,
      );
    }
  }

  void _viewDetails(Map<String, dynamic> asset) {
    final purchaseDate = asset['purchase_date'] != null
        ? (asset['purchase_date'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGradientEnd.withOpacity(0.3),
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
                    colors: [primaryGradientStart, primaryGradientEnd],
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSansJP',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Table(
                  border: const TableBorder.symmetric(
                      outside: BorderSide(color: primaryGradientEnd, width: 1.5)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    _buildTableRow('Asset ID', asset['asset_id'] ?? '-',
                        isGrey: true),
                    _buildTableRow('RFID ID', asset['rfid_id'] ?? '-'),
                    _buildTableRow('Asset Name', asset['name'] ?? '-',
                        isGrey: true),
                    _buildTableRow('Status', asset['status'] ?? '-'),
                    _buildTableRow(
                      'Purchase Date',
                      purchaseDate != null
                          ? DateFormat('MM/dd/yyyy').format(purchaseDate)
                          : '-',
                      isGrey: true,
                    ),
                    _buildTableRow('Lifetime (Years)',
                        asset['lifetime']?.toString() ?? '-'),
                    _buildTableRow('Value (RM)', asset['value']?.toString() ?? '-',
                        isGrey: true),
                    _buildTableRow('Location', asset['location'] ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGradientEnd,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP',
                    ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'NotoSansJP',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: textColor,
              fontFamily: 'NotoSansJP',
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final createdAt = report['created_at'] != null
        ? (report['created_at'] as Timestamp).toDate()
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
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGradientEnd.withOpacity(0.3),
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
                    colors: [primaryGradientStart, primaryGradientEnd],
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSansJP',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Table(
                  border: const TableBorder.symmetric(
                      outside: BorderSide(color: primaryGradientEnd, width: 1.5)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow('Report ID', report['report_id'] ?? '-',
                        isGrey: true),
                    _buildTableRow('Type', report['report_type'] ?? '-'),
                    _buildTableRow('Asset ID', report['assetId'] ?? '-',
                        isGrey: true),
                    _buildTableRow('Asset Name', report['assetName'] ?? '-'),
                    _buildTableRow('Details', report['details'] ?? '-',
                        isGrey: true),
                    _buildTableRow(
                      'Created At',
                      createdAt != null
                          ? DateFormat('MM/dd/yyyy HH:mm').format(createdAt)
                          : '-',
                    ),
                    if (report['next_maintenance_date'] != null)
                      _buildTableRow(
                        'Next Maintenance',
                        nextMaintenanceDate != null
                            ? DateFormat('MM/dd/yyyy').format(nextMaintenanceDate)
                            : '-',
                        isGrey: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGradientEnd,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP',
                    ),
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

  void _viewReport(String assetId) {
    String filterType = 'All';
    bool sortOrderAscending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGradientEnd.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGradientStart, primaryGradientEnd],
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: const Border.fromBorderSide(
                            BorderSide(color: primaryGradientEnd, width: 2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_list,
                                        color: textColor),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Filter by Type',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E0E0),
                                        border: Border.all(
                                            color: primaryGradientEnd, width: 1.5),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: DropdownButton<String>(
                                        value: filterType,
                                        icon: const Icon(Icons.arrow_drop_down,
                                            color: textColor),
                                        iconSize: 20,
                                        underline: const SizedBox(),
                                        onChanged: (String? newValue) {
                                          setDialogState(() {
                                            filterType = newValue!;
                                          });
                                        },
                                        items: ['All', 'Maintenance', 'Others']
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: const TextStyle(
                                                color: textColor,
                                                fontFamily: 'NotoSansJP',
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        dropdownColor: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  sortOrderAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: textColor,
                                ),
                                tooltip: sortOrderAscending
                                    ? 'Sort by Date (Descending)'
                                    : 'Sort by Date (Ascending)',
                                onPressed: () {
                                  setDialogState(() {
                                    sortOrderAscending = !sortOrderAscending;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryGradientStart, primaryGradientEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Report ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Action',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: filterType == 'All'
                                  ? FirebaseFirestore.instance
                                      .collection('reports')
                                      .where('assetId', isEqualTo: assetId)
                                      .orderBy('created_at',
                                          descending: !sortOrderAscending)
                                      .snapshots()
                                  : FirebaseFirestore.instance
                                      .collection('reports')
                                      .where('assetId', isEqualTo: assetId)
                                      .where('report_type', isEqualTo: filterType)
                                      .orderBy('created_at',
                                          descending: !sortOrderAscending)
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator(
                                          color: primaryGradientEnd));
                                }
                                if (snapshot.hasError) {
                                  return const Center(
                                    child: Text(
                                      'Error loading reports.',
                                      style: TextStyle(
                                        color: textColor,
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No reports available.',
                                      style: TextStyle(
                                        color: textColor,
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                  );
                                }

                                final reports = snapshot.data!.docs;

                                return ListView.builder(
                                  itemCount: reports.length,
                                  itemBuilder: (context, index) {
                                    final report =
                                        reports[index].data() as Map<String, dynamic>;
                                    final isGrey = index % 2 == 0;
                                    return Container(
                                      color: isGrey
                                          ? backgroundColor
                                          : const Color(0xFFE0E0E0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12.0),
                                              child: Text(
                                                report['report_id'] ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textColor,
                                                  fontFamily: 'NotoSansJP',
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12.0),
                                              child: Text(
                                                report['report_type'] ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textColor,
                                                  fontFamily: 'NotoSansJP',
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.visibility,
                                                      color: primaryGradientEnd),
                                                  onPressed: () =>
                                                      _showReportDetails(report),
                                                  tooltip: 'View Details',
                                                ),
                                             
                                              ],
                                            ),
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
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGradientEnd,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border.fromBorderSide(
              BorderSide(color: primaryGradientEnd, width: 2)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: primaryGradientEnd.withOpacity(0.3),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
                fontFamily: 'NotoSansJP',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: primaryGradientEnd, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'REGULAR USER HOME',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'NotoSansJP',
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: textColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGradientStart, primaryGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                width: double.infinity,
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSansJP',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildDrawerItem(
                icon: Icons.person,
                title: 'Manage Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserManageProfile(userId: widget.userId)),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsPage(
                      isAdmin: false,
                      userId: widget.userId,
                    ),
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Log Out',
                onTap: () => logOut(context),
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
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
                      style: const TextStyle(
                          color: textColor, fontFamily: 'NotoSansJP'),
                      decoration: InputDecoration(
                        hintText: 'Search here... (Asset Name or ID)',
                        hintStyle: const TextStyle(
                            color: primaryGradientEnd, fontFamily: 'NotoSansJP'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: primaryGradientEnd, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: primaryGradientEnd, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: textColor, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.search, color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGradientEnd,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onPressed: performSearch,
                    child: const Text(
                      'SEARCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansJP',
                      ),
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
                  border: const Border.fromBorderSide(
                      BorderSide(color: primaryGradientEnd, width: 2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGradientStart, primaryGradientEnd],
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('assets')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: primaryGradientEnd));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No assets registered yet.',
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'NotoSansJP',
                                ),
                              ),
                            );
                          }

                          final assets = snapshot.data!.docs
                              .map((doc) => doc.data() as Map<String, dynamic>)
                              .toList();

                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: ListView.builder(
                              itemCount: assets.length,
                              itemBuilder: (context, index) {
                                final asset = assets[index];
                                final assetId = asset['asset_id'] ?? '-';
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? backgroundColor
                                        : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border.fromBorderSide(
                                        BorderSide(
                                            color: primaryGradientEnd, width: 1.5)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Asset ID: $assetId',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                              fontFamily: 'NotoSansJP',
                                            ),
                                          ),
                                          Text(
                                            'Name: ${asset['name'] ?? '-'}',
                                            style: const TextStyle(
                                              color: textColor,
                                              fontFamily: 'NotoSansJP',
                                            ),
                                          ),
                                          Text(
                                            'Status: ${asset['status'] ?? '-'}',
                                            style: const TextStyle(
                                              color: textColor,
                                              fontFamily: 'NotoSansJP',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility,
                                                color: primaryGradientEnd),
                                            onPressed: () => _viewDetails(asset),
                                            tooltip: 'View Details',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.report,
                                                color: Colors.red),
                                            onPressed: () => _viewReport(assetId),
                                            tooltip: 'View Report',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
                  colors: [primaryGradientStart, primaryGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton('Scanning', Icons.qr_code, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => AssetScanner()));
                  }, primaryGradientEnd),
                  _buildActionButton('Tracking', Icons.location_on, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => AssetTracking()));
                  }, textColor),
                  _buildActionButton('Categorize', Icons.category, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const AssetCategorizationPage(isAdmin: false)),
                    );
                  }, primaryGradientStart),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}