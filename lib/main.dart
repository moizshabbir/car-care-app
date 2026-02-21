import 'package:car_care_app/firebase_options.dart';
import 'package:car_care_app/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Replace with your actual Firebase configuration
  try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  } catch (e) {
      // Ignore error for now if config is missing, to allow app to start for UI testing
      debugPrint("Firebase initialization failed: $e");
  }

  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarCareApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('CarCareApp Initialized')),
      ),
    );
  }
}
