import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:injectable/injectable.dart';

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
  FirebaseAuth get firebaseAuth => _FakeFirebaseAuth();

  @test
  @lazySingleton
  GoogleSignIn get googleSignIn => _FakeGoogleSignIn();

  @test
  @lazySingleton
  FirebaseAnalytics get analytics => _FakeFirebaseAnalytics();

  @test
  @lazySingleton
  FirebasePerformance get performance => _FakeFirebasePerformance();

  @test
  @lazySingleton
  FirebaseFirestore get firestore => _FakeFirebaseFirestore();
}

// Using Fake classes instead of Mockito to avoid dev_dependency issues in lib
class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
  @override
  User? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignIn implements GoogleSignIn {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebasePerformance implements FirebasePerformance {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
