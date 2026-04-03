import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Graceful fallback for mock data
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    try {
      _items = List<Map<String, dynamic>>.from(MockData.notifications);
    } catch (_) {
      _items = [];
    }
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
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              textStyle: GoogleFonts.barlow(fontSize: 13),
            ),
            onPressed: () {
              setState(() {
                _items = _items.map((n) => {...n, 'isRead': true}).toList();
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'All caught up',
              subtitle: 'No new notifications',
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                final bool isRead = item['isRead'] == true;
                final String type = item['type'] ?? '';

                return Dismissible(
                  key: ValueKey(item['id'] ?? i.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.red.withValues(alpha: 0.12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.sm2),
                    child: Icon(Icons.delete_outline, color: AppColors.red),
                  ),
                  onDismissed: (_) {
                    setState(() => _items.removeAt(i));
                  },
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
                            color: _colorFor(type).withValues(alpha: 0.12),
                          ),
                          child: Icon(_iconFor(type),
                              size: 22, color: _colorFor(type)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                            margin: const EdgeInsets.only(top: AppSpacing.sm),
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
    );
  }
}
