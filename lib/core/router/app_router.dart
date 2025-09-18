import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/post/presentation/pages/post_creation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const FeedPage(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const PostCreationPage(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfilePage(userId: userId);
        },
      ),
    ],
    redirect: (context, state) {
      // Get the authentication state
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      
      // If not authenticated and not on login/signup page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      // If authenticated and on login/signup page, redirect to home
      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
  );

  static GoRouter get router => _router;
}


