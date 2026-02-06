import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/chat_details_screen.dart';
import '../../features/chat/domain/models/chat_model.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/about_screen.dart';
import '../../features/settings/presentation/pages/privacy_screen.dart';
import '../../features/contacts/presentation/pages/add_friend_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/lock_screen.dart';
import '../../features/groups/presentation/pages/create_group_screen.dart';
import '../../features/groups/presentation/pages/groups_screen.dart';
import '../../features/mesh/presentation/pages/mesh_debug_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Provider لـ GoRouter
/// يستخدم ShellRoute لعرض BottomNavBar بشكل دائم
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authStatus = ref.watch(authServiceProvider);
  final biometricState = ref.watch(biometricServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.initial,
    redirect: (context, state) {
      final isLoggedIn = authStatus == AuthStatus.loggedIn;
      final isInitializing = authStatus == AuthStatus.initializing;
      final isLockEnabled = biometricState.isAppLockEnabled;
      final isOnAuthPage = state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.lock;

      // أثناء التهيئة، لا redirect
      if (isInitializing) {
        return null;
      }

      // إذا لم يكن مسجل دخول وليس في صفحة المصادقة، redirect إلى register
      if (!isLoggedIn && !isOnAuthPage) {
        return AppRoutes.register;
      }

      // إذا كان مسجل دخول وهو في صفحة register، redirect إلى home (أو lock إذا كان مفعل)
      if (isLoggedIn && state.matchedLocation == AppRoutes.register) {
        if (isLockEnabled) {
          return AppRoutes.lock;
        }
        return AppRoutes.home;
      }

      // إذا كان قفل التطبيق مفعل وليس في صفحة Lock، redirect إلى lock
      if (isLoggedIn && isLockEnabled && state.matchedLocation != AppRoutes.lock) {
        return AppRoutes.lock;
      }

      // إذا كان قفل التطبيق غير مفعل وهو في صفحة Lock، redirect إلى home
      if (isLoggedIn && !isLockEnabled && state.matchedLocation == AppRoutes.lock) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash Screen (بدون BottomNavBar)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding Screen (بدون BottomNavBar)
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Register Screen (بدون BottomNavBar)
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Lock Screen (بدون BottomNavBar)
      GoRoute(
        path: AppRoutes.lock,
        name: 'lock',
        builder: (context, state) => const LockScreen(),
      ),
      // Main App Routes (مع BottomNavBar)
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.chat}/:chatId',
            name: 'chat-details',
            builder: (context, state) {
              final chat = state.extra as ChatModel?;
              if (chat == null) {
                // Fallback إذا لم يتم تمرير ChatModel
                return const Scaffold(
                  body: Center(child: Text('خطأ في تحميل المحادثة')),
                );
              }
              return ChatDetailsScreen(chat: chat);
            },
          ),
          GoRoute(
            path: AppRoutes.chat,
            name: 'chat',
            builder: (context, state) => const ChatPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.privacy,
            name: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: AppRoutes.addFriend,
            name: 'add-friend',
            builder: (context, state) => const AddFriendScreen(),
          ),
          GoRoute(
            path: AppRoutes.createGroup,
            name: 'create-group',
            builder: (context, state) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: AppRoutes.groups,
            name: 'groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          GoRoute(
            path: AppRoutes.meshDebug,
            name: 'mesh-debug',
            builder: (context, state) => const MeshDebugScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Scaffold مع BottomNavBar دائم
class ScaffoldWithNavBar extends StatelessWidget {
  final String location;
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.location,
    required this.child,
  });

  int _calculateSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.chat)) return 1;
    if (location.startsWith(AppRoutes.settings)) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.chat);
        break;
      case 2:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(location);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

