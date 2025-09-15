import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pumpkin/features/feed_screen.dart';
import 'package:pumpkin/features/post/post_screen.dart';
import 'package:pumpkin/features/post_details/post_details.dart';
import 'package:pumpkin/pages/login_page.dart';
import 'package:pumpkin/pages/signup_page.dart';
import 'package:pumpkin/widgets/auth_wrapper.dart';

class AppRouter {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthPage =
          state.uri.path == '/login' || state.uri.path == '/signup';

      // If user is not logged in and trying to access protected route
      if (user == null && !isAuthPage && state.uri.path != '/') {
        return '/login';
      }

      // If user is logged in and trying to access auth pages
      if (user != null && isAuthPage) {
        return '/';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
      GoRoute(path: '/post', builder: (context, state) => const PostScreen()),
      GoRoute(
        path: '/post-detail/:postId',
        builder:
            (context, state) =>
                PostDetailsScreen(postId: state.pathParameters['postId'] ?? ''),
      ),
    ],
  );
}
