import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class LocationServicesPage extends StatelessWidget {
  const LocationServicesPage({super.key});

  // The free Hackathon Magic: Opening native Google Maps with a search query!
  Future<void> _openMapSearch(String query) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query+near+me',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch map');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Find Medical Care',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: isDesktop ? 800 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- URGENT CARE CARDS ---
                const Text(
                  'Emergency & Urgent',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Nearest Hospital',
                        'Open 24/7',
                        Icons.local_hospital_rounded,
                        Colors.redAccent,
                        () => _openMapSearch('hospital'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        'Pharmacy',
                        'Buy medicines',
                        Icons.local_pharmacy_rounded,
                        AppTheme.primaryGreen,
                        () => _openMapSearch('pharmacy'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- SPECIALIST FINDER ---
                const Text(
                  'Find a Specialist',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.glossyCardDecoration,
                  child: Column(
                    children: [
                      _buildSpecialistTile(
                        'Cardiologist',
                        'Heart & Blood Pressure',
                        Icons.favorite_rounded,
                        () => _openMapSearch('Cardiologist'),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      _buildSpecialistTile(
                        'Dermatologist',
                        'Skin, Hair & Nails',
                        Icons.face_retouching_natural_rounded,
                        () => _openMapSearch('Dermatologist'),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      _buildSpecialistTile(
                        'Pediatrician',
                        'Child Healthcare',
                        Icons.child_care_rounded,
                        () => _openMapSearch('Pediatrician'),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      _buildSpecialistTile(
                        'Orthopedic',
                        'Bones & Joints',
                        Icons.accessible_forward_rounded,
                        () => _openMapSearch('Orthopedic Doctor'),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      _buildSpecialistTile(
                        'Neurologist',
                        'Brain & Nerves',
                        Icons.psychology_rounded,
                        () => _openMapSearch('Neurologist'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistTile(
    String name,
    String desc,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: AppTheme.lightGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryGreen),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.location_on_rounded,
        color: AppTheme.primaryGreen,
      ),
      onTap: onTap,
    );
  }
}
