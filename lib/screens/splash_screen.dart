import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // Navigate to Login after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/login');
      // if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [AppTheme.pureWhite, AppTheme.backgroundLight],
            radius: 1.0,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 80,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MedHack',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Scan · Diagnose · Monitor · Act',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
