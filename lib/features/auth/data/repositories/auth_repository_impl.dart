import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._firebaseAuth, this._googleSignIn);

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmail(
      String email, String password, String displayName) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.reload();
    return credential;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint("Starting Google Sign-In (v7 logic)...");
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log("GoogleSignIn: Starting flow");
      }

      // authenticate() is used in this project's version of GoogleSignIn
      final GoogleSignInAccount? user = await _googleSignIn.authenticate();
      
      if (user == null) {
        debugPrint("Google Sign-In was aborted by user.");
        if (!kIsWeb && Firebase.apps.isNotEmpty) {
          FirebaseCrashlytics.instance.log("GoogleSignIn: User aborted");
        }
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Sign-in was cancelled.',
        );
      }
      
      debugPrint("Google User obtained: ${user.email}");
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log("GoogleSignIn: User obtained: ${user.email}");
      }
      
      // In this version, authentication is a synchronous getter
      final GoogleSignInAuthentication gAuth = user.authentication;
      debugPrint("Tokens received → ID Token: ${gAuth.idToken != null}");
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log("GoogleSignIn: Tokens received, ID Token present: ${gAuth.idToken != null}");
      }

      if (gAuth.idToken == null) {
        debugPrint("ERROR: Google ID Token is missing.");
        if (!kIsWeb && Firebase.apps.isNotEmpty) {
          FirebaseCrashlytics.instance.log("GoogleSignIn: ERROR - ID Token is null");
        }
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google ID Token is missing. This usually means the SHA-1 fingerprint is not configured correctly in Firebase.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );

      debugPrint("Signing into Firebase...");
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log("GoogleSignIn: Signing into Firebase");
      }
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint("Firebase Sign-In successful: ${userCredential.user?.uid}");
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log("GoogleSignIn: Firebase Sign-In successful: ${userCredential.user?.uid}");
      }

      return userCredential;
    } on PlatformException catch (e, stack) {
      debugPrint("Google Sign-In Platform Error: ${e.code} - ${e.message}");
      debugPrint("Details: ${e.details}");
      debugPrint("Stack Trace: $stack");

      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Google Sign-In Platform Error: ${e.code}');
      }

      String message;
      String code = 'google-sign-in-failed';

      switch (e.code) {
        case '12501':
          code = 'google-sign-in-cancelled';
          message = 'Sign-in cancelled by user.';
          break;
        case '10':
          message = 'Developer error (10): This usually means the SHA-1 fingerprint is missing in Firebase or the configuration is incorrect.';
          break;
        case '12500':
          message = 'Sign-in failed (12500). Please check internet connection and Google Play Services.';
          break;
        case '7':
          message = 'Network error (7). Check your internet connection.';
          break;
        case '16':
          message = 'Account reauth failed (16). This may happen if the Google Sign-In configuration is invalid or the tokens expired.';
          break;
        default:
          message = 'Google Sign-In Error [${e.code}]: ${e.message ?? 'Unknown error'}';
      }

      throw FirebaseAuthException(
        code: code,
        message: message,
      );
    } catch (e, stack) {
      debugPrint("Google Sign-In Unexpected Error: $e");
      debugPrint("Stack Trace: $stack");

      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Google Sign-In Unexpected Error');
      }

      if (e is FirebaseAuthException) {
        rethrow;
      }

      final error = e.toString().toLowerCase();
      if (error.contains('cancel') || error.contains('abort')) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Sign-in was cancelled.',
        );
      }

      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In Unexpected Error: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    await _firebaseAuth.currentUser?.reload();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _firebaseAuth.currentUser?.updatePassword(newPassword);
  }

  @override
  Future<void> deleteAccount() async {
    await _firebaseAuth.currentUser?.delete();
  }
}
