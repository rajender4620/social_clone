import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/feed/presentation/pages/comments_page.dart';
import '../../features/feed/presentation/pages/post_detail_page.dart';
import '../../features/feed/presentation/pages/saved_posts_page.dart';
import '../../features/post/presentation/pages/post_creation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/feed/data/models/post_model.dart';

// Custom Listenable that listens to AuthBloc state changes
class AuthBlocListenable extends ChangeNotifier {
  AuthBlocListenable(this._authBloc) {
    _authBloc.stream.listen((_) {
      // Add small delay to prevent navigation during widget building
      Future.microtask(() {
        notifyListeners();
      });
    });
  }

  final AuthBloc _authBloc;
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
    initialLocation: '/login',
    refreshListenable: AuthBlocListenable(authBloc),
    routes: [
      // Authentication routes with custom transitions to avoid Hero conflicts
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignUpPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
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
      GoRoute(
        path: '/comments/:postId',
        builder: (context, state) {
          final post = state.extra as PostModel;
          return CommentsPage(post: post);
        },
      ),
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final post = state.extra as PostModel;
          return PostDetailPage(post: post);
        },
      ),
      GoRoute(
        path: '/saved-posts',
        builder: (context, state) => const SavedPostsPage(),
      ),
    ],
    redirect: (context, state) {
      // Get the authentication state from the passed authBloc
      final authState = authBloc.state;
      
      // Don't redirect if we're still loading
      if (authState.isLoading) {
        return null;
      }
      
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final currentLocation = state.matchedLocation;
      final isAuthPage = currentLocation == '/login' || currentLocation == '/signup';
      
      // If not authenticated and not on auth pages, redirect to login
      if (!isAuthenticated && !isAuthPage) {
        return '/login';
      }
      
      // If authenticated and on auth pages, redirect to home
      if (isAuthenticated && isAuthPage) {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
  );
  }
}


