import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState._({
    this.status = AuthStatus.unknown,
    required this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  // Initial state
  AuthState.unknown() : this._(user: UserModel.empty);

  // Loading state
  AuthState.loading() : this._(
    status: AuthStatus.unknown,
    user: UserModel.empty,
    isLoading: true,
  );

  // Authenticated state
  const AuthState.authenticated(UserModel user) : this._(
    status: AuthStatus.authenticated,
    user: user,
  );

  // Unauthenticated state
  AuthState.unauthenticated() : this._(
    status: AuthStatus.unauthenticated,
    user: UserModel.empty,
  );

  // Error state
  AuthState.error(String message) : this._(
    status: AuthStatus.unauthenticated,
    user: UserModel.empty,
    errorMessage: message,
  );

  // Loading state with current user
  AuthState copyWithLoading() {
    return AuthState._(
      status: status,
      user: user,
      isLoading: true,
    );
  }

  // Update user data while maintaining authenticated status
  AuthState copyWithUser(UserModel newUser) {
    return AuthState._(
      status: AuthStatus.authenticated,
      user: newUser,
    );
  }

  // Clear error while maintaining current state
  AuthState copyWithoutError() {
    return AuthState._(
      status: status,
      user: user,
      isLoading: isLoading,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isLoading];

  @override
  String toString() {
    return '''AuthState {
      status: $status,
      user: ${user.email},
      errorMessage: $errorMessage,
      isLoading: $isLoading
    }''';
  }
}
