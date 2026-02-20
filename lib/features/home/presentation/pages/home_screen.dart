import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';
import '../../../../core/widgets/glowing_orb_fab.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/mesh_status_bar.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/log_service.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/domain/models/chat_model.dart';
import '../../../chat/presentation/widgets/glass_chat_tile.dart';
import '../../../profile/profile_service.dart';
import '../../../network/presentation/providers/network_state_provider.dart';
import '../../../network/presentation/providers/relay_queue_provider.dart';

/// شاشة الرئيسية - قائمة المحادثات
/// محدثة لدعم Android 15/16 و Flutter 3.27+ / 4.x
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
  final GlobalKey _fabKey = GlobalKey(debugLabel: 'home_fab');
  final GlobalKey _profileKey = GlobalKey();

  // Double Back to Exit
  DateTime? _lastBackPress;

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
    // لا نستدعي _checkAndStartShowcase هنا - سيتم استدعاؤها من builder callback
  }

  /// التحقق من عرض Showcase Tour
  Future<void> _checkAndStartShowcase() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('hasSeenHomeTour') ?? false;

    if (!hasSeenTour && mounted) {
      try {
        // استخدام API الجديد ShowcaseView.get()
        ShowcaseView.get().startShowCase([_profileKey, _fabKey]);
        // حفظ أن المستخدم شاهد الـ tour
        await prefs.setBool('hasSeenHomeTour', true);
      } catch (e) {
        // Fallback إذا فشل ShowcaseView
        LogService.warning('فشل بدء Showcase - سيتم المحاولة لاحقاً', e);
        // لا نحفظ hasSeenHomeTour حتى ينجح العرض
      }
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
    final onSecondary = theme.colorScheme.onSecondary;
    final onTertiary = theme.colorScheme.onTertiary;
    final onTertiaryContainer = theme.colorScheme.onTertiaryContainer;

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
                // Scan QR Option
                ScaleTransition(
                  scale: _speedDialAnimation,
                  child: Material(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(28.r),
                    child: InkWell(
                      onTap: () {
                        _toggleSpeedDial();
                        context.push(AppRoutes.scanQr);
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
                            Icon(Icons.qr_code_scanner, color: onTertiary),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.scanQrCode,
                              style: TextStyle(
                                color: onTertiary,
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
                // Safe Notes Option
                ScaleTransition(
                  scale: _speedDialAnimation,
                  child: Material(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(28.r),
                    child: InkWell(
                      onTap: () {
                        _toggleSpeedDial();
                        context.push(AppRoutes.safeNotes);
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
                            Icon(Icons.notes, color: onTertiaryContainer),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.localeName == 'ar' ? 'ملاحظاتي' : 'My Notes',
                              style: TextStyle(
                                color: onTertiaryContainer,
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
                            Icon(Icons.group_add, color: onSecondary),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.createCommunity,
                              style: TextStyle(
                                color: onSecondary,
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

        // Main FAB - Glowing Orb
        GlowingOrbFAB(
          onPressed: _toggleSpeedDial,
          icon: _isSpeedDialOpen ? Icons.close : Icons.radar,
          glowColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  void _navigateToChat(BuildContext context, ChatModel chat) {
    context.push('${AppRoutes.chat}/${chat.id}', extra: chat);
  }

  /// معالجة Double Back to Exit مع دعم Predictive Back Gesture
  void _handleBackPress(BuildContext context) {
    final now = DateTime.now();
    final shouldExit =
        _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);

    if (shouldExit) {
      // الضغط الثاني خلال ثانيتين - إغلاق التطبيق
      SystemNavigator.pop();
    } else {
      // الضغط الأول أو بعد ثانيتين - عرض رسالة
      _lastBackPress = now;
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.exitMessage,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
              left: 16.w,
              right: 16.w,
            ),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatsAsync = ref.watch(chatRepositoryProvider);
    final networkState = ref.watch(networkStateProvider);
    final relayCountAsync = ref.watch(relayQueueCountProvider);
    final theme = Theme.of(context);

    // استخدام ShowCaseWidget مع ignore للتحذيرات (API الجديد غير متوفر بعد)
    // ignore: deprecated_member_use
    return ShowCaseWidget(
      builder: (showcaseContext) {
        // بدء Showcase بعد أن يكون context متاحاً
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAndStartShowcase();
          }
        });

        return Builder(
          builder: (builderContext) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              // إذا تم الإغلاق بالفعل، لا نفعل شيء
              if (didPop) return;

              // معالجة Double Back to Exit
              _handleBackPress(builderContext);
            },
            child: MeshGradientBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // SliverAppBar - Transparent with blur
                    SliverAppBar(
                      expandedHeight: 120.h,
                      floating: true,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.3,
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: FlexibleSpaceBar(
                              title: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmallScreen =
                                      constraints.maxWidth < 300;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          l10n.home,
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isSmallScreen) ...[
                                        SizedBox(width: 12.w),
                                        // Mesh Status Bar
                                        Flexible(
                                          child: MeshStatusBar(
                                            status: networkState.peerCount > 0
                                                ? MeshStatus.connected
                                                : (networkState.isScanning
                                                      ? MeshStatus.connecting
                                                      : MeshStatus.offline),
                                            peerCount: networkState.peerCount,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              centerTitle: false,
                              titlePadding: EdgeInsets.only(
                                left: 16.w,
                                bottom: 16.h,
                              ),
                            ),
                          ),
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
                          textColor: theme.colorScheme.onPrimary,
                          titleTextStyle: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          descTextStyle: TextStyle(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.9,
                            ),
                            fontSize: 14.sp,
                          ),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final profileState = ref.watch(
                                profileServiceProvider,
                              );
                              final authService = ref.read(
                                authServiceProvider.notifier,
                              );
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
                        // Network Status Indicator
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: _NetworkStatusIndicator(state: networkState),
                        ),
                        // زر الإشعارات
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          tooltip: l10n.notifications,
                          onPressed: () {
                            context.push(AppRoutes.notifications);
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                        child: _buildRelayParticipationBanner(
                          context,
                          relayCountAsync: relayCountAsync,
                        ),
                      ),
                    ),
                    // قائمة المحادثات
                    chatsAsync.when(
                      data: (chats) {
                        if (chats.isEmpty) {
                          return SliverFillRemaining(
                            child: EmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: l10n.noChats,
                              subtitle: 'ابدأ محادثة آمنة ومشفرة مع أصدقائك',
                              actionLabel: l10n.addFriend,
                              onAction: () => context.push(AppRoutes.addFriend),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final chat = chats[index];
                            return GlassChatTile(
                              chat: chat,
                              onTap: () => _navigateToChat(context, chat),
                              index: index,
                            );
                          }, childCount: chats.length),
                        );
                      },
                      loading: () => SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      error: (error, stack) {
                        // Log the error for debugging
                        LogService.error(
                          'CHAT REPOSITORY ERROR: $error',
                          error,
                        );

                        // Show Empty State instead of Error for better UX
                        return SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: l10n.noChats,
                            subtitle: 'ابدأ محادثة آمنة ومشفرة مع أصدقائك',
                            actionLabel: l10n.addFriend,
                            onAction: () => context.push(AppRoutes.addFriend),
                          ),
                        );
                      },
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
                  textColor: theme.colorScheme.onPrimary,
                  titleTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  descTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                  ),
                  child: _buildSpeedDial(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelayParticipationBanner(
    BuildContext context, {
    required AsyncValue<int> relayCountAsync,
  }) {
    final theme = Theme.of(context);
    final relayCount = relayCountAsync.valueOrNull ?? 0;
    final text = relayCountAsync.isLoading
        ? 'جارٍ مزامنة دورك في الشبكة...'
        : relayCount > 0
        ? '📦 أنت تحمل $relayCount حزمة مشفرة للشبكة حالياً'
        : '📦 لا تحمل حالياً أي حزم مرحّلة للشبكة';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 18.sp,
            color: theme.colorScheme.secondary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkStatusIndicator extends StatelessWidget {
  final NetworkState state;

  const _NetworkStatusIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Determine status color and glow
    final isConnected = state.peerCount > 0; // Removed state.isConnected as it doesn't exist
    final isScanning = state.isScanning;
    
    final Color statusColor;
    final List<BoxShadow> shadows;
    final String tooltip;

    if (isConnected) {
      statusColor = const Color(0xFF00FF9D); // Neon Green
      shadows = [
        BoxShadow(
          color: const Color(0xFF00FF9D).withValues(alpha: 0.6),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ];
      tooltip = 'Mesh Active: ${state.peerCount} Peers Connected';
    } else if (isScanning) {
      statusColor = const Color(0xFF00E5FF); // Cyan for scanning
      shadows = [
        BoxShadow(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ];
      tooltip = 'Scanning for peers...';
    } else {
      statusColor = const Color(0xFFFF3D00); // Neon Red
      shadows = [
        BoxShadow(
          color: const Color(0xFFFF3D00).withValues(alpha: 0.3),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];
      tooltip = 'Mesh Offline';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          boxShadow: shadows,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
