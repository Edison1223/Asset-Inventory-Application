
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AssetTracking extends StatefulWidget {
  const AssetTracking({super.key});

  @override
  AssetTrackingState createState() => AssetTrackingState();
}

class AssetTrackingState extends State<AssetTracking> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _rfidLength = 24;
  final int _timeoutSeconds = 10;

  List<Map<String, dynamic>> scannedAssets = [];
  List<Map<String, dynamic>> filteredAssets = [];
  Map<String, Timestamp> lastSeenMap = {};
  Map<String, String> assetStatus = {};
  Set<String> scannedRfids = {};
  final Queue<String> _rfidQueue = Queue();
  bool isScanning = false;
  String currentRfid = '';
  bool _isProcessing = false;
  bool isBuildingRfid = false;
  Timer? _debounceTimer;
  Timer? _buildTimeout;
  Timer? _trackingTimer;
  String selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _lastReadMillis = 0;

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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    filteredAssets = scannedAssets;
    startTrackingTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounceTimer?.cancel();
    _buildTimeout?.cancel();
    _trackingTimer?.cancel();
    super.dispose();
  }

  void startTrackingTimer() {
    _trackingTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      final now = DateTime.now();
      setState(() {
        lastSeenMap.forEach((rfid, timestamp) {
          if (now.difference(timestamp.toDate()).inSeconds > _timeoutSeconds) {
            assetStatus[rfid] = 'Out of Range';
            print('Marked $rfid as Out of Range (reads: ${scannedRfids.contains(rfid) ? 1 : 0}) at $now');
          }
        });
      });
    });
  }

  Future<void> fetchAssetDetails(String rfidId) async {
    if (scannedRfids.contains(rfidId)) {
      print("Duplicate RFID ignored: $rfidId");
      setState(() {
        lastSeenMap[rfidId] = Timestamp.now();
        assetStatus[rfidId] = 'In Range';
      });
      return;
    }

    try {
      print("Fetching asset for RFID: $rfidId");
      QuerySnapshot querySnapshot = await _firestore
          .collection('assets')
          .where('rfid_id', isEqualTo: rfidId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          scannedAssets.add(querySnapshot.docs.first.data() as Map<String, dynamic>);
          scannedRfids.add(rfidId);
          lastSeenMap[rfidId] = Timestamp.now();
          assetStatus[rfidId] = 'In Range';
          _filterAssets();
          print("Asset added: $rfidId");
        });
        if (!mounted) return;
        _showMessageDialog(
          context,
          title: 'Asset Found',
          message: "Asset Found: ${querySnapshot.docs.first['name']}",
          isSuccess: true,
        );
      } else {
        if (!mounted) return;
        _showMessageDialog(
          context,
          title: 'Asset Not Found',
          message: "No asset found for RFID: $rfidId",
          isSuccess: false,
        );
      }
    } catch (e) {
      print("Error fetching asset: $e");
      _showMessageDialog(
        context,
        title: 'Error',
        message: "Error fetching asset: $e",
        isSuccess: false,
      );
    }
  }

  void _processQueue() {
    if (_isProcessing || _rfidQueue.isEmpty) {
      print("Queue processing skipped: isProcessing=$_isProcessing, queueLength=${_rfidQueue.length}");
      setState(() {
        isBuildingRfid = false;
      });
      return;
    }

    _isProcessing = true;
    final rfid = _rfidQueue.removeFirst();
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;
    final deltaMillis = _lastReadMillis > 0 ? nowMillis - _lastReadMillis : 0;
    _lastReadMillis = nowMillis;
    print("Processing RFID from queue: $rfid at $now (delta: ${deltaMillis}ms)");
    fetchAssetDetails(rfid).then((_) {
      setState(() {
        _isProcessing = false;
        isBuildingRfid = false;
      });
      _processQueue();
    });
  }

  void _filterAssets() {
    setState(() {
      if (selectedFilter == 'All') {
        filteredAssets = List.from(scannedAssets);
      } else {
        filteredAssets = scannedAssets
            .where((asset) => asset['status'] == selectedFilter)
            .toList();
      }
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (!isScanning) {
      print("Input ignored: Scanning is stopped");
      return;
    }

    if (event is KeyDownEvent) {
      final keyLabel = event.logicalKey.keyLabel;
      if (keyLabel.isNotEmpty &&
          RegExp(r'^[0-9A-Z]$', caseSensitive: false).hasMatch(keyLabel)) {
        setState(() {
          currentRfid += keyLabel.toUpperCase();
          print("Building RFID: $currentRfid");
        });

        _buildTimeout?.cancel();
        _buildTimeout = Timer(const Duration(seconds: 1), () {
          setState(() {
            currentRfid = '';
            isBuildingRfid = false;
            print("Build timeout: Reset RFID buffer");
          });
        });

        if (currentRfid.length >= _rfidLength) {
          _buildTimeout?.cancel();
          final rfid = currentRfid.trim();
          if (rfid.length == _rfidLength && rfid.startsWith('E')) {
            if (isBuildingRfid) {
              print("Input ignored: Queuing another RFID");
              setState(() {
                currentRfid = '';
              });
              return;
            }
            print("Raw RFID input received: $rfid");
            if (!_rfidQueue.contains(rfid)) {
              setState(() {
                isBuildingRfid = true;
              });
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                _rfidQueue.add(rfid);
                print("Queued RFID: $rfid");
                _processQueue();
              });
            } else {
              print("RFID already queued: $rfid");
              setState(() {
                isBuildingRfid = false;
              });
            }
          } else {
            print("Ignored RFID input (wrong length or format): $rfid");
            setState(() {
              isBuildingRfid = false;
            });
          }
          setState(() {
            currentRfid = '';
          });
        }
      }
    }
  }

  void _showMessageDialog(BuildContext context,
      {required String title, required String message, required bool isSuccess}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
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
                        if (isSuccess) ...[
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                        ],
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
                        color: isSuccess ? Colors.lightGreen : Colors.red,
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'RFID ASSET TRACKING',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A4F41),
                fontFamily: 'NotoSansJP'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF3A4F41)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Continuously Tracking RFID Assets',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isScanning
                                    ? Colors.red
                                    : const Color(0xFF5B7A6D),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _animationController.reverse().then((_) {
                                  _animationController.forward();
                                  setState(() {
                                    isScanning = !isScanning;
                                    if (!isScanning) {
                                      currentRfid = '';
                                      _rfidQueue.clear();
                                      _isProcessing = false;
                                      isBuildingRfid = false;
                                      _debounceTimer?.cancel();
                                      _buildTimeout?.cancel();
                                    }
                                  });
                                });
                              },
                              child: Text(
                                isScanning ? 'Stop Tracking' : 'Start Tracking',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansJP',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (isScanning) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Current RFID: $currentRfid',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF3A4F41),
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
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
                              children: [
                                const Icon(
                                  Icons.list_alt,
                                  color: Color(0xFF3A4F41),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Tracked Assets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF3A4F41),
                                    fontFamily: 'NotoSansJP',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedFilter,
                                    items: ['All', 'Active', 'Inactive']
                                        .map((option) {
                                      return DropdownMenuItem(
                                        value: option,
                                        child: Text(
                                          option,
                                          style: const TextStyle(
                                              color: Color(0xFF3A4F41),
                                              fontFamily: 'NotoSansJP'),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedFilter = value!;
                                        _filterAssets();
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF5B7A6D),
                                              width: 1.5)),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF5B7A6D),
                                              width: 1.5)),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF3A4F41),
                                              width: 2)),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 0),
                                    ),
                                    dropdownColor: const Color(0xFFF5F5F5),
                                    isExpanded: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Color(0xFF3A4F41),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      scannedAssets.clear();
                                      filteredAssets.clear();
                                      scannedRfids.clear();
                                      lastSeenMap.clear();
                                      assetStatus.clear();
                                      _rfidQueue.clear();
                                      _isProcessing = false;
                                      isBuildingRfid = false;
                                      _debounceTimer?.cancel();
                                      _buildTimeout?.cancel();
                                    });
                                  },
                                  tooltip: 'Clear List',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: filteredAssets.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.grey,
                                        size: 50,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'No assets tracked yet.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          fontFamily: 'NotoSansJP',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredAssets.length,
                                  itemBuilder: (context, index) {
                                    final asset = filteredAssets[index];
                                    final rfid = asset['rfid_id'] ?? '-';
                                    final status = assetStatus[rfid] ?? 'Unknown';
                                    return Card(
                                      elevation: 3,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              status == 'In Range'
                                                  ? Colors.green[50]!
                                                  : Colors.red[50]!,
                                              status == 'In Range'
                                                  ? Colors.green[100]!
                                                  : Colors.red[100]!
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Name: ${asset['name'] ?? '-'}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF3A4F41),
                                                        fontSize: 14,
                                                        fontFamily:
                                                            'NotoSansJP',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'RFID: $rfid',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xFF3A4F41),
                                                          fontFamily:
                                                              'NotoSansJP'),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Status: $status',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xFF3A4F41),
                                                          fontFamily:
                                                              'NotoSansJP'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.visibility,
                                                  color: Color(0xFF3A4F41),
                                                ),
                                                onPressed: () {
                                                  _showAssetDetails(asset);
                                                },
                                                tooltip: 'View Details',
                                              ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssetDetails(Map<String, dynamic> asset) {
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
                      'Asset Details',
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                          _buildTableRow('Asset ID', asset['asset_id'] ?? '-'),
                          _buildTableRow('RFID ID', asset['rfid_id'] ?? '-', isGrey: true),
                          _buildTableRow('Asset Name', asset['name'] ?? '-'),
                          _buildTableRow('Status', asset['status'] ?? '-', isGrey: true),
                          _buildTableRow('Purchase Date', asset['purchase_date']),
                          _buildTableRow('Lifetime (Years)',
                              asset['lifetime']?.toString() ?? '-', isGrey: true),
                          _buildTableRow('Value (RM)',
                              asset['value']?.toString() ?? '-'),
                          _buildTableRow('Location', asset['location'] ?? '-', isGrey: true),
                        ],
                      ),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  TableRow _buildTableRow(String label, dynamic value, {bool isGrey = false}) {
    String displayValue;

    if (label == 'Purchase Date' && value is Timestamp) {
      final DateTime dateTime = value.toDate();
      displayValue = DateFormat('dd/MM/yyyy').format(dateTime);
    } else {
      displayValue = value?.toString() ?? '-';
    }

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
            displayValue,
            style: const TextStyle(
                fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
          ),
        ),
      ],
    );
  }
}