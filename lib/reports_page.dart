
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsDialog extends StatefulWidget {
  final String assetId;
  final String assetName;
  final bool isAdmin;
  final VoidCallback? onReportGenerated;
  final Function(Map<String, dynamic>)? onViewDetails;

  const ReportsDialog({
    super.key,
    required this.assetId,
    required this.assetName,
    required this.isAdmin,
    this.onReportGenerated,
    this.onViewDetails,
  });

  @override
  State<ReportsDialog> createState() => _ReportsDialogState();
}

class _ReportsDialogState extends State<ReportsDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reportDetailsController = TextEditingController();
  DateTime? _maintenanceDate;
  DateTime? _nextMaintenanceDate;
  String? _reportType;
  String? _filterType = 'All'; // Default filter type
  bool _isGenerating = false;
  bool _sortOrderAscending = false; // Default to descending order

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _reportDetailsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectMaintenanceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B7A6D),
              onPrimary: Colors.white,
              surface: Color(0xFFF5F5F5),
              onSurface: Color(0xFF3A4F41),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFFF5F5F5),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'NotoSansJP', color: Color(0xFF3A4F41)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _maintenanceDate) {
      setState(() {
        _maintenanceDate = picked;
      });
    }
  }

  Future<void> _selectNextMaintenanceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _maintenanceDate ?? DateTime.now(),
      firstDate: _maintenanceDate ?? DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B7A6D),
              onPrimary: Colors.white,
              surface: Color(0xFFF5F5F5),
              onSurface: Color(0xFF3A4F41),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFFF5F5F5),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'NotoSansJP', color: Color(0xFF3A4F41)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _nextMaintenanceDate) {
      setState(() {
        _nextMaintenanceDate = picked;
      });
    }
  }

  Future<void> _createNotification(String assetId, String assetName,
      DateTime nextMaintenanceDate, String reportType) async {
    final now = DateTime.now();
    final oneWeekFromNow = now.add(const Duration(days: 7));

    if (nextMaintenanceDate.isAfter(now) &&
        nextMaintenanceDate.isBefore(oneWeekFromNow)) {
      // Check if a notification for this assetId and maintenance_date has been deleted
      Timestamp maintenanceTimestamp = Timestamp.fromDate(nextMaintenanceDate);
      QuerySnapshot deletedNotifications = await FirebaseFirestore.instance
          .collection('deleted_notifications')
          .where('assetId', isEqualTo: assetId)
          .where('maintenance_date', isEqualTo: maintenanceTimestamp)
          .get();

      if (deletedNotifications.docs.isNotEmpty) {
        // ignore: avoid_print
        print(
            "Notification for asset $assetId with maintenance_date $maintenanceTimestamp was previously deleted, skipping creation...");
        return;
      }

      // Check if a notification already exists
      QuerySnapshot existingNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('assetId', isEqualTo: assetId)
          .where('maintenance_date', isEqualTo: maintenanceTimestamp)
          .get();

      if (existingNotifications.docs.isNotEmpty) {
        // ignore: avoid_print
        print(
            "Notification for asset $assetId with maintenance_date $maintenanceTimestamp already exists, skipping creation...");
        return;
      }

      // Create the notification
      final message =
          'Maintenance for $assetName is due on ${DateFormat('MM/dd/yyyy').format(nextMaintenanceDate)}';
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('notifications').add({
        'notification_id': '',
        'assetId': assetId,
        'assetName': assetName,
        'message': message,
        'maintenance_date': maintenanceTimestamp,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'system',
        'type': 'maintenance_alert',
      });

      await docRef.update({'notification_id': docRef.id});
      // ignore: avoid_print
      print("Created notification with ID: ${docRef.id}");
    }
  }

  Future<void> generateReport() async {
    final details = _reportDetailsController.text.trim();

    if (_reportType == null) {
      _showMessageDialog(
        context,
        title: 'Validation Error',
        message: 'Please select a report type.',
        isSuccess: false,
      );
      return;
    }

    if (details.isEmpty) {
      _showMessageDialog(
        context,
        title: 'Validation Error',
        message: 'Report details cannot be empty.',
        isSuccess: false,
      );
      return;
    }

    if (_reportType == 'Maintenance') {
      if (_maintenanceDate == null) {
        _showMessageDialog(
          context,
          title: 'Validation Error',
          message: 'Please select a maintenance date.',
          isSuccess: false,
        );
        return;
      }
      if (_nextMaintenanceDate == null) {
        _showMessageDialog(
          context,
          title: 'Validation Error',
          message: 'Please select the next maintenance date.',
          isSuccess: false,
        );
        return;
      }
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('reports').add({
        'report_id': '',
        'assetId': widget.assetId,
        'assetName': widget.assetName,
        'report_type': _reportType,
        'details': details,
        'maintenance_date':
            _reportType == 'Maintenance' ? Timestamp.fromDate(_maintenanceDate!) : null,
        'next_maintenance_date': _reportType == 'Maintenance'
            ? Timestamp.fromDate(_nextMaintenanceDate!)
            : null,
        'created_at': FieldValue.serverTimestamp(),
      });

      await docRef.update({'report_id': docRef.id});

      if (_reportType == 'Maintenance' && _nextMaintenanceDate != null) {
        await _createNotification(
            widget.assetId, widget.assetName, _nextMaintenanceDate!, _reportType!);
      }

      if (!mounted) return;
      _showMessageDialog(
        context,
        title: 'Success',
        message: 'Report generated successfully!',
        isSuccess: true,
      );

      _reportDetailsController.clear();
      setState(() {
        _reportType = null;
        _maintenanceDate = null;
        _nextMaintenanceDate = null;
      });

      if (widget.onReportGenerated != null) {
        widget.onReportGenerated!();
      }
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(
        context,
        title: 'Error',
        message: 'Error generating report: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (!mounted) return;
      _showMessageDialog(
        context,
        title: 'Success',
        message: 'Report deleted successfully!',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(
        context,
        title: 'Error',
        message: 'Error deleting report: $e',
        isSuccess: false,
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String reportId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: Dialog(
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
                          topRight: Radius.circular(15)),
                    ),
                    child: const Text(
                      'Delete Report',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Are you sure you want to delete this report?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A4F41),
                        fontFamily: 'NotoSansJP'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: Color(0xFF5B7A6D), width: 2),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'NO',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A4F41),
                                fontFamily: 'NotoSansJP'),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7A6D),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteReport(reportId);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'YES',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'NotoSansJP'),
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
      },
    );
  }

void _showMessageDialog(BuildContext context,
    {required String title, required String message, required bool isSuccess}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    pageBuilder: (context, animation, secondaryAnimation) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        ),
        child: Dialog(
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
                        topRight: Radius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSuccess ? const Color(0xFF3A4F41) : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansJP',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7A6D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Close',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
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

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: Dialog(
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
                            topRight: Radius.circular(15)),
                      ),
                      child: const Text(
                        'Report Details',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: const Center(
                              child: Text(
                                'Report Information',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'NotoSansJP'),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8)),
                              border: const Border.fromBorderSide(
                                  BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(3, 3),
                                ),
                              ],
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(3),
                              },
                              children: [
                                _buildDetailsTableRow(
                                    'Report ID', report['report_id'] ?? '-'),
                                _buildDetailsTableRow(
                                    'Asset ID', report['assetId'] ?? '-',
                                    isGrey: true),
                                _buildDetailsTableRow(
                                    'Asset Name', report['assetName'] ?? '-'),
                                _buildDetailsTableRow(
                                    'Report Type', report['report_type'] ?? '-',
                                    isGrey: true),
                                _buildDetailsTableRow(
                                    'Details', report['details'] ?? '-'),
                                _buildDetailsTableRow(
                                    'Maintenance Date',
                                    maintenanceDate != null
                                        ? DateFormat('MM/dd/yyyy')
                                            .format(maintenanceDate)
                                        : '-',
                                    isGrey: true),
                                _buildDetailsTableRow(
                                    'Next Maintenance',
                                    nextMaintenanceDate != null
                                        ? DateFormat('MM/dd/yyyy')
                                            .format(nextMaintenanceDate)
                                        : '-'),
                                _buildDetailsTableRow(
                                    'Generated',
                                    createdAt != null
                                        ? DateFormat('MM/dd/yyyy HH:mm')
                                            .format(createdAt)
                                        : '-',
                                    isGrey: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7A6D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Close',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'NotoSansJP'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // For the report details table
  TableRow _buildDetailsTableRow(String label, String value, {bool isGrey = false}) {
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
                color: Color(0xFF3A4F41),
                fontFamily: 'NotoSansJP'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
          ),
        ),
      ],
    );
  }

  // For the reports table

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with gradient and icon
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7A6D).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.report,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reports for ${widget.assetName}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Generate Report Section (for admins)
        if (widget.isAdmin) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7A6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.add_circle, color: Color(0xFF3A4F41), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Generate New Report',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A4F41),
                          fontFamily: 'NotoSansJP'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    labelStyle:
                        TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                    filled: true,
                    fillColor: Color(0xFFE0E0E0),
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF3A4F41), width: 2)),
                    prefixIcon: Icon(Icons.report, color: Color(0xFF3A4F41)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  value: _reportType,
                  items: ['Maintenance', 'Others']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontFamily: 'NotoSansJP', color: Color(0xFF3A4F41)))))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _reportType = value;
                      _maintenanceDate = null;
                      _nextMaintenanceDate = null;
                    });
                  },
                  dropdownColor: const Color(0xFFF5F5F5),
                ),
                const SizedBox(height: 16),

                if (_reportType == 'Maintenance') ...[
                  GestureDetector(
                    onTap: () => _selectMaintenanceDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _maintenanceDate != null
                                ? 'Maintenance Date: ${DateFormat('MM/dd/yyyy').format(_maintenanceDate!)}'
                                : 'Select Maintenance Date',
                            style: TextStyle(
                                color: _maintenanceDate != null
                                    ? const Color(0xFF3A4F41)
                                    : Colors.grey[600],
                                fontSize: 16,
                                fontFamily: 'NotoSansJP'),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF3A4F41)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _selectNextMaintenanceDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _nextMaintenanceDate != null
                                ? 'Next Maintenance: ${DateFormat('MM/dd/yyyy').format(_nextMaintenanceDate!)}'
                                : 'Select Next Maintenance Date',
                            style: TextStyle(
                                color: _nextMaintenanceDate != null
                                    ? const Color(0xFF3A4F41)
                                    : Colors.grey[600],
                                fontSize: 16,
                                fontFamily: 'NotoSansJP'),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF3A4F41)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _reportDetailsController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Report Details',
                    labelStyle:
                        TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                    filled: true,
                    fillColor: Color(0xFFE0E0E0),
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF3A4F41), width: 2)),
                    prefixIcon: Icon(Icons.description, color: Color(0xFF3A4F41)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                Center(
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Color(0xFF5B7A6D))
                      : AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _animationController.reverse().then((_) {
                                    _animationController.forward();
                                    generateReport();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B7A6D),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                                icon: const Icon(Icons.report, color: Colors.white),
                                label: const Text(
                                  'Generate Report',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

 // Report List Section
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF5B7A6D).withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(
                Icons.list_alt,
                color: Color(0xFF3A4F41),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'List of Reports Generated',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF3A4F41),
                    fontFamily: 'NotoSansJP'),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _sortOrderAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: const Color(0xFF3A4F41),
                ),
                onPressed: () {
                  setState(() {
                    _sortOrderAscending = !_sortOrderAscending;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                tooltip: _sortOrderAscending
                    ? 'Sort by Date (Descending)'
                    : 'Sort by Date (Ascending)',
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF3A4F41),
                ),
                onPressed: () {
                  setState(() {
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),

      // Filter Dropdown
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Filter by Type',
          labelStyle:
              TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
          filled: true,
          fillColor: Color(0xFFE0E0E0),
          border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2)),
          prefixIcon: Icon(Icons.filter_list, color: Color(0xFF3A4F41)),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        value: _filterType,
        items: ['All', 'Maintenance', 'Others']
            .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type,
                    style: const TextStyle(
                        fontFamily: 'NotoSansJP', color: Color(0xFF3A4F41)))))
            .toList(),
        onChanged: (value) {
          setState(() {
            _filterType = value;
            _animationController.reset();
            _animationController.forward();
          });
        },
        dropdownColor: const Color(0xFFF5F5F5),
      ),
      const SizedBox(height: 10),

      SizedBox(
        height: 200,
        child: StreamBuilder<QuerySnapshot>(
          stream: _filterType == 'All'
              ? FirebaseFirestore.instance
                  .collection('reports')
                  .where('assetId', isEqualTo: widget.assetId)
                  .orderBy('created_at', descending: !_sortOrderAscending)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('reports')
                  .where('assetId', isEqualTo: widget.assetId)
                  .where('report_type', isEqualTo: _filterType)
                  .orderBy('created_at', descending: !_sortOrderAscending)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5B7A6D),
                ),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Failed to load reports. Please check your Firestore indexes.',
                      style: TextStyle(
                          color: Colors.red, fontFamily: 'NotoSansJP'),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Check the debug console for more details.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'NotoSansJP'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.report_off,
                      color: Colors.grey,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No reports generated yet.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: 'NotoSansJP'),
                    ),
                    const SizedBox(height: 10),
                    if (widget.isAdmin)
                      TextButton(
                        onPressed: () {
                          Scrollable.ensureVisible(
                            context,
                            alignment: 0.5,
                            duration: const Duration(milliseconds: 500),
                          );
                        },
                        child: const Text(
                          'Generate a report now!',
                          style: TextStyle(
                              color: Color(0xFF3A4F41),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansJP'),
                        ),
                      ),
                  ],
                ),
              );
            }

            final reports = snapshot.data!.docs;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B7A6D).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: ListView(
                    children: [
                      // Header Row
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'Report ID',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'Type',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'Action',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'NotoSansJP'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Data Rows
                      ...reports.asMap().entries.map((entry) {
                        final index = entry.key;
                        final report = entry.value.data() as Map<String, dynamic>;
                        final reportId = report['report_id'] ?? '-';
                        final isGrey = index % 2 == 0;

                        return Container(
                          color: isGrey ? const Color(0xFFE0E0E0) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
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
                                        color: Color(0xFF3A4F41),
                                        fontFamily: 'NotoSansJP'),
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
                                        color: Color(0xFF3A4F41),
                                        fontFamily: 'NotoSansJP'),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Color(0xFF3A4F41),
                                      ),
                                      onPressed: () {
                                        _showReportDetails(report);
                                      },
                                      tooltip: 'View Details',
                                    ),
                                    if (widget.isAdmin)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(
                                              context, reportId);
                                        },
                                        tooltip: 'Delete Report',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  ),
),
      ],
    );
  }
}