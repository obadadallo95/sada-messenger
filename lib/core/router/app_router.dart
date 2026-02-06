import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../features/contacts/presentation/scan_qr_screen.dart';
import '../../features/contacts/presentation/my_qr_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/lock_screen.dart';
import '../../features/groups/presentation/pages/create_group_screen.dart';
import '../../features/groups/presentation/pages/groups_screen.dart';
import '../../features/mesh/presentation/pages/mesh_debug_screen.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/database/database_provider.dart';
import '../../l10n/app_localizations.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Provider لـ GoRouter
/// يستخدم ShellRoute لعرض BottomNavBar بشكل دائم
@riverpod
GoRouter appRouter(Ref ref) {
  final authStatus = ref.watch(authServiceProvider);
  final biometricState = ref.watch(biometricServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.initial,
    redirect: (context, state) {
      final isLoggedIn = authStatus == AuthStatus.loggedIn;
      final isInitializing = authStatus == AuthStatus.initializing;
      final isLockEnabled = biometricState.isAppLockEnabled;
      
      // الحصول على AuthType من Provider (reactive)
      final authType = ref.watch(currentAuthTypeProvider);
      final isAuthenticated = authType != null && 
                              (authType == AuthType.master || authType == AuthType.duress);
      
      // تحديد الصفحات المحمية (تتطلب AuthType)
      final protectedRoutes = [
        AppRoutes.home,
        AppRoutes.chat,
        AppRoutes.settings,
        AppRoutes.addFriend,
        AppRoutes.scanQr,
        AppRoutes.myQr,
        AppRoutes.createGroup,
        AppRoutes.groups,
        AppRoutes.meshDebug,
        AppRoutes.notifications,
        AppRoutes.about,
        AppRoutes.privacy,
        AppRoutes.groupInfo,
      ];
      
      final isOnProtectedRoute = protectedRoutes.any((route) => 
        state.matchedLocation.startsWith(route));
      
      final isOnAuthPage = state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.lock;

      // أثناء التهيئة، لا redirect
      if (isInitializing) {
        return null;
      }

      // Rule 1: إذا لم يكن مسجل دخول وليس في صفحة المصادقة، redirect إلى register
      if (!isLoggedIn && !isOnAuthPage) {
        return AppRoutes.register;
      }

      // Rule 2: إذا كان مسجل دخول لكن AuthType غير محدد (لم يدخل PIN بعد)
      // وليس في صفحة Lock، redirect إلى lock
      if (isLoggedIn && !isAuthenticated && !isOnAuthPage) {
        return AppRoutes.lock;
      }

      // Rule 3: إذا كان مسجل دخول وهو في صفحة register، redirect إلى lock أو home
      if (isLoggedIn && state.matchedLocation == AppRoutes.register) {
        if (isLockEnabled || !isAuthenticated) {
          return AppRoutes.lock;
        }
        return AppRoutes.home;
      }

      // Rule 4: إذا كان مسجل دخول ومصادق عليه (AuthType محدد) وهو في صفحة Lock، redirect إلى home
      if (isLoggedIn && isAuthenticated && state.matchedLocation == AppRoutes.lock) {
        return AppRoutes.home;
      }

      // Rule 5: إذا كان مسجل دخول لكن AuthType غير محدد وهو يحاول الوصول لصفحة محمية، redirect إلى lock
      if (isLoggedIn && !isAuthenticated && isOnProtectedRoute) {
        return AppRoutes.lock;
      }

      // Rule 6: إذا كان قفل التطبيق مفعل وليس في صفحة Lock، redirect إلى lock
      if (isLoggedIn && isLockEnabled && state.matchedLocation != AppRoutes.lock && 
          !isAuthenticated) {
        return AppRoutes.lock;
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
            path: AppRoutes.scanQr,
            name: 'scan-qr',
            builder: (context, state) => const ScanQrScreen(),
          ),
          GoRoute(
            path: AppRoutes.myQr,
            name: 'my-qr',
            builder: (context, state) => const MyQrScreen(),
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
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
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
    if (location.startsWith(AppRoutes.groups)) return 2;
    if (location.startsWith(AppRoutes.addFriend)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
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
        context.go(AppRoutes.groups);
        break;
      case 3:
        context.go(AppRoutes.addFriend);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(location);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n?.home ?? 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n?.chat ?? 'Chat',
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            selectedIcon: const Icon(Icons.group),
            label: l10n?.nearbyCommunities ?? 'Groups',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_add_outlined),
            selectedIcon: const Icon(Icons.person_add),
            label: l10n?.addFriend ?? 'Add Friend',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n?.settings ?? 'Settings',
          ),
        ],
      ),
    );
  }
}

