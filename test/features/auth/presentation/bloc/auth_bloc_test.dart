import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:carlog/features/auth/domain/repositories/auth_repository.dart';
import 'package:carlog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carlog/features/auth/presentation/bloc/auth_event.dart';
import 'package:carlog/features/auth/presentation/bloc/auth_state.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<User>(),
  MockSpec<UserCredential>(),
])
import 'auth_bloc_test.mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthState with initial status', () {
      expect(authBloc.state, const AuthState());
      expect(authBloc.state.status, AuthStatus.initial);
    });

    group('CheckAuthStatus', () {
      blocTest<AuthBloc, AuthState>(
        'emits [authenticated] when user is logged in',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(mockUser);
          when(mockAuthRepository.authStateChanges).thenAnswer(
            (_) => Stream.value(mockUser),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.authenticated),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when no user is logged in',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(null);
          when(mockAuthRepository.authStateChanges).thenAnswer(
            (_) => Stream.value(null),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unauthenticated),
        ],
      );
    });

    group('SignInWithEmail', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] on successful sign-in',
        build: () {
          when(mockUserCredential.user).thenReturn(mockUser);
          when(mockAuthRepository.signInWithEmail('test@test.com', 'password123'))
              .thenAnswer((_) async => mockUserCredential);
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithEmail(email: 'test@test.com', password: 'password123')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.authenticated),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on failed sign-in',
        build: () {
          when(mockAuthRepository.signInWithEmail('test@test.com', 'wrongpassword'))
              .thenThrow(FirebaseAuthException(code: 'wrong-password', message: 'Wrong password'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithEmail(email: 'test@test.com', password: 'wrongpassword')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', contains('Incorrect password')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on generic exception',
        build: () {
          when(mockAuthRepository.signInWithEmail(any, any))
              .thenThrow(Exception('Generic error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithEmail(email: 'test@test.com', password: 'password')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'Exception: Generic error'),
        ],
      );
    });

    group('SignUpWithEmail', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] on successful sign-up',
        build: () {
          when(mockUserCredential.user).thenReturn(mockUser);
          when(mockAuthRepository.signUpWithEmail('test@test.com', 'password123', 'Test User'))
              .thenAnswer((_) async => mockUserCredential);
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpWithEmail(email: 'test@test.com', password: 'password123', displayName: 'Test User')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.authenticated),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when email already in use',
        build: () {
          when(mockAuthRepository.signUpWithEmail('test@test.com', 'password123', 'Test User'))
              .thenThrow(FirebaseAuthException(code: 'email-already-in-use', message: ''));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpWithEmail(email: 'test@test.com', password: 'password123', displayName: 'Test User')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', contains('An account already exists with this email')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on generic exception',
        build: () {
          when(mockAuthRepository.signUpWithEmail(any, any, any))
              .thenThrow(Exception('Generic error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpWithEmail(email: 'test@test.com', password: 'password', displayName: 'Name')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'Exception: Generic error'),
        ],
      );
    });

    group('SignOut', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] on sign-out',
        build: () {
          when(mockAuthRepository.signOut()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOut()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unauthenticated),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on generic exception',
        build: () {
          when(mockAuthRepository.signOut()).thenThrow(Exception('Generic error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOut()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'Failed to sign out: Exception: Generic error'),
        ],
      );
    });

    group('ForgotPassword', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, passwordResetSent] on success',
        build: () {
          when(mockAuthRepository.sendPasswordResetEmail('test@test.com'))
              .thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const ForgotPassword(email: 'test@test.com')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.passwordResetSent),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] for non-existent email',
        build: () {
          when(mockAuthRepository.sendPasswordResetEmail('noone@test.com'))
              .thenThrow(FirebaseAuthException(code: 'user-not-found', message: ''));
          return authBloc;
        },
        act: (bloc) => bloc.add(const ForgotPassword(email: 'noone@test.com')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', contains('No account found with this email')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on generic exception',
        build: () {
          when(mockAuthRepository.sendPasswordResetEmail(any))
              .thenThrow(Exception('Generic error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const ForgotPassword(email: 'test@test.com')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'Exception: Generic error'),
        ],
      );
    });

    group('SignInWithGoogle', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] on successful sign-in',
        build: () {
          when(mockUserCredential.user).thenReturn(mockUser);
          when(mockAuthRepository.signInWithGoogle())
              .thenAnswer((_) async => mockUserCredential);
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithGoogle()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.authenticated),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on cancelled sign-in',
        build: () {
          when(mockAuthRepository.signInWithGoogle())
              .thenThrow(FirebaseAuthException(code: 'google-sign-in-cancelled', message: ''));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithGoogle()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', contains('Google sign-in was cancelled')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] on generic xception',
        build: () {
          when(mockAuthRepository.signInWithGoogle())
              .thenThrow(Exception('Generic error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithGoogle()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'Exception: Generic error'),
        ],
      );
    });

    group('_mapAuthError fallback', () {
      blocTest<AuthBloc, AuthState>(
        'emits custom error message with code for unhandled exceptions',
        build: () {
          when(mockAuthRepository.signInWithEmail('any@test.com', 'password'))
              .thenThrow(FirebaseAuthException(code: 'unknown-code', message: ''));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithEmail(email: 'any@test.com', password: 'password')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', contains('Authentication failed (unknown-code)')),
        ],
      );
    });
  });
}
