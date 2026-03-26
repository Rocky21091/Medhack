import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Email or Password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.glossyCardDecoration,
            child: Column(
              children: [
                const Icon(
                  Icons.health_and_safety_rounded,
                  size: 60,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // --- EMAIL FIELD ---
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),

                // --- QUICK DOMAIN CHIPS ---
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: ['@gmail.com', '@yahoo.com', '@outlook.com'].map((
                    domain,
                  ) {
                    return ActionChip(
                      label: Text(
                        domain,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      backgroundColor: AppTheme.lightGreen,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: () {
                        // Only append if they haven't typed an '@' symbol yet
                        if (!_emailController.text.contains('@')) {
                          setState(() {
                            _emailController.text =
                                _emailController.text + domain;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // --- PASSWORD FIELD ---
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 32),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- SIGN UP LINK ---
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text(
                    'Create an Account',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
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
}
