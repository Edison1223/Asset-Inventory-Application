
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class AssetCategorizationPage extends StatefulWidget {
  final bool isAdmin;

  const AssetCategorizationPage({super.key, required this.isAdmin});

  @override
  State<AssetCategorizationPage> createState() => _AssetCategorizationPageState();
}

class _AssetCategorizationPageState extends State<AssetCategorizationPage> with SingleTickerProviderStateMixin {
  final TextEditingController _categoryNameController = TextEditingController();
  final Logger logger = Logger();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Color> categoryColors = [
    Colors.blue[300]!,
    Colors.green[300]!,
    Colors.orange[300]!,
    Colors.purple[300]!,
    Colors.red[300]!,
    Colors.teal[300]!,
    Colors.amber[300]!,
    Colors.cyan[300]!,
  ];

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

  @override
  void dispose() {
    _categoryNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Reusable method to show a styled message dialog
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
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7A6D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onClose?.call();
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

  Future<void> _createCategory() async {
    final String name = _categoryNameController.text.trim();
    if (name.isEmpty) {
      _showMessageDialog(context, title: 'Error', message: 'Please fill in the category name!', isSuccess: false);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('categories').add({'name': name, 'created_at': Timestamp.now()});
      _showMessageDialog(
        context,
        title: 'Success',
        message: 'Category created successfully!',
        isSuccess: true,
        onClose: () {
          _categoryNameController.clear();
          if (mounted) setState(() {});
        },
      );
    } catch (e) {
      logger.e('Error creating category: $e');
      _showMessageDialog(context, title: 'Error', message: 'Error creating category: $e', isSuccess: false);
    }
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    try {
      final assetsSnapshot = await FirebaseFirestore.instance.collection('assets').where('category', isEqualTo: categoryName).get();
      for (var asset in assetsSnapshot.docs) {
        await asset.reference.update({'category': null});
      }
      await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();
      _showMessageDialog(
        context,
        title: 'Success',
        message: 'Category deleted successfully!',
        isSuccess: true,
        onClose: () => mounted ? setState(() {}) : null,
      );
    } catch (e) {
      logger.e('Error deleting category: $e');
      _showMessageDialog(context, title: 'Error', message: 'Error deleting category: $e', isSuccess: false);
    }
  }

  Future<void> _assignAssetToCategory(String assetDocId, String categoryName) async {
    try {
      await FirebaseFirestore.instance.collection('assets').doc(assetDocId).update({'category': categoryName});
      _showMessageDialog(
        context,
        title: 'Success',
        message: 'Asset assigned to category successfully!',
        isSuccess: true,
        onClose: () => mounted ? setState(() {}) : null,
      );
    } catch (e) {
      logger.e('Error assigning asset to category: $e');
      _showMessageDialog(context, title: 'Error', message: 'Error assigning asset: $e', isSuccess: false);
    }
  }

  Future<void> _removeAssetCategory(String assetDocId) async {
    try {
      await FirebaseFirestore.instance.collection('assets').doc(assetDocId).update({'category': null});
      _showMessageDialog(
        context,
        title: 'Success',
        message: 'Asset category removed successfully!',
        isSuccess: true,
        onClose: () => mounted ? setState(() {}) : null,
      );
    } catch (e) {
      logger.e('Error removing asset category: $e');
      _showMessageDialog(context, title: 'Error', message: 'Error removing asset category: $e', isSuccess: false);
    }
  }

  void _showAssetDetailsDialog(BuildContext context, Map<String, dynamic> asset) {
    final purchaseDate = (asset['purchase_date'] as Timestamp?)?.toDate();
    final formattedDate = purchaseDate != null ? DateFormat('dd/MM/yyyy').format(purchaseDate) : 'Not specified';

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
                BoxShadow(color: const Color(0xFF5B7A6D).withOpacity(0.3), blurRadius: 10, offset: const Offset(3, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
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
                    columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                    children: [
                      _buildDetailRow('Asset ID', asset['asset_id'] ?? '-', isGrey: true),
                      _buildDetailRow('RFID ID', asset['rfid_id'] ?? '-'),
                      _buildDetailRow('Asset Name', asset['name'] ?? '-', isGrey: true),
                      _buildDetailRow('Status', asset['status'] ?? '-'),
                      _buildDetailRow('Purchase Date', formattedDate, isGrey: true),
                      _buildDetailRow('Lifetime (Years)', asset['lifetime']?.toString() ?? '-'),
                      _buildDetailRow('Value (RM)', asset['value']?.toString() ?? '-', isGrey: true),
                      _buildDetailRow('Location', asset['location'] ?? '-'),
                      _buildDetailRow('Category', asset['category'] ?? '-', isGrey: true),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7A6D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showUnassignedAssetsDialog(BuildContext context, String categoryName) {
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
              boxShadow: [BoxShadow(color: const Color(0xFF5B7A6D).withOpacity(0.3), blurRadius: 10, offset: const Offset(3, 3))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                  ),
                  child: const Text('Assets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('assets').where('category', isEqualTo: categoryName).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7A6D)));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No assets in this category.', style: TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')));
                      final assets = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: assets.length,
                        itemBuilder: (context, assetIndex) {
                          final asset = assets[assetIndex].data() as Map<String, dynamic>;
                          final assetId = assets[assetIndex].id;
                          final assetName = asset['name'] ?? 'Unnamed Asset';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: assetIndex % 2 == 0 ? const Color(0xFFF5F5F5) : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(assetName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                      Text('Asset ID: ${asset['asset_id'] ?? '-'}', style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Color(0xFF5B7A6D)),
                                      onPressed: () => _showAssetDetailsDialog(context, asset),
                                      tooltip: 'View Details',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async => await _removeAssetCategory(assetId),
                                      tooltip: 'Remove from Category',
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
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7A6D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showUnassignedAssetsSelectionDialog(context, categoryName),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text('Assign Asset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansJP')),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF5B7A6D), width: 2)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
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

  void _showUnassignedAssetsSelectionDialog(BuildContext context, String categoryName) {
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
              boxShadow: [BoxShadow(color: const Color(0xFF5B7A6D).withOpacity(0.3), blurRadius: 10, offset: const Offset(3, 3))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                  ),
                  child: Text(
                    'Unassigned Assets for $categoryName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('assets').where('category', isNull: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7A6D)));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No unassigned assets available.', style: TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')));
                      final assets = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: assets.length,
                        itemBuilder: (context, assetIndex) {
                          final asset = assets[assetIndex].data() as Map<String, dynamic>;
                          final assetId = assets[assetIndex].id;
                          final assetName = asset['name'] ?? 'Unnamed Asset';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: assetIndex % 2 == 0 ? const Color(0xFFF5F5F5) : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border.fromBorderSide(BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(assetName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                      Text('Asset ID: ${asset['asset_id'] ?? '-'}', style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5B7A6D),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        await _assignAssetToCategory(assetId, categoryName);
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        child: Text('Assign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansJP')),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await _removeAssetCategory(assetId);
                                        Navigator.pop(dialogContext);
                                      },
                                      tooltip: 'Remove Category',
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
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF5B7A6D), width: 2)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ASSET CATEGORIZATION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3A4F41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.isAdmin ? _buildAdminView() : _buildUserView(),
        ),
      ),
    );
  }

  Widget _buildAdminView() {
  return Column(
    children: [
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: const Center(
          child: Text('Create New Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP')),
        ),
      ),
      Table(
        border: const TableBorder.symmetric(outside: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
        children: [
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _categoryNameController,
                  style: const TextStyle(color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B7A6D), width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A4F41), width: 2)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _createCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B7A6D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        ),
        child: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansJP')),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('categories').snapshots(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7A6D)));
            }
            if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No categories available.', style: TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')));
            }
            final categories = categorySnapshot.data!.docs;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Maximum 3 squares in one horizontal row
                crossAxisSpacing: 10, // Spacing between squares horizontally
                mainAxisSpacing: 10, // Spacing between squares vertically
                childAspectRatio: 1, // Makes the tiles square (1:1 aspect ratio)
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index].data() as Map<String, dynamic>;
                final categoryName = category['name'] ?? 'Unnamed Category';
                final categoryId = categories[index].id;

                return GestureDetector(
                  onTap: () => _showUnassignedAssetsDialog(context, categoryName),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF5B7A6D), width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              categoryName,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
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
                                            'Delete Confirmation',
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
                                        Text(
                                          'Are you sure you want to delete the category "$categoryName"?',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3A4F41),
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
                                                  side: const BorderSide(color: Color(0xFF5B7A6D), width: 2),
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
                                                    color: Color(0xFF3A4F41),
                                                    fontFamily: 'NotoSansJP',
                                                  ),
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
                                                _deleteCategory(categoryId, categoryName);
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
                            },
                            tooltip: 'Delete Category',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildUserView() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('categories').snapshots(),
    builder: (context, categorySnapshot) {
      if (categorySnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7A6D)));
      }
      if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No categories available.', style: TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP')));
      }
      final categories = categorySnapshot.data!.docs;
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Maximum 3 squares in one horizontal row
          crossAxisSpacing: 10, // Spacing between squares horizontally
          mainAxisSpacing: 10, // Spacing between squares vertically
          childAspectRatio: 1, // Makes the tiles square (1:1 aspect ratio)
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index].data() as Map<String, dynamic>;
          final categoryName = category['name'] ?? 'Unnamed Category';
          final color = categoryColors[index % categoryColors.length];

          return GestureDetector(
            onTap: () {
              // Show a dialog with the assets for this category
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
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              '$categoryName Assets',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'NotoSansJP',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.maxFinite,
                            height: 300,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('assets')
                                  .where('category', isEqualTo: categoryName)
                                  .snapshots(),
                              builder: (context, assetSnapshot) {
                                if (assetSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7A6D)));
                                }
                                if (!assetSnapshot.hasData || assetSnapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No assets in this category.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF3A4F41),
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                  );
                                }
                                final assets = assetSnapshot.data!.docs;
                                return ListView.builder(
                                  itemCount: assets.length,
                                  itemBuilder: (context, assetIndex) {
                                    final asset = assets[assetIndex].data() as Map<String, dynamic>;
                                    final assetName = asset['name'] ?? 'Unnamed Asset';
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: assetIndex % 2 == 0 ? const Color(0xFFF5F5F5) : const Color(0xFFE0E0E0),
                                        borderRadius: BorderRadius.circular(10),
                                        border: const Border.fromBorderSide(
                                          BorderSide(color: Color(0xFF5B7A6D), width: 1.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  assetName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: Color(0xFF3A4F41),
                                                    fontFamily: 'NotoSansJP',
                                                  ),
                                                ),
                                                Text(
                                                  'Asset ID: ${asset['asset_id'] ?? '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF3A4F41),
                                                    fontFamily: 'NotoSansJP',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: Color(0xFF5B7A6D)),
                                            onPressed: () => _showAssetDetailsDialog(context, asset),
                                            tooltip: 'View Details',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B7A6D),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5B7A6D), width: 1.5),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A4F41),
                      fontFamily: 'NotoSansJP',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  TableRow _buildDetailRow(String label, String value, {bool isGrey = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isGrey ? const Color(0xFFE0E0E0) : Colors.white),
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'))),
        Padding(padding: const EdgeInsets.all(8), child: Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF3A4F41), fontFamily: 'NotoSansJP'))),
      ],
    );
  }
}