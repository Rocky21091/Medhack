import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medhack/screens/ai_chat_popup.dart';
import '../theme/app_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view history.")),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
            'Medical History',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.pureWhite,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textGrey,
            indicatorColor: AppTheme.primaryGreen,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.document_scanner_rounded), text: 'Scans'),
              Tab(icon: Icon(Icons.smart_toy_rounded), text: 'Diagnoses'),
              Tab(icon: Icon(Icons.manage_search_rounded), text: 'Searches'),
              Tab(icon: Icon(Icons.chat_rounded), text: 'AI Chats'),
            ],
          ),
        ),
        body: Center(
          child: SizedBox(
            width: isDesktop ? 800 : double.infinity,
            child: TabBarView(
              children: [
                _buildScansList(context, uid),
                _buildDiagnosesList(context, uid),
                _buildCloudSearchHistory(uid),
                _buildAIChatHistory(context, uid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. SCANS TAB (Updated with Firebase Data)
  // ==========================================
  Widget _buildScansList(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scanned_medicines')
          .orderBy('scannedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No scans found.",
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Scan a medicine barcode to see it here",
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/scanner');
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text("Scan Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var scan = doc.data() as Map<String, dynamic>;

            // Format date
            String dateStr = "Recently";
            if (scan['scannedAt'] != null) {
              DateTime date = (scan['scannedAt'] as Timestamp).toDate();
              dateStr =
                  "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
            }

            // Determine status based on expiry if available
            String status = "Verified";
            Color statusColor = Colors.green;

            if (scan['expiryDate'] != null) {
              try {
                DateTime expiry = DateTime.parse(scan['expiryDate']);
                if (expiry.isBefore(DateTime.now())) {
                  status = "EXPIRED";
                  statusColor = Colors.red;
                } else if (expiry.isBefore(
                  DateTime.now().add(const Duration(days: 90)),
                )) {
                  status = "Expiring Soon";
                  statusColor = Colors.orange;
                }
              } catch (e) {
                // Ignore parsing errors
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: AppTheme.glossyCardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                title: Text(
                  scan['name'] ?? 'Unknown Medicine',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      scan['purpose'] ?? 'Medication',
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 12,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scan['barcode']?.toString().substring(0, 12) ?? 'N/A',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _showScanDetailsModal(context, scan),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 2. AI DIAGNOSES TAB
  // ==========================================
  Widget _buildDiagnosesList(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('diagnoses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smart_toy_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No AI diagnoses found.",
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Chat with Medhack AI to get diagnoses",
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var diag = doc.data() as Map<String, dynamic>;

            String dateStr = "Recently";
            if (diag['createdAt'] != null) {
              DateTime date = (diag['createdAt'] as Timestamp).toDate();
              dateStr =
                  "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
            }

            return GestureDetector(
              onTap: () => _showDiagnosisDetailsModal(context, diag),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: AppTheme.glossyCardDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.smart_toy_rounded,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MedAI Report',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Reported Symptoms:',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diag['symptom'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "View Full Analysis",
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 3. SEARCH HISTORY TAB
  // ==========================================
  Widget _buildCloudSearchHistory(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('searches')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

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
                  "No search history found.",
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
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
                  backgroundColor: AppTheme.backgroundLight,
                  child: Icon(Icons.history_rounded, color: AppTheme.textGrey),
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
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 4. AI CHAT HISTORY TAB
  // ==========================================
  Widget _buildAIChatHistory(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ai_chats')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No chat history found.",
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Start a conversation with Medhack AI",
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/ai-chat');
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text("Start New Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var chat = doc.data() as Map<String, dynamic>;

            String dateStr = "Recently";
            if (chat['lastMessageTime'] != null) {
              DateTime date = (chat['lastMessageTime'] as Timestamp).toDate();
              dateStr =
                  "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: AppTheme.pureWhite,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiChatPage(conversationId: doc.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_rounded,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat['title'] ?? 'Chat Conversation',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat['preview'] ?? 'No messages',
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chat['messageCount'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${chat['messageCount']}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // SCAN DETAILS MODAL
  // ==========================================
  void _showScanDetailsModal(BuildContext context, Map<String, dynamic> scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: AppTheme.primaryGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scan['name'] ?? 'Unknown Medicine',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              scan['type'] ?? 'Medication',
                              style: const TextStyle(color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details Grid
                  _buildDetailRow(
                    'Description',
                    scan['description'] ?? 'N/A',
                    Icons.description_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Purpose',
                    scan['purpose'] ?? 'N/A',
                    Icons.health_and_safety_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Dosage',
                    scan['dosage'] ?? 'N/A',
                    Icons.science_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Frequency',
                    scan['frequency'] ?? 'N/A',
                    Icons.timer_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Age Limit',
                    scan['ageLimit'] ?? 'Consult doctor',
                    Icons.person_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Usage',
                    scan['usage'] ?? 'Follow doctor\'s instructions',
                    Icons.info_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Side Effects',
                    scan['sideEffects'] ?? 'Consult your doctor',
                    Icons.warning_rounded,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Barcode',
                    scan['barcode'] ?? 'N/A',
                    Icons.qr_code_scanner_rounded,
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
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
                            style: TextStyle(fontSize: 12, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DIAGNOSIS DETAILS MODAL
  // ==========================================
  void _showDiagnosisDetailsModal(
    BuildContext context,
    Map<String, dynamic> diag,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MedAI Diagnostic Report',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              diag['dateStr'] ?? '',
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Patient Symptoms',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              diag['symptom'] ?? 'N/A',
              style: const TextStyle(fontSize: 16, color: AppTheme.textDark),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Conclusion',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diag['result'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recommended Action',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diag['recommendation'] ?? 'Please consult a doctor.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
