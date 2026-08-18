import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';
import '../state/notifications_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _listKey = GlobalKey<PaginatedListViewState<NotificationResponse>>();

  Future<void> _markRead(NotificationResponse notification) async {
    if (notification.isRead) return;
    final repository = context.read<NotificationRepository>();
    try {
      await repository.markRead(notification.id);
      _listKey.currentState?.refresh();
      if (mounted) context.read<NotificationsState>().refreshNow();
    } catch (_) {
      // Marking read is a low-stakes action — a failed tap just leaves the
      // item unread, no need to surface an error dialog for it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<NotificationRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: PaginatedListView<NotificationResponse>(
        key: _listKey,
        emptyMessage: 'No notifications yet.',
        fetchPage: (page, size) => repository.list(page: page, size: size),
        itemBuilder: (context, notification) {
          return ListTile(
            onTap: () => _markRead(notification),
            leading: Icon(
              notification.isRead
                  ? Icons.notifications_none
                  : Icons.notifications,
              color: notification.isRead
                  ? context.palette.textMuted
                  : context.palette.accent,
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                color: context.palette.primary,
                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            subtitle: Text(notification.message),
            trailing: Text(
              _relativeTime(notification.createdAt),
              style: TextStyle(color: context.palette.textMuted, fontSize: 11),
            ),
          );
        },
      ),
    );
  }

  String _relativeTime(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
