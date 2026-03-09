import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class SignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmail({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpWithEmail({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

class SignInWithGoogle extends AuthEvent {}

class SignOut extends AuthEvent {}

class ForgotPassword extends AuthEvent {
  final String email;

  const ForgotPassword({required this.email});

  @override
  List<Object?> get props => [email];
}
