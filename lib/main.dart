import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyAF4HZ2-r7Br5tBwXc5uZUI07CaT8wlK3k",
  authDomain: "assetinventoryapplication.firebaseapp.com",
  projectId: "assetinventoryapplication",
  storageBucket: "assetinventoryapplication.appspot.com",
  messagingSenderId: "348593158588",
  appId: "1:348593158588:android:cec127ecdbc03851f0d3b9",
  measurementId: "G-EXAMPLE",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asset Inventory App',
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9), // Background color
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Title
            const Text(
              'Asset Inventory Application',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'Kumar One',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Logo (Rounded Square with Circle & Icon)
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rounded Square
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFA858), Color(0xFFFD6A6A)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // Circle (Overlay with Icon)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE08AE9), Color(0xFF7D1E9B)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.inventory_2, // Inventory Icon
                        size: 35,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LOGIN Button
            CustomButton(
              text: "LOGIN",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
            const SizedBox(height: 10),

            // EXIT Button
            CustomButton(
              text: "EXIT",
              onTap: () async {
                bool? exitConfirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Exit"),
                    content: const Text("Are you sure you want to exit?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Exit"),
                      ),
                    ],
                  ),
                );

                if (exitConfirmed == true && context.mounted) {
                  // Closes the app safely
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CustomButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 45,
        decoration: ShapeDecoration(
          color: const Color(0xFFE9DEDE),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 2), // Thicker Border
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF070707),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
