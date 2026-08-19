import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../data/announcement_models.dart';
import '../data/announcement_repository.dart';
import '../widgets/poll_card.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({super.key, required this.announcement});

  final AnnouncementResponse announcement;

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Best-effort read receipt — failure shouldn't block viewing the content.
    context.read<AnnouncementRepository>().markRead(widget.announcement.id).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;
    final date = DateTime.tryParse(announcement.createdAt)?.toLocal();

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (announcement.priority != 'NORMAL')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PriorityBadge(priority: announcement.priority),
            ),
          Text(
            announcement.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.palette.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (announcement.authorName.isNotEmpty) announcement.authorName,
              if (date != null) DateFormat('MMM d, yyyy · h:mm a').format(date),
            ].join(' · '),
            style: TextStyle(color: context.palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Text(
            announcement.body,
            style: TextStyle(color: context.palette.primary, fontSize: 15, height: 1.5),
          ),
          // Below the body, which is the context the question is asked in.
          if (announcement.poll != null) ...[
            const SizedBox(height: 20),
            PollCard(announcementId: announcement.id, poll: announcement.poll!),
          ],
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: context.palette.accentInk,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
