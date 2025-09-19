import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/feed/data/repositories/feed_repository.dart';
import 'features/feed/presentation/bloc/feed_bloc.dart';
import 'features/post/presentation/bloc/post_creation_bloc.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/follow/data/repositories/follow_repository.dart';
import 'shared/services/image_picker_service.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
