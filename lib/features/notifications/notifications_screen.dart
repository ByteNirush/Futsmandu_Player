import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import 'data/services/player_notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final PlayerNotificationsService _notificationsService =
      PlayerNotificationsService.instance;

  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await _notificationsService.getNotifications();
      if (!mounted) return;
      setState(() => _items = records);
    } on NotificationsApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load notifications');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _notificationsService.markAllRead();
      if (!mounted) return;
      setState(() {
        _items =
            _items.map((n) => {...n, 'isRead': true}).toList(growable: false);
      });
      _showMessage('All notifications marked as read');
    } on NotificationsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to mark all notifications as read');
    }
  }

  Future<void> _markOneRead(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final isRead = item['isRead'] == true;
    final id = (item['id'] ?? '').toString();
    if (isRead || id.isEmpty) return;

    try {
      await _notificationsService.markOneRead(notificationId: id);
      if (!mounted) return;
      setState(() {
        _items[index] = {...item, 'isRead': true};
      });
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
        return AppColors.txtDisabled; // txtSecond
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Notifications', style: AppText.h2),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              textStyle: GoogleFonts.barlow(fontSize: 13),
            ),
            onPressed: _items.isEmpty ? null : _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                _error!,
                style: AppText.bodySm.copyWith(color: AppColors.red),
              ),
            ),
          Expanded(
            child: _items.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'All caught up',
                    subtitle: 'No new notifications',
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        final bool isRead = item['isRead'] == true;
                        final String type = item['type'] ?? '';

                        return InkWell(
                          onTap: () => _markOneRead(i),
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
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _colorFor(type).withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    _iconFor(type),
                                    size: 22,
                                    color: _colorFor(type),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? '',
                                        style: AppText.body.copyWith(
                                          fontWeight: isRead
                                              ? FontWeight.w400
                                              : AppTextStyles.semiBold,
                                          color: isRead
                                              ? AppColors.txtDisabled
                                              : AppColors.txtPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['body'] ?? '',
                                        style: AppText.bodySm,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        item['timeAgo'] ?? '',
                                        style: AppText.label,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: AppSpacing.sm),
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.green,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
