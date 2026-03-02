
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AssetRegistrationPage extends StatefulWidget {
  const AssetRegistrationPage({super.key});

  @override
  State<AssetRegistrationPage> createState() => _AssetRegistrationPageState();
}

class _AssetRegistrationPageState extends State<AssetRegistrationPage> with SingleTickerProviderStateMixin {
  final CollectionReference assetsCollection = FirebaseFirestore.instance.collection('assets');

  final TextEditingController assetIdController = TextEditingController();
  final TextEditingController rfidIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController lifetimeController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController categoryController = TextEditingController(text: '-'); // Read-only category field

  String selectedStatus = 'Active'; // Default Status
  DateTime? selectedPurchaseDate; // Store the selected DateTime
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    assetIdController.dispose();
    rfidIdController.dispose();
    nameController.dispose();
    purchaseDateController.dispose();
    lifetimeController.dispose();
    valueController.dispose();
    locationController.dispose();
    categoryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B7A6D),
              onPrimary: Colors.white,
              surface: Color(0xFFF5F5F5),
              onSurface: Color(0xFF3A4F41),
            ),
            dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFF5F5F5)),
          ),
          child: child!,
        );
      },
    );

    setState(() {
      selectedPurchaseDate = pickedDate;
      purchaseDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate!);
    });
    }

  void _showMessageDialog(BuildContext context, {required String message, required bool isSuccess}) {
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
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSuccess) ...[
                          const Icon(Icons.check_circle, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          isSuccess ? 'Success' : 'Error',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
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
      },
    );
  }

  Future<void> registerAsset() async {
    final assetId = assetIdController.text.trim();
    final rfid = rfidIdController.text.trim();
    final name = nameController.text.trim();
    final status = selectedStatus;
    final lifetimeText = lifetimeController.text.trim();
    final valueText = valueController.text.trim();
    final location = locationController.text.trim();

    if (assetId.isEmpty ||
        rfid.isEmpty ||
        name.isEmpty ||
        selectedPurchaseDate == null ||
        lifetimeText.isEmpty ||
        valueText.isEmpty ||
        location.isEmpty) {
      _showMessageDialog(context, message: 'All fields must be filled!', isSuccess: false);
      return;
    }

    double? lifetime = double.tryParse(lifetimeText);
    double? value = double.tryParse(valueText);

    if (lifetime == null) {
      _showMessageDialog(context, message: 'Lifetime must be a valid decimal number!', isSuccess: false);
      return;
    }

    if (value == null) {
      _showMessageDialog(context, message: 'Value must be a valid decimal number!', isSuccess: false);
      return;
    }

    try {
      await assetsCollection.add({
        'asset_id': assetId,
        'rfid_id': rfid,
        'name': name,
        'status': status,
        'purchase_date': Timestamp.fromDate(selectedPurchaseDate!),
        'lifetime': lifetime,
        'value': value,
        'location': location,
        'category': null,
        'created_at': Timestamp.now(),
      });
      if (!mounted) return;
      _showMessageDialog(context, message: 'Asset registered successfully!', isSuccess: true);

      assetIdController.clear();
      rfidIdController.clear();
      nameController.clear();
      purchaseDateController.clear();
      lifetimeController.clear();
      valueController.clear();
      locationController.clear();
      setState(() {
        selectedStatus = 'Active';
        selectedPurchaseDate = null;
      });
    } catch (e) {
      _showMessageDialog(context, message: 'Error saving asset!', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ASSET REGISTRATION',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP', fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3A4F41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Center(
                    child: Text(
                      'Asset Details',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP', fontSize: 18),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                    border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
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
                      0: FlexColumnWidth(2.5),
                      1: FixedColumnWidth(1),
                      2: FlexColumnWidth(3),
                    },
                    children: [
                      _buildTableRow('Asset ID', assetIdController),
                      _buildTableRow('RFID ID', rfidIdController, isGrey: true),
                      _buildTableRow('Asset Name', nameController),
                      _buildDropdownRow('Status', ['Active', 'Inactive']),
                      _buildDateRow('Purchase Date', purchaseDateController, () => _selectPurchaseDate(context)),
                      _buildTableRow('Lifetime (Years)', lifetimeController, isGrey: true, isNumeric: true),
                      _buildTableRow('Value (RM)', valueController, isNumeric: true),
                      _buildTableRow('Location', locationController, isGrey: true),
                      _buildReadOnlyRow('Category', categoryController, isGrey: true),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ElevatedButton(
                        onPressed: () {
                          _animationController.reverse().then((_) {
                            _animationController.forward();
                            registerAsset();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7A6D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        ),
                        child: const Text(
                          'Register Asset',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP', fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, TextEditingController controller, {bool isGrey = false, bool isNumeric = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isGrey ? const Color(0xFFE0E0E0) : Colors.white,
      ),
      children: [
        _buildTableCell(label),
        _buildSeparator(),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, minHeight: 60),
              child: TextField(
                controller: controller,
                keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP', fontSize: 16),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildReadOnlyRow(String label, TextEditingController controller, {bool isGrey = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isGrey ? const Color(0xFFE0E0E0) : Colors.white,
      ),
      children: [
        _buildTableCell(label),
        _buildSeparator(),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, minHeight: 60),
              child: TextField(
                controller: controller,
                enabled: false,
                style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP', fontSize: 16),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildDropdownRow(String label, List<String> options) {
    return TableRow(
      children: [
        _buildTableCell(label),
        _buildSeparator(),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, minHeight: 60),
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                items: options.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option, style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP', fontSize: 16)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                dropdownColor: const Color(0xFFF5F5F5),
                isExpanded: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildDateRow(String label, TextEditingController controller, VoidCallback onTap) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildTableCell(label),
        _buildSeparator(),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, minHeight: 60),
              child: GestureDetector(
                onTap: onTap,
                child: AbsorbPointer(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP', fontSize: 16),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      hintText: 'Select Date',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP', fontSize: 16),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(color: const Color(0xFF5B7A6D), width: 1, height: 70);
  }
}