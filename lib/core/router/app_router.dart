import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/username_picker_screen.dart';
import '../../features/auth/screens/avatar_picker_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/record/screens/record_screen.dart';
import '../../features/posts/screens/create_post_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../shared/widgets/main_shell.dart';
import 'app_auth_notifier.dart';

GoRouter buildRouter(AppAuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final status = authNotifier.status;
      final loc = state.matchedLocation;

      switch (status) {
        case AppAuthStatus.loading:
          return loc == '/' ? null : '/';
        case AppAuthStatus.unauthenticated:
          return loc == '/login' ? null : '/login';
        case AppAuthStatus.needsProfile:
          if (loc == '/username-picker' || loc == '/avatar-picker') {
            return null;
          }
          return '/username-picker';
        case AppAuthStatus.authenticated:
          if (loc == '/' ||
              loc == '/login' ||
              loc == '/username-picker' ||
              loc == '/avatar-picker') {
            return '/feed';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(
          path: '/username-picker',
          builder: (c, s) => const UsernamePickerScreen()),
      GoRoute(
          path: '/avatar-picker',
          builder: (c, s) => const AvatarPickerScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (c, s) => const FeedScreen()),
          GoRoute(path: '/explore', builder: (c, s) => const ExploreScreen()),
          GoRoute(
            path: '/record',
            builder: (c, s) => RecordScreen(
              postId: s.uri.queryParameters['postId'],
            ),
          ),
          GoRoute(
              path: '/create-post',
              builder: (c, s) => const CreatePostScreen()),
          GoRoute(
              path: '/notifications',
              builder: (c, s) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),
    ],
  );
}
