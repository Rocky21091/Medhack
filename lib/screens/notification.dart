import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Active Reminders',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGreen),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🚨 CRITICAL FIX: Only fetch reminders for the logged in user!
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: uid)
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
                    Icons.notifications_off_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No active reminders set.",
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

          // Sort manually here since combining `where` and `orderBy` in Firebase requires an index we don't have time to build!
          var docs = snapshot.data!.docs;
          docs.sort(
            (a, b) => (b['createdAt'] as Timestamp? ?? Timestamp.now())
                .compareTo(a['createdAt'] as Timestamp? ?? Timestamp.now()),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var reminder = docs[index].data() as Map<String, dynamic>;
              List<dynamic> times = reminder['times'] ?? [];

              DateTime start = DateTime.parse(reminder['startDate']);
              DateTime end = DateTime.parse(reminder['endDate']);
              String dateRange =
                  "${start.day}/${start.month} - ${end.day}/${end.month}";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glossyCardDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder['medicineName'] ?? 'Medicine',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Schedule: $dateRange",
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: times
                                .map(
                                  (time) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      time.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
