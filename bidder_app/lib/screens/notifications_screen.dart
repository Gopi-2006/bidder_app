import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';

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
    final notifs = await ApiService.fetchNotifications();
    setState(() {
      _notifications = notifs;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.read) return;
    final success = await ApiService.markNotificationAsRead(notif.id);
    if (success) {
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
    setState(() {});
    widget.onNotificationUpdated?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All as Read',
            onPressed: _notifications.any((n) => !n.read) ? _markAllAsRead : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: GemTheme.saffron))
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      SizedBox(height: 6),
                      Text('You will receive updates when tenders change or AI completes analysis.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: GemTheme.saffron,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: notif.read ? Colors.white : const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: notif.read ? const Color(0xFFE2E8F0) : GemTheme.saffron.withValues(alpha: 0.5),
                            width: notif.read ? 1 : 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: notif.read
                                  ? const Color(0xFFF1F5F9)
                                  : GemTheme.saffron.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notif.read ? Icons.notifications_outlined : Icons.notifications_active,
                              color: notif.read ? const Color(0xFF64748B) : const Color(0xFFEA580C),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: notif.read ? FontWeight.w600 : FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (!notif.read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: GemTheme.saffron,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.createdAt.contains('T')
                                    ? notif.createdAt.split('T').first
                                    : 'Recent',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          onTap: () => _markAsRead(notif),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
