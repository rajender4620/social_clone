import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Event to initialize authentication state
class AuthInitialized extends AuthEvent {
  const AuthInitialized();
}

// Email/Password Sign Up Events
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String? displayName;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.username,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, username, displayName];
}

// Email/Password Sign In Events
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

// Google Sign In Event
class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

// Sign Out Event
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

// Profile Update Event
class ProfileUpdateRequested extends AuthEvent {
  final String? displayName;
  final String? bio;
  final File? profileImage;

  const ProfileUpdateRequested({
    this.displayName,
    this.bio,
    this.profileImage,
  });

  @override
  List<Object?> get props => [displayName, bio, profileImage];
}

// Delete Account Event
class DeleteAccountRequested extends AuthEvent {
  const DeleteAccountRequested();
}

// Clear Auth Error Event
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
