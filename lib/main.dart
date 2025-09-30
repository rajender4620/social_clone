import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/feed/data/repositories/feed_repository.dart';
import 'features/feed/presentation/bloc/feed_bloc.dart';
import 'features/feed/presentation/bloc/bookmark_bloc.dart';
import 'features/post/presentation/bloc/post_creation_bloc.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/follow/data/repositories/follow_repository.dart';
import 'shared/services/image_picker_service.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';
import 'shared/services/video_controller_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    VideoControllerManager().disposeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause all videos when app goes to background
        VideoControllerManager().pauseAll();
        print('🔄 App paused - videos paused');
        break;
      case AppLifecycleState.resumed:
        // App is back - let individual video players handle reinitializing themselves
        // This avoids race conditions from bulk controller disposal
        print('🔄 App resumed - video players will reinitialize as needed');
        break;
      case AppLifecycleState.detached:
        // App is being destroyed - dispose all controllers
        VideoControllerManager().disposeAll();
        print('🔄 App detached - all video controllers disposed');
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final feedRepository = FeedRepository();
    final profileRepository = ProfileRepository();
    final followRepository = FollowRepository();
    final imagePickerService = ImagePickerService();

    // Create AuthBloc first so we can pass it to the router
    final authBloc = AuthBloc(
      authRepository: authRepository,
    )..add(const AuthInitialized());

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: feedRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: followRepository),
        RepositoryProvider.value(value: imagePickerService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<FeedBloc>(
            create: (context) => FeedBloc(
              feedRepository: feedRepository,
            ),
          ),
          BlocProvider<PostCreationBloc>(
            create: (context) => PostCreationBloc(
              feedRepository: feedRepository,
              imagePickerService: imagePickerService,
              authBloc: authBloc,
              feedBloc: context.read<FeedBloc>(),
            ),
          ),
          BlocProvider<BookmarkBloc>(
            create: (context) => BookmarkBloc(
              feedRepository: feedRepository,
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'PumpkinSocial',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.createRouter(authBloc),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
