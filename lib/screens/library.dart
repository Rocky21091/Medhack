import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medhack/screens/MedicineDetailsPage.dart';
import '../theme/app_theme.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with AutomaticKeepAliveClientMixin {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  // --- SAVE TO FIREBASE INSTANTLY ---
  Future<void> _handleMedicineTap(Map<String, dynamic> med) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // 1. Save to Firebase Cloud History
    if (uid != null) {
      try {
        // We use the medicine name as the Document ID.
        // This ensures if you click it twice, it just updates the timestamp instead of duplicating!
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('searches')
            .doc(med['name'])
            .set({...med, 'timestamp': FieldValue.serverTimestamp()});
      } catch (e) {
        debugPrint("Firebase save error: $e");
      }
    }

    if (!mounted) return;

    // 2. Navigate to Details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailsPage(medicineData: med),
      ),
    ).then((_) {
      // 3. Clear search bar when you come back
      if (mounted) {
        _searchController.clear();
        setState(() {
          searchQuery = "";
        });
      }
    });
  }

  // --- CLEAR CLOUD HISTORY ---
  Future<void> _clearHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Delete all documents in the user's search history collection
    var snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('searches')
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isDesktop = MediaQuery.of(context).size.width > 800;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Medicine Library',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: isDesktop ? 800 : double.infinity,
          child: Column(
            children: [
              // --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: AppTheme.glossyCardDecoration,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search medicines (e.g. Paracetamol)...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => searchQuery = "");
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.pureWhite,
                    ),
                  ),
                ),
              ),

              // --- BODY: LIVE CLOUD HISTORY OR SEARCH RESULTS ---
              Expanded(
                child: uid == null
                    ? const Center(child: Text("Please log in to search."))
                    : (searchQuery.isEmpty
                          ? _buildCloudHistoryView(uid)
                          : _buildSearchResults()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REAL-TIME CLOUD HISTORY VIEW ---
  Widget _buildCloudHistoryView(String uid) {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the user's personal search collection, ordered by newest first (Limit to 5)
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('searches')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.manage_search_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Your recent searches will appear here.",
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...snapshot.data!.docs.map((doc) {
              var med = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: AppTheme.pureWhite,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.backgroundLight,
                    child: Icon(
                      Icons.history_rounded,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  title: Text(
                    med['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    med['purpose'] ?? '',
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  onTap: () => _handleMedicineTap(med),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- FIREBASE SEARCH RESULTS ---
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicines')
          .where('searchKey', isGreaterThanOrEqualTo: searchQuery)
          .where('searchKey', isLessThan: '$searchQuery\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_liquid_rounded,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No medicines found in database.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var med = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: AppTheme.pureWhite,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lightGreen,
                  child: Icon(Icons.medication, color: AppTheme.primaryGreen),
                ),
                title: Text(
                  med['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(med['purpose'] ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleMedicineTap(med),
              ),
            );
          },
        );
      },
    );
  }
}
