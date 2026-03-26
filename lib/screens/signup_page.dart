import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedSex;
  String? _selectedBlood;

  // Auto-calculate age from DOB
  int _calculateAge(DateTime dob) {
    DateTime now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day))
      age--;
    return age;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedSex == null ||
        _selectedBlood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and selections.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );

      // Save complete profile with calculated age and DEFAULT "-" Vitals
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'dob': _selectedDate!.toIso8601String(),
            'age': _calculateAge(_selectedDate!).toString(),
            'sex': _selectedSex,
            'bloodGroup': _selectedBlood,
            'height': _heightCtrl.text.trim(),
            'weight': _weightCtrl.text.trim(),
            'allergies': 'None', // Default
            'vitals': {
              'heartRate': '-', // Default as requested
              'bloodPressure': '-',
              'spO2': '-',
            },
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGreen),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.glossyCardDecoration,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Complete Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Details
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDeco('Full Name', Icons.person),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: _inputDeco('Email', Icons.email),
                    validator: (v) =>
                        !v!.contains('@') ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: _inputDeco(
                      'Password (min 6 chars)',
                      Icons.lock,
                    ),
                    validator: (v) => v!.length < 6 ? 'Too short' : null,
                  ),
                  const SizedBox(height: 24),

                  // Health Demographics
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    title: const Text(
                      'Date of Birth',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                    ),
                    subtitle: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryGreen,
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _inputDeco('Sex', Icons.male),
                          items: ['Male', 'Female', 'Other']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSex = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _inputDeco('Blood Grp', Icons.water_drop),
                          items:
                              ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBlood = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('Height (cm)', Icons.height),
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('Weight (kg)', Icons.scale),
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Profile & Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
      filled: true,
      fillColor: AppTheme.pureWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
