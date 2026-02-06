import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../core/widgets/double_back_to_exit.dart';
import '../../../../core/widgets/in_app_notification.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/domain/models/chat_model.dart';
import '../../../chat/presentation/widgets/chat_tile.dart';
import '../../../profile/profile_service.dart';

/// شاشة الرئيسية - قائمة المحادثات
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isSpeedDialOpen = false;
  late AnimationController _speedDialController;
  late Animation<double> _speedDialAnimation;

  // Showcase Keys
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speedDialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _speedDialAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeInOut,
    );
    _checkAndStartShowcase();
  }

  /// التحقق من عرض Showcase Tour
  Future<void> _checkAndStartShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('hasSeenHomeTour') ?? false;

    if (!hasSeenTour && mounted) {
      // انتظار بناء الـ widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([
            _profileKey,
            _fabKey,
          ]);
          // حفظ أن المستخدم شاهد الـ tour
          prefs.setBool('hasSeenHomeTour', true);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speedDialController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // يمكن استخدام هذا للتحقق من حالة التطبيق
    super.didChangeAppLifecycleState(state);
  }
  
  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _speedDialController.forward();
      } else {
        _speedDialController.reverse();
      }
    });
  }
  
  Widget _buildSpeedDial(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Speed Dial Options
        if (_isSpeedDialOpen)
          Positioned(
            bottom: 80.h,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Create Group Option
                ScaleTransition(
                  scale: _speedDialAnimation,
                  child: Material(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(28.r),
                    child: InkWell(
                      onTap: () {
                        _toggleSpeedDial();
                        context.push(AppRoutes.createGroup);
                      },
                      borderRadius: BorderRadius.circular(28.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_add, color: Colors.white),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.createCommunity,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // Add Friend Option
                ScaleTransition(
                  scale: _speedDialAnimation,
                  child: Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(28.r),
                    child: InkWell(
                      onTap: () {
                        _toggleSpeedDial();
                        context.push(AppRoutes.addFriend);
                      },
                      borderRadius: BorderRadius.circular(28.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add, color: Colors.white),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.addFriend,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleSpeedDial,
          backgroundColor: theme.colorScheme.primary,
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: 0.125).animate(_speedDialAnimation),
            child: Icon(
              _isSpeedDialOpen ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToChat(BuildContext context, ChatModel chat) {
    context.push('/chat/${chat.id}', extra: chat);
  }

  /// محاكاة رسالة واردة
  Future<void> _simulateIncomingMessage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final notificationService = ref.read(notificationServiceProvider);

    // إظهار رسالة المحاكاة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.simulatingMessage),
        duration: const Duration(seconds: 1),
      ),
    );

    // انتظار 3 ثوان (محاكاة تأخير الشبكة)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // بيانات المحاكاة
    const chatId = 'chat_simulated_123';
    const senderName = 'Sarah';
    const messageText = 'Hello neighbor!';
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    // التحقق من حالة التطبيق
    final appState = WidgetsBinding.instance.lifecycleState;
    final isInForeground = appState == AppLifecycleState.resumed;

    if (isInForeground) {
      // إظهار إشعار داخل التطبيق
      InAppNotificationOverlay.show(
        context: context,
        title: senderName,
        body: messageText,
        chatId: chatId,
        avatarColor: Colors.teal,
        onTap: () {
          // التنقل إلى المحادثة (في هذه الحالة سنعرض رسالة)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم النقر على إشعار من $senderName'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    } else {
      // إظهار إشعار النظام
      final notificationTitle = l10n.newMessageFrom(senderName);
      await notificationService.showChatNotification(
        id: notificationId,
        title: notificationTitle,
        body: messageText,
        payload: chatId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatsAsync = ref.watch(chatRepositoryProvider);
    final theme = Theme.of(context);

    return ShowCaseWidget(
      builder: (context) => DoubleBackToExit(
        child: Scaffold(
        body: CustomScrollView(
        slivers: [
          // SliverAppBar
          SliverAppBar(
            expandedHeight: 120.h,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.appName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              centerTitle: false,
              titlePadding: EdgeInsets.only(
                left: 16.w,
                bottom: 16.h,
              ),
            ),
            leading: Padding(
              padding: EdgeInsets.all(8.w),
              child: Showcase(
                key: _profileKey,
                title: l10n.yourIdentity,
                description: l10n.yourIdentityDescription,
                targetShapeBorder: const CircleBorder(),
                tooltipBackgroundColor: theme.colorScheme.primary,
                textColor: Colors.white,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                descTextStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14.sp,
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final profileState = ref.watch(profileServiceProvider);
                    final authService = ref.read(authServiceProvider.notifier);
                    final currentUser = authService.currentUser;
                    
                    return UserAvatar(
                      base64Image: profileState.avatarBase64,
                      userName: currentUser?.displayName ?? 'User',
                      radius: 20.r,
                    );
                  },
                ),
              ),
            ),
            actions: [
              // زر محاكاة الرسالة (للاختبار)
              IconButton(
                icon: Icon(Icons.notifications_active),
                tooltip: l10n.simulateMessage,
                onPressed: () => _simulateIncomingMessage(context),
              ),
            ],
          ),
          // قائمة المحادثات
          chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          l10n.noChats,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18.sp,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chat = chats[index];
                    return ChatTile(
                      chat: chat,
                      onTap: () => _navigateToChat(context, chat),
                    );
                  },
                  childCount: chats.length,
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.errorLoadingChats,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18.sp,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        // Floating Action Button with Speed Dial
        floatingActionButton: Showcase(
          key: _fabKey,
          title: l10n.startConnecting,
          description: l10n.startConnectingDescription,
          targetShapeBorder: const CircleBorder(),
          tooltipBackgroundColor: theme.colorScheme.primary,
          textColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          descTextStyle: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14.sp,
          ),
          child: _buildSpeedDial(context),
        ),
      ),
    ),
    );
  }
}

