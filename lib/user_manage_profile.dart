import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManageProfile extends StatefulWidget {
  final String userId;

  const UserManageProfile({super.key, required this.userId});

  @override
  State<UserManageProfile> createState() => _UserManageProfileState();
}

class _UserManageProfileState extends State<UserManageProfile>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? selectedOccupation; // For dropdown

  bool isLoading = false;
  bool isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Consistent color scheme from RegularUserHomePage
  static const Color primaryGradientStart = Color(0xFFDAB894);
  static const Color primaryGradientEnd = Color(0xFF5B7A6D);
  static const Color textColor = Color(0xFF3A4F41);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // List of occupations for the dropdown
  final List<String> occupations = [
    'Engineer',
    'Manager',
    'Technician',
    'Administrator',
    'Other',
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
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        emailController.text = data['email'] ?? '';
        selectedOccupation = data['occupation'] ?? 'Other';
        phoneController.text = data['phone'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Error',
          message: 'Error fetching profile: $e',
          isSuccess: false,
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    final email = emailController.text.trim();
    final occupation = selectedOccupation ?? 'Other';
    final phone = phoneController.text.trim();

    if (!email.contains('@') || !email.endsWith('.com')) {
      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Error',
          message: 'Invalid email format!, should include @ and .com',
          isSuccess: false,
        );
      }
      return;
    }

    if (!phone.startsWith('+60')) {
      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Error',
          message: 'Phone number should start with +60!',
          isSuccess: false,
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'email': email,
        'occupation': occupation,
        'phone': phone,
      });

      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Success',
          message: 'Profile updated successfully!',
          isSuccess: true,
          onClose: () {
            setState(() {
              isEditing = false;
            });
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessageDialog(
          context,
          title: 'Error',
          message: 'Error saving profile: $e',
          isSuccess: false,
        );
      }
    }
  }

  void _showMessageDialog(BuildContext context,
      {required String title, required String message, required bool isSuccess, VoidCallback? onClose}) {
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
                  child: Text(
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

  TableRow _buildProfileRow({
    required String label,
    required TextEditingController controller,
    bool isGrey = false,
    bool isDropdown = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isGrey ? const Color(0xFFE0E0E0) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12), // Increased padding
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'NotoSansJP',
              fontSize: 16, // Larger font
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Increased vertical padding
          child: isEditing && !isDropdown
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60), // Increased height for input fields
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: textColor,
                      fontFamily: 'NotoSansJP',
                      fontSize: 16, // Larger font
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryGradientEnd, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryGradientEnd, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Increased padding
                    ),
                  ),
                )
              : isEditing && isDropdown
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 60), // Increased height for dropdown
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Adjusted padding
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          border: Border.all(color: primaryGradientEnd, width: 1.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: DropdownButtonFormField<String>( // Changed to DropdownButtonFormField for consistency
                          value: selectedOccupation,
                          icon: const Icon(Icons.arrow_drop_down, color: textColor),
                          style: const TextStyle(
                            color: textColor,
                            fontFamily: 'NotoSansJP',
                            fontSize: 16, // Larger font
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none, // Remove default border
                            contentPadding: EdgeInsets.zero, // Align content properly
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedOccupation = newValue!;
                            });
                          },
                          items: occupations.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: textColor,
                                  fontFamily: 'NotoSansJP',
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          dropdownColor: const Color(0xFFE0E0E0),
                          isExpanded: true,
                        ),
                      ),
                    )
                  : Text(
                      isDropdown
                          ? (selectedOccupation ?? '-')
                          : (controller.text.isNotEmpty ? controller.text : '-'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'NotoSansJP',
                        fontSize: 16, // Larger font
                      ),
                    ),
        ),
      ],
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
          'MANAGE PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'NotoSansJP',
            fontSize: 20, // Larger font
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGradientEnd))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGradientStart, primaryGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12), // Increased padding
                      child: const Center(
                        child: Text(
                          'User Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18, // Larger font
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: const Border.fromBorderSide(
                            BorderSide(color: primaryGradientEnd, width: 1.5)),
                      ),
                      child: Table(
                        border: const TableBorder.symmetric(
                            outside: BorderSide(color: primaryGradientEnd, width: 1.5)),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                        },
                        children: [
                          _buildProfileRow(label: 'Email', controller: emailController),
                          _buildProfileRow(
                              label: 'Phone Number', controller: phoneController, isGrey: true),
                          _buildProfileRow(
                            label: 'Occupation',
                            controller: TextEditingController(text: selectedOccupation),
                            isDropdown: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30), // Increased spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isEditing) ...[
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                              });
                              _fetchUserProfile();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: primaryGradientEnd, width: 2),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14), // Larger button
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 18, // Larger font
                                fontFamily: 'NotoSansJP',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        ElevatedButton(
                          onPressed: isEditing
                              ? saveProfile
                              : () => setState(() => isEditing = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGradientEnd,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14), // Larger button
                          ),
                          child: Text(
                            isEditing ? 'Save Profile' : 'Edit Profile',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18, // Larger font
                              fontFamily: 'NotoSansJP',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30), // Increased spacing
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}