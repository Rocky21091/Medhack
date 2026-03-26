import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 240.0,
    ).animate(_animationController);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.isInitialized) {
      return;
    }
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _cameraController.start();
        break;
      case AppLifecycleState.inactive:
        _cameraController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  // Search medicine in Firebase by barcode or name
  Future<Map<String, dynamic>?> _searchMedicineInFirebase(
    String searchTerm,
  ) async {
    try {
      // First try to search by barcode
      QuerySnapshot barcodeQuery = await FirebaseFirestore.instance
          .collection('medicines')
          .where('barcode', isEqualTo: searchTerm)
          .limit(1)
          .get();

      if (barcodeQuery.docs.isNotEmpty) {
        return barcodeQuery.docs.first.data() as Map<String, dynamic>;
      }

      // Then try to search by name or searchKey
      QuerySnapshot nameQuery = await FirebaseFirestore.instance
          .collection('medicines')
          .where('searchKey', isEqualTo: searchTerm.toLowerCase())
          .limit(1)
          .get();

      if (nameQuery.docs.isNotEmpty) {
        return nameQuery.docs.first.data() as Map<String, dynamic>;
      }

      // Try partial match on name
      QuerySnapshot partialQuery = await FirebaseFirestore.instance
          .collection('medicines')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .limit(1)
          .get();

      if (partialQuery.docs.isNotEmpty) {
        return partialQuery.docs.first.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print("Error searching Firebase: $e");
      return null;
    }
  }

  // Search medicine online using OpenFDA API or Google Search
  Future<Map<String, dynamic>> _searchMedicineOnline(
    String medicineName,
  ) async {
    try {
      // Try OpenFDA API first
      final url = Uri.parse(
        "https://api.fda.gov/drug/label.json?search=openfda.brand_name:$medicineName&limit=1",
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return {
            'name': medicineName,
            'description':
                result['indications_and_usage']?[0] ??
                'No description available',
            'purpose': result['purpose']?[0] ?? 'Medicine',
            'sideEffects':
                result['adverse_reactions']?[0] ??
                'Consult your doctor for side effects',
            'dosage':
                result['dosage_and_administration']?[0] ??
                'Follow doctor\'s prescription',
            'type': 'Tablet',
            'ageLimit': 'Consult doctor',
            'frequency': 'As prescribed',
            'usage': 'Take as directed by healthcare provider',
            'source': 'online',
          };
        }
      }

      // Fallback to structured data based on medicine name
      return _getMedicineDetailsFromName(medicineName);
    } catch (e) {
      print("Online search error: $e");
      return _getMedicineDetailsFromName(medicineName);
    }
  }

  // Generate medicine details based on name (fallback)
  Map<String, dynamic> _getMedicineDetailsFromName(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('paracetamol') ||
        lowerName.contains('acetaminophen')) {
      return {
        'name': 'Paracetamol 500mg',
        'description':
            'A common painkiller used to treat aches and pain. It can also be used to reduce a high temperature.',
        'purpose': 'Fever & Pain Relief',
        'sideEffects': 'Rare: allergic reaction, liver damage if overdosed.',
        'dosage': '500mg - 1000mg',
        'type': 'Tablet',
        'ageLimit': '12+ Years',
        'frequency': 'Every 4-6 hours (Max 4 times a day)',
        'usage': 'Take with water. Can be taken with or without food.',
        'searchKey': 'paracetamol',
      };
    } else if (lowerName.contains('ibuprofen')) {
      return {
        'name': 'Ibuprofen 200mg',
        'description':
            'Nonsteroidal anti-inflammatory drug (NSAID) used to reduce fever and treat pain or inflammation.',
        'purpose': 'Pain & Inflammation Relief',
        'sideEffects':
            'Stomach upset, heartburn, nausea. Long-term use may cause kidney issues.',
        'dosage': '200mg - 400mg',
        'type': 'Tablet',
        'ageLimit': '12+ Years',
        'frequency': 'Every 6-8 hours with food',
        'usage': 'Take with food or milk to prevent stomach upset.',
        'searchKey': 'ibuprofen',
      };
    } else if (lowerName.contains('amoxicillin')) {
      return {
        'name': 'Amoxicillin 500mg',
        'description':
            'Penicillin-type antibiotic used to treat bacterial infections.',
        'purpose': 'Bacterial Infection Treatment',
        'sideEffects': 'Diarrhea, nausea, rash. Allergic reactions possible.',
        'dosage': '500mg every 12 hours',
        'type': 'Capsule',
        'ageLimit': 'All ages (adjusted for children)',
        'frequency': 'Every 12 hours',
        'usage': 'Complete full course as prescribed. Take with food.',
        'searchKey': 'amoxicillin',
      };
    } else {
      return {
        'name': name,
        'description':
            'Please consult your doctor for detailed information about this medication.',
        'purpose': 'Medication',
        'sideEffects': 'Consult your doctor or pharmacist for side effects.',
        'dosage': 'As prescribed by doctor',
        'type': 'Medicine',
        'ageLimit': 'Consult doctor',
        'frequency': 'As prescribed',
        'usage': 'Follow doctor\'s instructions',
        'searchKey': name.toLowerCase(),
      };
    }
  }

  // Save medicine to Firebase
  Future<void> _saveMedicineToFirebase(
    Map<String, dynamic> medicineData,
    String barcode,
  ) async {
    if (uid == null) return;

    try {
      // Add to user's scanned medicines history
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scanned_medicines')
          .add({
            ...medicineData,
            'barcode': barcode,
            'scannedAt': FieldValue.serverTimestamp(),
          });

      // Also add to global medicines collection if not exists
      final existingDoc = await FirebaseFirestore.instance
          .collection('medicines')
          .where('name', isEqualTo: medicineData['name'])
          .limit(1)
          .get();

      if (existingDoc.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('medicines').add({
          ...medicineData,
          'barcode': barcode,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving to Firebase: $e");
    }
  }

  // Show medicine details in modal
  void _showMedicineDetails(Map<String, dynamic> medicine, String barcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['name'] ?? 'Medicine',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          medicine['type'] ?? 'Medication',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (medicine['source'] == 'online')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),

            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      title: 'Description',
                      content:
                          medicine['description'] ?? 'No description available',
                      icon: Icons.description_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            title: 'Purpose',
                            content: medicine['purpose'] ?? 'General',
                            icon: Icons.health_and_safety_rounded,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            title: 'Age Limit',
                            content: medicine['ageLimit'] ?? 'Consult doctor',
                            icon: Icons.person_rounded,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildDetailCard(
                      title: 'Dosage',
                      content: medicine['dosage'] ?? 'As prescribed',
                      icon: Icons.science_rounded,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            title: 'Frequency',
                            content: medicine['frequency'] ?? 'As prescribed',
                            icon: Icons.timer_rounded,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            title: 'Barcode',
                            content: barcode.length > 15
                                ? '${barcode.substring(0, 12)}...'
                                : barcode,
                            icon: Icons.qr_code_scanner_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildDetailCard(
                      title: 'Usage Instructions',
                      content:
                          medicine['usage'] ?? 'Follow doctor\'s instructions',
                      icon: Icons.info_rounded,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 16),

                    _buildDetailCard(
                      title: '⚠️ Side Effects',
                      content:
                          medicine['sideEffects'] ??
                          'Consult your doctor for complete list',
                      icon: Icons.warning_rounded,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.medical_information_rounded,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ This information is for reference only. Always consult a healthcare professional before taking any medication.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Core Barcode Scanning Logic
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() => _isProcessing = true);

      final String codeText = barcodes.first.rawValue ?? '';

      // Pause camera while processing
      _cameraController.stop();

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Searching medicine details...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      try {
        // First search in Firebase
        Map<String, dynamic>? medicine = await _searchMedicineInFirebase(
          codeText,
        );

        if (medicine != null) {
          // Found in Firebase
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            _showMedicineDetails(medicine, codeText);
          }
        } else {
          // Not found in Firebase - search online
          String searchName = codeText;
          if (!codeText.contains(RegExp(r'[a-zA-Z]'))) {
            // If barcode is numbers only, try to search by barcode online
            searchName =
                await _getMedicineNameFromBarcode(codeText) ?? codeText;
          }

          final onlineMedicine = await _searchMedicineOnline(searchName);

          // Save to Firebase
          await _saveMedicineToFirebase(onlineMedicine, codeText);

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            _showMedicineDetails(onlineMedicine, codeText);
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      } finally {
        // Restart camera after user closes modal or after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isProcessing = false);
            _cameraController.start();
          }
        });
      }
    }
  }

  Future<String?> _getMedicineNameFromBarcode(String barcode) async {
    try {
      // Try UPC database API (free)
      final url = Uri.parse(
        "https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0]['title'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Medicine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppTheme.primaryGreen : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              _cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error: ${error.errorCode.name}\nPlease ensure permissions are granted.',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.pureWhite,
                      ),
                      icon: const Icon(Icons.cameraswitch_rounded),
                      label: const Text('Try Switching Camera'),
                      onPressed: () => _cameraController.switchCamera(),
                    ),
                  ],
                ),
              );
            },
          ),

          // Dark Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Glowing Frame & Laser
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryGreen, width: 3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: _scanAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Instructions
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Align Barcode in frame',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _isProcessing ? 'Processing...' : 'Scanning...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
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
