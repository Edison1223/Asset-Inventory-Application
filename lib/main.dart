
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart'; 
import 'dart:math';
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  print('Starting app...');
  print('Checking Firebase initialization...');
  print('Firebase.apps before initialization: ${Firebase.apps}');
  if (Firebase.apps.isEmpty) {
    print('Initializing Firebase with options...');
    try {
      await Firebase.initializeApp(options: firebaseOptions);
      print('Firebase initialized successfully');
      print('Firebase.apps after initialization: ${Firebase.apps}');
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  } else {
    print('Firebase already initialized, skipping...');
    print('Firebase.apps: ${Firebase.apps}');
  }
  print('Proceeding to run app...');
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
        fontFamily: 'NotoSansJP',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B7A6D),
          primary: const Color(0xFF5B7A6D),
          secondary: const Color(0xFFDAB894),
          surface: const Color(0xFFF5F5F5),
          background: const Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _buttonSlideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with Gradient and Paper Texture
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F5F5),
                  Color(0xFFE8E8E8),
                ],
              ),
            ),
          ),
          // Animated Cherry Blossom Particles
          CherryBlossomParticles(),
          // Wavy Effect at the Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WaveBackground(),
          ),
          // Main Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _titleFadeAnimation,
                  child: Text(
                    'Asset Inventory',
                    style: TextStyle(
                      color: Color(0xFF3A4F41),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Color(0xFF5B7A6D).withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: const AppLogo(),
                ),
                SizedBox(height: 40),
                SlideTransition(
                  position: _buttonSlideAnimation,
                  child: Column(
                    children: [
                      CustomButton(
                        text: "LOGIN",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B7A6D), Color(0xFF7A9A88)],
                        ),
                      ),
                      SizedBox(height: 15),
                      CustomButton(
                        text: "EXIT",
                        onTap: () async {
                          bool? exitConfirmed = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              content: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFDAB894),
                                      Color(0xFFF5F5F5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Color(0xFF5B7A6D), width: 2),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Exit",
                                      style: TextStyle(
                                        color: Color(0xFF3A4F41),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Are you sure you want to exit?",
                                      style: TextStyle(
                                        color: Color(0xFF3A4F41),
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _DialogButton(
                                          text: "Cancel",
                                          onTap: () => Navigator.pop(context, false),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFDAB894),
                                              Color(0xFFBFA77F),
                                            ],
                                          ),
                                        ),
                                        _DialogButton(
                                          text: "Exit",
                                          onTap: () => Navigator.pop(context, true),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF5B7A6D),
                                              Color(0xFF7A9A88),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (exitConfirmed == true) {
                            SystemNavigator.pop(); // Terminate the app
                          }
                        },
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDAB894), Color(0xFFBFA77F)],
                        ),
                      ),
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
}

// Cherry Blossom Particles Animation
class CherryBlossomParticles extends StatefulWidget {
  const CherryBlossomParticles({super.key});

  @override
  _CherryBlossomParticlesState createState() => _CherryBlossomParticlesState();
}

class _CherryBlossomParticlesState extends State<CherryBlossomParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      particles.add(Particle());
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
        }
        return CustomPaint(
          painter: ParticlePainter(particles: particles),
          child: Container(),
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

  Particle()
      : x = Random().nextDouble() * 500,
        y = Random().nextDouble() * 800,
        speedX = (Random().nextDouble() - 0.5) * 0.5,
        speedY = Random().nextDouble() * 1 + 0.5,
        size = Random().nextDouble() * 5 + 3;

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

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(0xFFFFB6C1).withOpacity(0.7);
    for (var particle in particles) {
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Wave Background Animation
class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  @override
  _WaveBackgroundState createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat();
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
        return CustomPaint(
          painter: WavePainter(phase: _controller.value * 2 * pi),
          child: Container(
            height: 150,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double phase;

  WavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF5B7A6D).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x++) {
      double y = size.height * 0.7 +
          20 * sin((x / size.width) * 2 * pi + phase) +
          10 * sin((x / size.width) * 4 * pi + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow Effect
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFDAB894).withOpacity(0.3), Colors.transparent],
                stops: [0.5, 1.0],
              ),
            ),
          ),
          // Main Logo
          ClipOval(
            child: Image.asset(
              'assets/new_logo.png', // Replace with the path to your new logo
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.inventory_2,
                  size: 50,
                  color: Color(0xFF3A4F41),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Gradient gradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 180,
          height: 60,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFF3A4F41), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: Color(0xFF3A4F41),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Gradient gradient;

  const _DialogButton({
    required this.text,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF3A4F41), width: 1),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: Color(0xFF3A4F41),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}