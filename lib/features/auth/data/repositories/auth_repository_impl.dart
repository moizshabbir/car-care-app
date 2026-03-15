import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
      final dynamic googleUser = await (_googleSignIn as dynamic).signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In cancelled by user.");
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled by user',
        );
      }
      debugPrint("Google User obtained: ${googleUser.email}");
      
      final dynamic gAuth = googleUser.authentication;

      debugPrint("Google Auth obtained. ID Token: ${gAuth.idToken != null ? 'Present' : 'NULL'}, Access Token: ${gAuth.accessToken != null ? 'Present' : 'NULL'}");
      
      if (gAuth.idToken == null && gAuth.accessToken == null) {
        debugPrint("SEVERE: Both ID Token and Access Token are NULL. Check Google Cloud Console / Firebase configuration.");
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      debugPrint("Firebase GoogleAuthProvider credential created.");

      debugPrint("Signing into Firebase with Google Credential...");
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint("Firebase Sign-In successful. User UID: ${userCredential.user?.uid}");
      return userCredential;
    } catch (e, stack) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint("Stack Trace: $stack");
      if (e is FirebaseAuthException) {
        rethrow;
      }
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('cancel') || errorMessage.contains('abort')) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled by user',
        );
      }
      rethrow;
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
