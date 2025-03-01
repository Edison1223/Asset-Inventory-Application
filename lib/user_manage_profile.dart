import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManageProfile extends StatefulWidget {
  final String userId; // Accept userId as a parameter

  const UserManageProfile({super.key, required this.userId});

  @override
  State<UserManageProfile> createState() => _UserManageProfileState();
}

class _UserManageProfileState extends State<UserManageProfile> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;
  bool isEditing = false; // Track whether the user is in edit mode

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch the user's profile when the page loads
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
        occupationController.text = data['occupation'] ?? '';
        phoneController.text = data['phone'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
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
    final occupation = occupationController.text.trim();
    final phone = phoneController.text.trim();

    // Validate email and phone number
    if (!email.contains('@') || !email.endsWith('.com')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
    content: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Dark background like buttons
        borderRadius: BorderRadius.circular(8), // ✅ Rounded corners
        boxShadow: [ // ✅ Soft shadow effect
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Invalid email format!',
        style: TextStyle(
          color: Colors.red, // ✅ White text for contrast
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    backgroundColor: Colors.transparent, // ✅ Remove default background
    elevation: 0, // ✅ Remove default shadow
    behavior: SnackBarBehavior.floating, // ✅ Make it float above UI
    margin: const EdgeInsets.all(16), // ✅ Add spacing
    duration: const Duration(seconds: 2), // ✅ Control duration
  ),
        );
      }
      return;
    }

    if (!phone.startsWith('+60')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
    content: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Dark background like buttons
        borderRadius: BorderRadius.circular(8), // ✅ Rounded corners
        boxShadow: [ // ✅ Soft shadow effect
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Phone number should start from +60!',
        style: TextStyle(
          color: Colors.red, // ✅ White text for contrast
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    backgroundColor: Colors.transparent, // ✅ Remove default background
    elevation: 0, // ✅ Remove default shadow
    behavior: SnackBarBehavior.floating, // ✅ Make it float above UI
    margin: const EdgeInsets.all(16), // ✅ Add spacing
    duration: const Duration(seconds: 2), // ✅ Control duration
  ),
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
    content: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Dark background like buttons
        borderRadius: BorderRadius.circular(8), // ✅ Rounded corners
        boxShadow: [ // ✅ Soft shadow effect
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Profile updated successfully!',
        style: TextStyle(
          color: Colors.lightGreen, // ✅ White text for contrast
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    backgroundColor: Colors.transparent, // ✅ Remove default background
    elevation: 0, // ✅ Remove default shadow
    behavior: SnackBarBehavior.floating, // ✅ Make it float above UI
    margin: const EdgeInsets.all(16), // ✅ Add spacing
    duration: const Duration(seconds: 2), // ✅ Control duration
  ),
        );

        setState(() {
          isEditing = false; // Exit edit mode
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
    content: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Dark background like buttons
        borderRadius: BorderRadius.circular(8), // ✅ Rounded corners
        boxShadow: [ // ✅ Soft shadow effect
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Error saving profile!',
        style: TextStyle(
          color: Colors.red, // ✅ White text for contrast
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    backgroundColor: Colors.transparent, // ✅ Remove default background
    elevation: 0, // ✅ Remove default shadow
    behavior: SnackBarBehavior.floating, // ✅ Make it float above UI
    margin: const EdgeInsets.all(16), // ✅ Add spacing
    duration: const Duration(seconds: 2), // ✅ Control duration
  ),
        );
      }
    }
  }

Widget _buildProfileRow({
  required String label,
  required TextEditingController controller,
  bool isGrey = false,
}) {
  return Container(
    color: isGrey ? Colors.grey[200] : Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        isEditing
            ? SizedBox(
                width: 200,
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              )
            : Text(
                controller.text.isNotEmpty ? controller.text : '-',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ],
    ),
  );
}









  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.grey[400],
        elevation: 0,
        title: const Text(
          'MANAGE PROFILE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Center(
                      child: Text(
                        'User Detail',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Container(
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
  ),
  
child: Column( // ✅ Corrected
    children: [
      _buildProfileRow(label: 'Email', controller: emailController),
      _buildProfileRow(label: 'Phone Number', controller: phoneController, isGrey: true),
      _buildProfileRow(label: 'Occupation', controller: occupationController),
    ],
  ),



),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isEditing ? saveProfile : () => setState(() => isEditing = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                    child: Text(
                      isEditing ? 'Save Profile' : 'Edit Profile',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
