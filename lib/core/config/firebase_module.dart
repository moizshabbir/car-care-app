import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Mocks will be generated in a test file instead to avoid issues with build_runner

@module
abstract class FirebaseModule {
  @prod
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @prod
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  @prod
  @lazySingleton
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  @prod
  @lazySingleton
  FirebasePerformance get performance => FirebasePerformance.instance;

  @prod
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

@module
abstract class MockFirebaseModule {
  @test
  @lazySingleton
  FirebaseAuth get firebaseAuth => _MockFirebaseAuth();

  @test
  @lazySingleton
  GoogleSignIn get googleSignIn => _MockGoogleSignIn();

  @test
  @lazySingleton
  FirebaseAnalytics get analytics => _MockFirebaseAnalytics();

  @test
  @lazySingleton
  FirebasePerformance get performance => _MockFirebasePerformance();

  @test
  @lazySingleton
  FirebaseFirestore get firestore => _MockFirebaseFirestore();
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
  @override
  User? get currentUser => null;
}
class _MockGoogleSignIn extends Mock implements GoogleSignIn {}
class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}
class _MockFirebasePerformance extends Mock implements FirebasePerformance {}
class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
