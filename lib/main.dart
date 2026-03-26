import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Fixes web routing
import 'package:medhack/router/app_router.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  usePathUrlStrategy(); 
  runApp(const MedHack());
}

class MedHack extends StatelessWidget {
  const MedHack({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedHack',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}