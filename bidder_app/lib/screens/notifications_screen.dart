import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/state_views.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Official Notifications Center
/// Section 23: Meaningful icons, unread distinguishing, clean timestamps
/// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onNotificationUpdated;
  const NotificationsScreen({super.key, this.onNotificationUpdated});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await ApiService.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.read) return;
    final success = await ApiService.markNotificationAsRead(notif.id);
    if (success && mounted) {
      setState(() {
        notif.read = true;
      });
      widget.onNotificationUpdated?.call();
    }
  }

  Future<void> _markAllAsRead() async {
    for (var n in _notifications) {
      if (!n.read) {
        await ApiService.markNotificationAsRead(n.id);
        n.read = true;
      }
    }
    if (mounted) {
      setState(() {});
      widget.onNotificationUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    }
  }

  IconData _getIcon(String title, String message) {
    final text = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (text.contains('deadline') || text.contains('remaining') || text.contains('expir')) {
      return Icons.alarm_rounded;
    }
    if (text.contains('compliance') || text.contains('evaluat') || text.contains('score')) {
      return Icons.auto_awesome_rounded;
    }
    if (text.contains('review') || text.contains('document') || text.contains('oem') || text.contains('attention')) {
      return Icons.assignment_late_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getColor(String title, String message) {
    final text = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (text.contains('deadline') || text.contains('remaining')) {
      return AppColors.warning;
    }
    if (text.contains('compliance') || text.contains('evaluat')) {
      return AppColors.info;
    }
    if (text.contains('review') || text.contains('attention') || text.contains('required')) {
      return AppColors.error;
    }
    return AppColors.primaryNavy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.read))
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Notifications',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const GovLoadingSkeleton(count: 4);
    }

    if (_notifications.isEmpty) {
      return const GovEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No new notifications',
        description: 'You are all caught up! Updates regarding tender deadlines and compliance evaluations will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primaryNavy,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, idx) {
          final notif = _notifications[idx];
          final iconColor = _getColor(notif.title, notif.message);
          final iconData = _getIcon(notif.title, notif.message);

          return GovCard(
            elevated: !notif.read,
            backgroundColor: notif.read ? Colors.white : AppColors.infoBg.withValues(alpha: 0.25),
            borderColor: notif.read ? AppColors.border : AppColors.infoBorder,
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: () => _markAsRead(notif),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: notif.read ? FontWeight.w600 : FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notif.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.createdAt,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
