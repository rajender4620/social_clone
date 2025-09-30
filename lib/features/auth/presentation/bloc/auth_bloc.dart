import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _authStatusSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthState.unknown()) {
    // Register event handlers
    on<AuthInitialized>(_onAuthInitialized);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthErrorCleared>(_onAuthErrorCleared);

    // Listen to authentication state changes
    _authStatusSubscription = _authRepository.authStateChanges.listen((user) {
      // Trigger initialization when auth state changes
      add(const AuthInitialized());
    });
  }

  // Initialize authentication state
  Future<void> _onAuthInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        final userModel = await _authRepository.getCurrentUserData();
        if (userModel != null) {
          emit(AuthState.authenticated(userModel));
        } else {
          emit(AuthState.unauthenticated());
        }
      } else {
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.error('Initialization failed: $e'));
    }
  }

  // Handle sign up
  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final userModel = await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        username: event.username,
        displayName: event.displayName,
      );

      emit(AuthState.authenticated(userModel));
    } catch (e) {
      print('❌ Sign up failed: $e');
      emit(AuthState.error(e.toString()));
    }
  }

  // Handle sign in
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final userModel = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      emit(AuthState.authenticated(userModel));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  // Handle Google sign in
  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final userModel = await _authRepository.signInWithGoogle();
      emit(AuthState.authenticated(userModel));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  // Handle sign out
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWithLoading());

    try {
      await _authRepository.signOut();
      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Sign out failed: $e'));
    }
  }

  // Handle profile update
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) {
      emit(AuthState.error('User not authenticated'));
      return;
    }

    emit(state.copyWithLoading());

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        displayName: event.displayName,
        bio: event.bio,
        profileImage: event.profileImage,
      );

      emit(AuthState.authenticated(updatedUser));
    } catch (e) {
      emit(AuthState.error('Profile update failed: $e'));
    }
  }

  // Handle account deletion
  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) {
      emit(AuthState.error('User not authenticated'));
      return;
    }

    emit(state.copyWithLoading());

    try {
      await _authRepository.deleteAccount();
      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Account deletion failed: $e'));
    }
  }

  // Clear authentication error
  void _onAuthErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWithoutError());
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }
}
