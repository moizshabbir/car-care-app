import 'dart:async';

import 'package:car_care_app/firebase_options.dart';
import 'package:car_care_app/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/logs/data/models/fuel_log_model.dart';
import 'features/logs/data/models/location_model.dart';
import 'features/logs/data/models/maintenance_log_model.dart';
import 'features/logs/presentation/pages/add_expense_page.dart';
import 'features/logs/presentation/pages/quick_log_page.dart';
import 'features/logs/presentation/pages/share_stats_page.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // TODO: Replace with your actual Firebase configuration
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      // Ignore error for now if config is missing, to allow app to start for UI testing
      debugPrint("Firebase initialization failed: $e");
    }

    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(FuelLogModelAdapter());
    Hive.registerAdapter(LocationModelAdapter());
    Hive.registerAdapter(MaintenanceLogModelAdapter());

    configureDependencies();
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarCareApp',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Care App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ShareStatsPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Car Care App Initialized')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.local_gas_station),
                      title: const Text('Log Fuel (Scan)'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const QuickLogPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Log Expense'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const AddExpensePage()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
