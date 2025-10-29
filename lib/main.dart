import 'package:civil_road_app/case2_screen.dart';
import 'package:flutter/material.dart';
import 'package:civil_road_app/case1_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civil Road Project',
      theme: ThemeData(
        primaryColor: const Color(0xFF19183B), // Dark navy
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF19183B)),
          bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF19183B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            backgroundColor: const Color(0xFF2F3E46), // Dark grey
            foregroundColor: const Color(0xFFE7F2EF),
          ),
        ),
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
      appBar: AppBar(
        title: const Text('Civil Road Project'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.black, // Dark navy
        foregroundColor: const Color(0xFFE7F2EF), // Light gray-green
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Case1Screen()),
                  );
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1C2526), // Very dark grey
                    Color(0xFF2F3E46), // Dark grey
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.analytics,
                text: 'Case 1',
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                  onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Case2Screen()),
                  );
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2F3E46), // Dark grey
                    Color(0xFF354F52), // Slightly darker grey with a hint of teal
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.build,
                text: 'Case 2',
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Economic Analysis not implemented yet'),
                      backgroundColor: Color(0xFF19183B),
                    ),
                  );
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF354F52), // Dark grey with teal hint
                    Color(0xFF1C2526), // Very dark grey
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.calculate,
                text: 'Economic Analysis',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final LinearGradient gradient;
  final IconData icon;
  final String text;

  const AnimatedButton({
    super.key,
    required this.onTap,
    required this.gradient,
    required this.icon,
    required this.text,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: const Color(0xFFE7F2EF), size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE7F2EF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}