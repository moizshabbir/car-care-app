import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  @lazySingleton
  FirebasePerformance get performance => FirebasePerformance.instance;

  @lazySingleton
  FirebaseFirestore get firestore {
    final firestore = FirebaseFirestore.instance;
    // Persistence is enabled by default on mobile.
    // Explicitly setting it ensures intent.
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return firestore;
  }
}
