import 'package:carlog/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
  MockSpec<UserCredential>(),
  MockSpec<GoogleSignIn>(),
  MockSpec<GoogleSignInAccount>(),
  MockSpec<GoogleSignInAuthentication>(),
  MockSpec<GoogleSignInAuthorizationClient>(),
  MockSpec<GoogleSignInClientAuthorization>(),
])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockGoogleSignInAccount mockGoogleUser;
  late MockGoogleSignInAuthentication mockGoogleAuth;
  late MockGoogleSignInAuthorizationClient mockGoogleAuthorizationClient;
  late MockGoogleSignInClientAuthorization mockGoogleClientAuth;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockGoogleUser = MockGoogleSignInAccount();
    mockGoogleAuth = MockGoogleSignInAuthentication();
    mockGoogleAuthorizationClient = MockGoogleSignInAuthorizationClient();
    mockGoogleClientAuth = MockGoogleSignInClientAuthorization();
    repository = AuthRepositoryImpl(mockFirebaseAuth, mockGoogleSignIn);
  });

  group('AuthRepositoryImpl', () {
    test('currentUser returns firebaseAuth.currentUser', () {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      expect(repository.currentUser, mockUser);
    });

    test('authStateChanges returns firebaseAuth.authStateChanges()', () {
      final stream = Stream<User?>.value(mockUser);
      when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => stream);
      expect(repository.authStateChanges, stream);
    });

    group('signInWithEmail', () {
      test('calls signInWithEmailAndPassword', () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password',
        )).thenAnswer((_) async => mockUserCredential);

        await repository.signInWithEmail('test@test.com', 'password');

        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password',
        )).called(1);
      });
    });

    group('signUpWithEmail', () {
      test('calls createUserWithEmailAndPassword and updates display name', () async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password',
        )).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
        when(mockUser.reload()).thenAnswer((_) async {});

        await repository.signUpWithEmail('test@test.com', 'password', 'Test User');

        verify(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@test.com',
          password: 'password',
        )).called(1);
        verify(mockUser.updateDisplayName('Test User')).called(1);
        verify(mockUser.reload()).called(1);
      });
    });

    group('signInWithGoogle', () {
      test('calls authenticate and signInWithCredential on success', () async {
        when(mockGoogleSignIn.initialize()).thenAnswer((_) async {});
        when(mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockGoogleUser);
        when((mockGoogleUser as dynamic).authentication).thenReturn(mockGoogleAuth);
        when((mockGoogleAuth as dynamic).idToken).thenReturn('idToken');
        when((mockGoogleAuth as dynamic).accessToken).thenReturn('accessToken');
        when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);
        
        await repository.signInWithGoogle();
 
        verify(mockGoogleSignIn.initialize()).called(1);
        verify(mockGoogleSignIn.authenticate()).called(1);
        verify(mockFirebaseAuth.signInWithCredential(any)).called(1);
      });
 
      test('throws FirebaseAuthException when user cancels', () async {
        when(mockGoogleSignIn.initialize()).thenAnswer((_) async {});
        when(mockGoogleSignIn.authenticate()).thenThrow(Exception('cancel'));
 
        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>().having((e) => e.code, 'code', 'google-sign-in-cancelled')),
        );
      });
    });

    group('signOut', () {
      test('calls signOut on both firebase and google sign in', () async {
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        await repository.signOut();

        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
      });
    });

    test('sendPasswordResetEmail calls firebaseAuth.sendPasswordResetEmail', () async {
      final email = 'test@test.com';
      when(mockFirebaseAuth.sendPasswordResetEmail(email: email)).thenAnswer((_) async {});
      await repository.sendPasswordResetEmail(email);
      verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
    });

    test('updateDisplayName updates currentUser display name', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.updateDisplayName('New Name')).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});

      await repository.updateDisplayName('New Name');

      verify(mockUser.updateDisplayName('New Name')).called(1);
      verify(mockUser.reload()).called(1);
    });

    test('updatePassword updates currentUser password', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.updatePassword('newPass')).thenAnswer((_) async {});

      await repository.updatePassword('newPass');

      verify(mockUser.updatePassword('newPass')).called(1);
    });

    test('deleteAccount deletes currentUser', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.delete()).thenAnswer((_) async {});

      await repository.deleteAccount();

      verify(mockUser.delete()).called(1);
    });
  });
}
