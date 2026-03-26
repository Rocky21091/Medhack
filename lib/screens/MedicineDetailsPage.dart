import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class MedicineDetailsPage extends StatelessWidget {
  final Map<String, dynamic> medicineData;

  const MedicineDetailsPage({super.key, required this.medicineData});

  // --- HACKATHON REMINDER BOTTOM SHEET ---
  void _showReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _ReminderBottomSheet(medicineName: medicineData['name']),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? MediaQuery.of(context).size.width * 0.15
              : 24.0,
          vertical: 24.0,
        ),
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  // ==========================================
  // 1. MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildAbout(),
        const SizedBox(height: 24),
        _buildGrid(),
        const SizedBox(height: 24),
        _buildSideEffects(),
        const SizedBox(height: 40),
        _buildActionButton(context),
      ],
    );
  }

  // ==========================================
  // 2. DESKTOP LAYOUT
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildAbout(),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGrid(),
              const SizedBox(height: 24),
              _buildSideEffects(),
              const SizedBox(height: 40),
              _buildActionButton(context),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_liquid_rounded,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            medicineData['name'] ?? 'Unknown Medicine',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            medicineData['purpose'] ?? '',
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "About",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          medicineData['description'] ?? 'No description available.',
          style: const TextStyle(
            color: AppTheme.textGrey,
            height: 1.6,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                Icons.vaccines,
                'Dosage',
                medicineData['dosage'],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridItem(
                Icons.family_restroom,
                'Age Limit',
                medicineData['ageLimit'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                Icons.access_time,
                'Frequency',
                medicineData['frequency'],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridItem(
                Icons.info_outline,
                'Usage',
                medicineData['usage'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, String? value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideEffects() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Side Effects: ${medicineData['sideEffects'] ?? 'None documented'}",
              style: const TextStyle(color: Colors.redAccent, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showReminderSheet(context),
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text(
          'Set Schedule & Reminder',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: AppTheme.pureWhite,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ==========================================
// BOTTOM SHEET (Now with Custom Timings!)
// ==========================================
class _ReminderBottomSheet extends StatefulWidget {
  final String medicineName;
  const _ReminderBottomSheet({required this.medicineName});

  @override
  State<_ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<_ReminderBottomSheet> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));

  List<String> selectedTimes = [];
  List<String> availableTimes = [
    "08:00 AM",
    "01:00 PM",
    "08:00 PM",
  ]; // Defaults
  bool _isLoadingTimes = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCustomTimes();
  }

  // Fetch the user's personally saved times from Firestore
  Future<void> _fetchUserCustomTimes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          List<dynamic>? savedTimes = doc.data()?['customTimes'];
          if (savedTimes != null && savedTimes.isNotEmpty) {
            setState(() {
              availableTimes = List<String>.from(savedTimes);
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching times: $e");
      }
    }
    setState(() => _isLoadingTimes = false);
  }

  // Format the TimeOfDay to a beautiful string (e.g., "08:30 AM")
  String _formatTime(TimeOfDay time) {
    final hr = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "${hr.toString().padLeft(2, '0')}:$min $period";
  }

  // Open the clock and save the new time to Firestore
  Future<void> _addCustomTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String newTime = _formatTime(picked);

      if (!availableTimes.contains(newTime)) {
        setState(() {
          availableTimes.add(newTime);
          selectedTimes.add(newTime); // Auto-select the newly added time
        });

        // Save this new array to the user's profile so it's there next time they login!
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set(
            {'customTimes': availableTimes},
            SetOptions(merge: true),
          ); // Merge prevents overwriting the rest of their profile
        }
      }
    }
  }

  Future<void> _saveReminder() async {
    if (selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reminders').add({
        'userId':
            FirebaseAuth.instance.currentUser?.uid, // Locked to this user!
        'medicineName': widget.medicineName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'times': selectedTimes,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder Scheduled Successfully!')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving reminder: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Reminder',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // Date Pickers
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  title: const Text(
                    'Start Date',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                  subtitle: Text(
                    "${startDate.day}/${startDate.month}/${startDate.year}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryGreen,
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => startDate = picked);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  title: const Text(
                    'End Date',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                  subtitle: Text(
                    "${endDate.day}/${endDate.month}/${endDate.year}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryGreen,
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => endDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- CUSTOM TIMINGS SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Timings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
              // The Add Custom Time Button
              TextButton.icon(
                onPressed: _addCustomTime,
                icon: const Icon(Icons.add_alarm_rounded, size: 18),
                label: const Text('Add Time'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _isLoadingTimes
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableTimes.map((time) {
                    bool isSelected = selectedTimes.contains(time);
                    return FilterChip(
                      label: Text(
                        time,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: AppTheme.backgroundLight,
                      selectedColor: AppTheme.lightGreen,
                      checkmarkColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedTimes.add(time);
                          } else {
                            selectedTimes.remove(time);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
          const SizedBox(height: 40),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save Reminder',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
