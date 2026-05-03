import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/core/theme/app_radius.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import '../../../../shared/widgets/enhanced_empty_state.dart';
import '../../data/models/player_notification_models.dart';
import '../../data/services/player_notifications_service.dart';
import '../providers/notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent * 0.85;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(notificationsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationsControllerProvider.notifier).markAllRead();
      _showMessage('All notifications marked as read');
    } on NotificationsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to mark all notifications as read');
    }
  }

  Future<void> _markSingleRead(String notificationId) async {
    try {
      await ref
          .read(notificationsControllerProvider.notifier)
          .markRead(notificationId);
    } on NotificationsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to mark notification as read');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return AppColors.green;
      case 'BOOKING_CANCELLED':
        return AppColors.red;
      case 'SLOT_EXPIRING':
        return AppColors.amber;
      case 'MATCH_INVITE':
        return AppColors.blue;
      case 'FRIEND_REQUEST':
        return AppColors.amber;
      case 'NO_SHOW_MARKED':
        return AppColors.red;
      case 'REVIEW_REQUEST':
        return AppColors.amber;
      default:
        return AppColors.txtDisabled;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle_rounded;
      case 'BOOKING_CANCELLED':
        return Icons.cancel_rounded;
      case 'SLOT_EXPIRING':
        return Icons.timer_rounded;
      case 'MATCH_INVITE':
        return Icons.group_add_rounded;
      case 'FRIEND_REQUEST':
        return Icons.person_add_rounded;
      case 'NO_SHOW_MARKED':
        return Icons.warning_rounded;
      case 'REVIEW_REQUEST':
        return Icons.star_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.bgPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: state.isRefreshing ? null : controller.refresh,
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
            onPressed: state.items.isEmpty || state.isMarkingAllRead
                ? null
                : _markAllRead,
            child: state.isMarkingAllRead
                ? const SizedBox(
                    width: AppSpacing.md,
                    height: AppSpacing.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoadingInitial || state.isRefreshing)
            const LinearProgressIndicator(minHeight: 2),
          if (state.errorMessage != null && state.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.xs2,
                AppSpacing.xs,
                AppSpacing.xs2,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: AppRadius.small,
                border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: AppTypography.body(context, Theme.of(context).colorScheme).copyWith(color: AppColors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoadingInitial && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.errorMessage != null && state.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTypography.body(context, Theme.of(context).colorScheme).copyWith(color: AppColors.red),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ElevatedButton(
                            onPressed: controller.loadInitial,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyStateWidget(
                          type: EmptyStateType.noNotifications,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = state.items[i];
                      return _NotificationTile(
                        item: item,
                        colorFor: _colorFor,
                        iconFor: _iconFor,
                        onTap: () => _markSingleRead(item.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.colorFor,
    required this.iconFor,
    required this.onTap,
  });

  final PlayerNotification item;
  final Color Function(String type) colorFor;
  final IconData Function(String type) iconFor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead;
    final type = item.type;
    final iconColor = colorFor(type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead
            ? AppColors.bgPrimary
            : AppColors.bgElevated.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSpacing.xl + 4,
              height: AppSpacing.xl + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                iconFor(type),
                size: AppSpacing.md - 2,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.body(context, Theme.of(context).colorScheme).copyWith(
                      fontWeight:
                          isRead ? AppFontWeights.regular : AppFontWeights.semiBold,
                      color:
                          isRead ? AppColors.txtDisabled : AppColors.txtPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.body,
                    style: AppTypography.body(context, Theme.of(context).colorScheme).copyWith(fontSize: 14 * AppTypographyScale.fromContext(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.timeAgo,
                    style: AppTypography.caption(context, Theme.of(context).colorScheme),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: AppSpacing.sm - 7,
                height: AppSpacing.sm - 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}