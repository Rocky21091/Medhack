import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    // 1. Get the current logged-in user's UID
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    // 2. Wrap the UI in a StreamBuilder to fetch their specific data
    return StreamBuilder<DocumentSnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : null,
      builder: (context, snapshot) {
        // Default Fallback Data (Shows while loading or if guest)
        String name = "Guest";
        String hr = "--";
        String bp = "--";
        String spo2 = "--";

        String getGreeting() {
          final hour = DateTime.now().hour;

          if (hour < 12) {
            return 'Good morning,';
          } else if (hour < 17) {
            return 'Good afternoon,';
          } else if (hour < 21) {
            return 'Good evening,';
          } else {
            return 'Good night,';
          }
        }

        // Extract real data if the document exists
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? 'User'; // Gets the name from signup

          var vitals = data['vitals'] ?? {};
          hr = vitals['heartRate'] ?? '--';
          bp = vitals['bloodPressure'] ?? '--';
          spo2 = vitals['spO2'] ?? '--';
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: isDesktop ? 800 : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: GREETING ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getGreeting(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Dynamic Name Injection!
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.lightGreen,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- SECTION: LIVE VITALS ---
                  const Text(
                    'Today\'s Vitals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Dynamic Vitals Injection!
                      Expanded(
                        child: _buildVitalCard(
                          'Heart Rate',
                          hr,
                          'bpm',
                          Icons.favorite_rounded,
                          Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVitalCard(
                          'Blood Pres',
                          bp,
                          'mmHg',
                          Icons.bloodtype_rounded,
                          AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVitalCard(
                          'SpO2',
                          spo2,
                          '%',
                          Icons.air_rounded,
                          Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- SECTION: HERO ACTION CARD (SCANNER) ---
                  GestureDetector(
                    onTap: () => context.push('/scan'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.pureWhite.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: AppTheme.pureWhite,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan Medicine',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Identify pills & check expiry via camera',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppTheme.pureWhite,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- SECTION: QUICK ACCESS ---
                  const Text(
                    'Health Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      _buildServiceTile(
                        context,
                        'MedAI Triage',
                        'Check symptoms',
                        Icons.smart_toy_rounded,
                        () => context.push('/ai-chat'),
                      ),
                      _buildServiceTile(
                        context,
                        'Med History',
                        'Past diagnoses',
                        Icons.history_rounded,
                        () => context.push('/history'),
                      ),
                      _buildServiceTile(
                        context,
                        'IoT Devices',
                        'Manage watches',
                        Icons.watch_rounded,
                        () => context.push('/iot'),
                      ),
                      _buildServiceTile(
                        context,
                        'Find Pharmacy',
                        'Near you',
                        Icons.local_pharmacy_rounded,
                        () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- REUSABLE UI WIDGETS ---

  Widget _buildVitalCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 8,
      ), // Slightly reduced horizontal padding to fit smaller screens
      decoration: AppTheme.glossyCardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                fontSize: 13,
              ),
            ), // slightly smaller text to prevent overflow
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
