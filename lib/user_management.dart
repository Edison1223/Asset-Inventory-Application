import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// **Show User Details**
void showUserInfo(BuildContext context, Map<String, dynamic> user) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // ✅ Soft rounded corners
      child: Container(
        width: 320, // ✅ Compact width
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4), // ✅ Shadow instead of border
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// **Title Header**
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.brown[200], // ✅ Beige header
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${user['username']} Details',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            /// **User Details Table**
            Table(
              border: TableBorder.all(color: Colors.black12, width: 1), // ✅ Light border for table
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(1), // ✅ First column (Label)
                1: FlexColumnWidth(2), // ✅ Second column (Value)
              },
              children: [
                _buildTableRow('Username', user['username']),
                _buildTableRow('Password', user['password']),
                _buildTableRow('Phone Number', user['phone'] ?? '-'),
                _buildTableRow('Email', user['email'] ?? '-'),
                _buildTableRow('Occupation', user['occupation'] ?? '-'),
              ],
            ),
            const SizedBox(height: 16),

            /// **Close Button**
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200], // ✅ Light grey like image
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// **Helper Function to Build Table Row**
TableRow _buildTableRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value),
      ),
    ],
  );
}

  /// **Edit User**
void editUser(BuildContext context, String userId, Map<String, dynamic> user) {
  final usernameController = TextEditingController(text: user['username']);
  final passwordController = TextEditingController(text: user['password']);

  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320, // ✅ Compact width
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [ // ✅ Soft shadow instead of border
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// **Title Section**
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.brown[200], // ✅ Beige header
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Edit user account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            /// **Input Fields**
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// **Buttons**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200], // ✅ Light gray like image
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newUsername = usernameController.text.trim();
                    final newPassword = passwordController.text.trim();

                    if (newUsername.isEmpty || newPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all fields')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance.collection('users').doc(userId).update({
                      'username': newUsername,
                      'password': newPassword,
                    });

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
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
        'User updated successfully!',
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

                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // ✅ Dark like the image
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void deleteUser(BuildContext context, String userId) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // ✅ Soft rounded corners
      child: Container(
        width: 300, // ✅ Compact width
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4), // ✅ Shadow instead of border
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// **Title Header**
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.brown[200], // ✅ Beige header
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Delete user account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            /// **Message**
            const Text(
              'Are you sure you want to delete this user?',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            /// **Buttons**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// **Cancel Button**
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200], // ✅ Light grey like image
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('CANCEL'),
                ),

                /// **Delete Button**
                ElevatedButton(
                  onPressed: () async {
                    await usersCollection.doc(userId).delete();

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
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
        'User deleted successfully!',
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

                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // ✅ Dark like image
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('DELETE'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


  /// **Add New User**
void addUser(BuildContext context) {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320, // ✅ Compact width
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [ // ✅ Soft shadow instead of border
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// **Title Section (Same as Image)**
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.brown[200], // ✅ Same as image
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Create user account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            /// **Input Fields**
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              /// **Buttons (Same Style as Image)**
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200], // ✅ Light gray like image
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final username = usernameController.text.trim();
                      final password = passwordController.text.trim();

                      if (username.isEmpty || password.isEmpty) {
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
        'Please fill in all fields!',
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

                        return;
                      }

                      await usersCollection.add({
                        'username': username,
                        'password': password,
                        'created_at': Timestamp.now(),
                      });

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
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
        'User added successfully!',
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

                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // ✅ Dark like the image
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('CREATE'),
                  ),
                ],
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
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'USER MANAGEMENT',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// **Add User Button**
        Align(
  alignment: Alignment.centerRight,
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 2), // Border color and thickness
      borderRadius: BorderRadius.circular(8), // Rounded corners
    ),
    child: TextButton(
      onPressed: () => addUser(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black, // Change text color
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Add padding inside
      ),
      child: const Text('➕ Add User'),
    ),
  ),
),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                      ),
                      child: const Text(
                        'All users',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: usersCollection.orderBy('created_at', descending: true).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('No users found.'));
                          }

                          final users = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index].data() as Map<String, dynamic>;
                              final userId = users[index].id;

                     return Container(
  decoration: BoxDecoration(
    color: index % 2 == 0 ? Colors.grey[200] : Colors.grey[350], // ✅ Alternating colors
    borderRadius: BorderRadius.circular(8), // ✅ Rounded corners
  ),
  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // ✅ Spacing for clarity
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // ✅ Consistent padding
    title: Text(user['username'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)), // ✅ Bold username
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.info), onPressed: () => showUserInfo(context, user)),
        IconButton(icon: const Icon(Icons.edit), onPressed: () => editUser(context, userId, user)),
        IconButton(icon: const Icon(Icons.delete), onPressed: () => deleteUser(context, userId)),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
