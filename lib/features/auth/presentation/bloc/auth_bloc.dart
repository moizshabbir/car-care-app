import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInWithEmail>(_onSignInWithEmail);
    on<SignUpWithEmail>(_onSignUpWithEmail);
    on<SignInWithGoogle>(_onSignInWithGoogle);
    on<SignOut>(_onSignOut);
    on<ForgotPassword>(_onForgotPassword);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }

    // Listen for auth state changes
    await emit.forEach<User?>(
      _authRepository.authStateChanges,
      onData: (user) {
        if (user != null) {
          return AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          return const AuthState(status: AuthStatus.unauthenticated);
        }
      },
    );
  }

  Future<void> _onSignInWithEmail(
      SignInWithEmail event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final credential = await _authRepository.signInWithEmail(
        event.email,
        event.password,
      );
      emit(AuthState(
          status: AuthStatus.authenticated, user: credential.user));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e.code),
      ));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignUpWithEmail(
      SignUpWithEmail event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final credential = await _authRepository.signUpWithEmail(
        event.email,
        event.password,
        event.displayName,
      );
      emit(AuthState(
          status: AuthStatus.authenticated, user: credential.user));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e.code),
      ));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignInWithGoogle(
      SignInWithGoogle event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final credential = await _authRepository.signInWithGoogle();
      emit(AuthState(
          status: AuthStatus.authenticated, user: credential.user));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e.code),
      ));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: 'Failed to sign out: ${e.toString()}',
      ));
    }
  }

  Future<void> _onForgotPassword(
      ForgotPassword event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(const AuthState(status: AuthStatus.passwordResetSent));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e.code),
      ));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'google-sign-in-cancelled':
        return 'Google sign-in was cancelled';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
