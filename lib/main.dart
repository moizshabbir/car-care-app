import 'dart:async';

import 'package:carlog/firebase_options.dart';
import 'package:carlog/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/logs/data/models/fuel_log_model.dart';
import 'features/logs/data/models/location_model.dart';
import 'features/logs/data/models/maintenance_log_model.dart';
import 'features/logs/presentation/pages/dashboard_page.dart';
import 'features/vehicles/data/models/vehicle_model.dart';
import 'features/vehicles/presentation/bloc/vehicle_bloc.dart';
import 'features/vehicles/presentation/pages/garage_page.dart';
import 'features/vehicles/presentation/pages/onboarding_page.dart';
import 'features/reports/presentation/pages/reports_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

import 'core/services/settings_service.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("Initializing Firebase...");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase initialized");

      // Initialize GoogleSignIn (required in 7.x)
      // Including serverClientId is CRITICAL for Firebase to receive the idToken on Android
      debugPrint("Initializing GoogleSignIn...");
      const serverClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      debugPrint("GoogleSignIn initialized. Server Client ID: ${serverClientId.isEmpty ? 'MISSING (Check --dart-define)' : 'Set'}");

      // Check if Firebase configuration was loaded correctly
      final appId = DefaultFirebaseOptions.android.appId;
      if (appId.isEmpty) {
        debugPrint("SEVERE WARNING: Firebase App ID is empty! AI and Auth will likely fail.");
        debugPrint("Ensure you are running with --dart-define-from-file=.env");
      } else {
        debugPrint("Firebase Configuration validated (App ID: ${appId.substring(0, 10)}...)");
      }

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Async error: $error\n$stack');
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e, stack) {
      debugPrint("Firebase initialization failed: $e\n$stack");
    }

    // Initialize Hive
    debugPrint("Initializing Hive...");
    await Hive.initFlutter();
    debugPrint("Hive initialized");

    debugPrint("Registering Hive adapters...");
    Hive.registerAdapter(FuelLogModelAdapter());
    Hive.registerAdapter(LocationModelAdapter());
    Hive.registerAdapter(MaintenanceLogModelAdapter());
    Hive.registerAdapter(VehicleModelAdapter());
    debugPrint("Hive adapters registered");

    debugPrint("Configuring dependencies...");
    configureDependencies();
    debugPrint("Dependencies configured");

    debugPrint("Initializing SettingsService...");
    await getIt<SettingsService>().init();
    debugPrint("SettingsService initialized");

    debugPrint("Running runApp...");
    runApp(const MyApp());
    debugPrint("runApp called");
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>()..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (context) => getIt<VehicleBloc>()..add(LoadVehicles()),
        ),
      ],
      child: ListenableBuilder(
        listenable: getIt<SettingsService>(),
        builder: (context, child) {
          return MaterialApp(
            title: 'CarCareApp',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (state.status == AuthStatus.authenticated) {
          return const MainPage();
        }

        return const LoginPage();
      },
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

  final List<Widget> _pages = [
    const DashboardPage(),
    const GaragePage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        if (state.status == VehicleStatus.initial || state.status == VehicleStatus.loading) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        if (state.status == VehicleStatus.loaded && state.vehicles.isEmpty) {
          return const OnboardingPage();
        }

        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car),
                label: 'Garage',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: Colors.grey,
            backgroundColor: AppTheme.cardDark,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
