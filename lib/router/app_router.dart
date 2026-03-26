import 'package:go_router/go_router.dart';
import 'package:medhack/screens/device_sync_page.dart';
import 'package:medhack/screens/history.dart';
// Adjust your imports based on your actual folder structure
import 'package:medhack/screens/home.dart';
import 'package:medhack/screens/location_services_page.dart';
import 'package:medhack/screens/login.dart';
import 'package:medhack/screens/profile.dart';
import 'package:medhack/screens/notification.dart';
import 'package:medhack/screens/ai_chat_popup.dart';
import 'package:medhack/screens/scanner_page.dart';
import 'package:medhack/screens/signup_page.dart';

// New Imports
import 'package:medhack/screens/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash', // Start at the splash screen
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/', builder: (context, state) => const MainLayout()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) =>
            const AiChatPage(), // Replace with your actual chat screen
      ),
      GoRoute(path: '/scan', builder: (context, state) => const ScannerPage()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/iot',
        builder: (context, state) => const DeviceSyncPage(),
      ),

      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationServicesPage(),
      ),
    ],
  );
}
