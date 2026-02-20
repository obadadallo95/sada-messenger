import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../data/groups_repository.dart';
import '../../../chat/domain/models/chat_model.dart';

/// شاشة اكتشاف المجموعات
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  late final Stream<List<ChatModel>> _nearbyGroupsStream;
  Future<List<ChatModel>>? _myGroupsFuture;

  @override
  void initState() {
    super.initState();
    _nearbyGroupsStream = ref.read(groupsRepositoryProvider).getNearbyGroups();
    _refreshMyGroups();
  }

  void _refreshMyGroups() {
    setState(() {
      _myGroupsFuture = ref.read(groupsRepositoryProvider).getMyGroups();
    });
  }

  Future<void> _openCreateGroup() async {
    await context.push(AppRoutes.createGroup);
    if (!mounted) return;
    _refreshMyGroups();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar مع Radar Animation
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(l10n.nearbyCommunities),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: FadeIn(
                    duration: const Duration(seconds: 2),
                    child: RotationTransition(
                      turns: const AlwaysStoppedAnimation(0.0),
                      child: Icon(
                        Icons.radar,
                        size: 80.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // My Groups Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myGroups,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  FutureBuilder<List<ChatModel>>(
                    future: _myGroupsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 120.h,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 120.h,
                          child: Center(child: Text('خطأ في تحميل المجموعات')),
                        );
                      }

                      final groups = snapshot.data ?? [];

                      if (groups.isEmpty) {
                        return Container(
                          height: 120.h,
                          alignment: Alignment.center,
                          child: Text(
                            'لا توجد مجموعات',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 120.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            return _buildGroupCard(
                              context,
                              group,
                              isJoined: true,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Nearby Communities Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                l10n.nearbyCommunities,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),

          // Nearby Groups List
          StreamBuilder<List<ChatModel>>(
            stream: _nearbyGroupsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(l10n.scanning),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('خطأ: ${snapshot.error}')),
                );
              }

              final groups = snapshot.data ?? [];

              if (groups.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.group_outlined,
                    title: 'لا توجد مجتمعات',
                    subtitle: 'اكتشف مجموعات في منطقتك أو أنشئ مجتمعاً جديداً',
                    actionLabel: 'إنشاء مجتمع',
                    onAction: _openCreateGroup,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = groups[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: _buildGroupCard(context, group, isJoined: false),
                  );
                }, childCount: groups.length),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.lightImpact();
          await _openCreateGroup();
        },
        icon: Icon(Icons.add),
        label: Text(l10n.createCommunity),
      ),
    );
  }

  /// بناء بطاقة مجموعة
  Widget _buildGroupCard(
    BuildContext context,
    ChatModel group, {
    required bool isJoined,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isJoined) {
            context.push('${AppRoutes.chat}/${group.id}', extra: group);
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Group Icon
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Color(group.avatarColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.group,
                  size: 32.sp,
                  color: Color(group.avatarColor),
                ),
              ),
              SizedBox(width: 16.w),

              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.groupName ?? group.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (group.groupDescription != null)
                      Text(
                        group.groupDescription!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          l10n.peersNearby(group.memberCount ?? 0),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Join Button
              if (!isJoined)
                FadeInRight(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(groupsRepositoryProvider)
                            .joinGroup(group.id);
                        _refreshMyGroups();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم الانضمام إلى ${group.groupName}',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ في الانضمام: $e'),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(l10n.join),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
