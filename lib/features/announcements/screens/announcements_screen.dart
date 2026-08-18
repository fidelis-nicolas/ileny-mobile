import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../auth/state/auth_state.dart';
import '../data/announcement_models.dart';
import '../data/announcement_repository.dart';
import 'announcement_detail_screen.dart';
import 'create_announcement_screen.dart';

/// Read-only for everyone; authoring (create/publish) is Tier B, role-gated
/// to HR Manager/Org Admin, as of Phase 4.
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _listKey = GlobalKey<PaginatedListViewState<AnnouncementResponse>>();

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
    );
    if (created == true) _listKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AnnouncementRepository>();
    final isManager = context.watch<AuthState>().hasAnyPermission(kAnnouncementAuthorPermissions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New announcement',
              onPressed: _openCreate,
            ),
        ],
      ),
      body: PaginatedListView<AnnouncementResponse>(
        key: _listKey,
        emptyMessage: 'No announcements yet.',
        fetchPage: (page, size) => repository.listPublished(page: page, size: size),
        itemBuilder: (context, announcement) {
          return ListTile(
            leading: Icon(Icons.campaign_outlined, color: context.palette.primary),
            title: Text(
              announcement.title,
              style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              announcement.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnnouncementDetailScreen(announcement: announcement),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
