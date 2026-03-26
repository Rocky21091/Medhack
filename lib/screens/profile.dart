import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

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
          'My Profile',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppTheme.primaryGreen,
            ),
            tooltip: 'Change Password',
            onPressed: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text('Profile not found.'));

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: isDesktop ? 800 : double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileHeader(
                      context,
                      isDesktop,
                      userData,
                      currentUser.email ?? '',
                    ),
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Health Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHealthDetailsGrid(isDesktop, userData),
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Health Tracking',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildVitalsAndHistoryCard(context, userData),
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'IoT Devices',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: AppTheme.glossyCardDecoration,
                      child: Column(
                        children: [
                          _buildDeviceTile(
                            deviceName: 'Apple Watch',
                            deviceType: 'Heart Rate & SpO2',
                            icon: Icons.watch_rounded,
                            isConnected: false,
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          _buildDeviceTile(
                            deviceName: 'Omron BP Monitor',
                            deviceType: 'Blood Pressure',
                            icon: Icons.bloodtype_rounded,
                            isConnected: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.redAccent.shade700.withOpacity(0.5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _showLogoutConfirmation(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildProfileHeader(
    BuildContext context,
    bool isDesktop,
    Map<String, dynamic> userData,
    String email,
  ) {
    Widget avatar = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryGreen, width: 3),
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: AppTheme.lightGreen,
        child: Icon(
          Icons.person_rounded,
          size: 50,
          color: AppTheme.primaryGreen,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glossyCardDecoration,
      child: isDesktop
          ? Row(
              children: [
                avatar,
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? 'User',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileSheet(context, userData),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.pureWhite,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                avatar,
                const SizedBox(height: 16),
                Text(
                  userData['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileSheet(context, userData),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.pureWhite,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHealthDetailsGrid(
    bool isDesktop,
    Map<String, dynamic> userData,
  ) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildInfoCard(
          'Age',
          '${userData['age'] ?? '-'} Yrs',
          Icons.cake_rounded,
        ),
        _buildInfoCard('Sex', userData['sex'] ?? '-', Icons.male_rounded),
        _buildInfoCard(
          'Blood',
          userData['bloodGroup'] ?? '-',
          Icons.water_drop_rounded,
        ),
        _buildInfoCard(
          'Height',
          '${userData['height'] ?? '-'} cm',
          Icons.height_rounded,
        ),
        _buildInfoCard(
          'Weight',
          '${userData['weight'] ?? '-'} kg',
          Icons.scale_rounded,
        ),
        _buildInfoCard(
          'Allergies',
          userData['allergies'] ?? 'None',
          Icons.coronavirus_rounded,
        ),
      ],
    );
  }

  Widget _buildVitalsAndHistoryCard(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    var vitals = userData['vitals'] ?? {};
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glossyCardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniVital(
                'Heart',
                '${vitals['heartRate'] ?? '-'} bpm',
                Icons.favorite,
                Colors.redAccent,
              ),
              _buildMiniVital(
                'BP',
                vitals['bloodPressure'] ?? '-',
                Icons.bloodtype,
                AppTheme.primaryGreen,
              ),
              _buildMiniVital(
                'SpO2',
                '${vitals['spO2'] ?? '-'}%',
                Icons.air,
                Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.history_rounded),
              label: const Text(
                'View Medical History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightGreen,
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed: () => context.push('/history'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniVital(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glossyCardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile({
    required String deviceName,
    required String deviceType,
    required IconData icon,
    required bool isConnected,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isConnected
            ? AppTheme.lightGreen
            : Colors.grey.shade100,
        child: Icon(
          icon,
          color: isConnected ? AppTheme.primaryGreen : Colors.grey,
        ),
      ),
      title: Text(
        deviceName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(deviceType, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        isConnected ? 'Connected' : '-',
        style: TextStyle(
          color: isConnected ? AppTheme.primaryGreen : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- EDIT PROFILE MODAL ---
  void _showEditProfileSheet(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    final nameCtrl = TextEditingController(text: userData['name']);
    final ageCtrl = TextEditingController(
      text: userData['age']?.toString(),
    ); // 🚨 ADDED AGE CONTROL
    final heightCtrl = TextEditingController(text: userData['height']);
    final weightCtrl = TextEditingController(text: userData['weight']);
    final allergiesCtrl = TextEditingController(text: userData['allergies']);

    String? selectedSex = userData['sex'];
    String? selectedBlood = userData['bloodGroup'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedSex,
                      decoration: const InputDecoration(labelText: 'Sex'),
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) => selectedSex = val,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedBlood,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                      ),
                      items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) => selectedBlood = val,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageCtrl,
                      decoration: const InputDecoration(labelText: 'Age (Yrs)'),
                      keyboardType: TextInputType.number,
                    ),
                  ), // 🚨 ADDED AGE UI
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: allergiesCtrl,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({
                          'name': nameCtrl.text.trim(),
                          'age': ageCtrl.text.trim(), // 🚨 ADDED AGE DB UPDATE
                          'sex': selectedSex,
                          'bloodGroup': selectedBlood,
                          'height': heightCtrl.text.trim(),
                          'weight': weightCtrl.text.trim(),
                          'allergies': allergiesCtrl.text.trim(),
                        });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- CHANGE PASSWORD DIALOG ---
  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter new password (min 6 chars)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser!.updatePassword(
                  passCtrl.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT FUNCTION ---
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
