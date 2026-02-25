import 'dart:async';

import 'package:car_care_app/firebase_options.dart';
import 'package:car_care_app/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:intl/intl.dart';

import 'core/theme/app_theme.dart';
import 'features/logs/data/models/fuel_log_model.dart';
import 'features/logs/data/models/location_model.dart';
import 'features/logs/data/models/maintenance_log_model.dart';
import 'features/logs/domain/repositories/log_repository.dart';
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late Future<List<FuelLogModel>> _recentLogsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _recentLogsFuture = getIt<LogRepository>().getRecentFuelLogs();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages for BottomNavigationBar
    final List<Widget> pages = [
      _buildDashboard(),
      const ShareStatsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
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
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                    builder: (context) => const QuickLogPage()),
                              )
                                  .then((_) {
                                // Refresh logs when returning from QuickLogPage
                                _refreshLogs();
                              });
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.receipt_long),
                            title: const Text('Log Expense'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AddExpensePage()),
                              )
                                  .then((_) {
                                // Refresh logs when returning from AddExpensePage
                                _refreshLogs();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: FutureBuilder<List<FuelLogModel>>(
        future: _recentLogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No logs yet. Add one!'));
          }

          final logs = snapshot.data!;
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: const Icon(Icons.local_gas_station),
                title: Text(DateFormat.yMMMd().format(log.timestamp)),
                subtitle: Text('${log.liters.toStringAsFixed(1)}L @ \$${log.cost.toStringAsFixed(2)}'),
                trailing: Text('${log.odometer} km'),
              );
            },
          );
        },
      ),
    );
  }
}
