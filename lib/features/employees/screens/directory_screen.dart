import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/employee_models.dart';
import '../data/employee_repository.dart';
import 'employee_avatar.dart';
import 'employee_detail_screen.dart';

/// Read-only directory browse for every role — invite/status-toggle write
/// actions are Phase 4. There is no free-text search endpoint on the
/// backend yet, so the search box filters within the pages already
/// fetched rather than re-querying the server on every keystroke.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _status;
  final _listKey = GlobalKey<PaginatedListViewState<EmployeeResponse>>();

  static const _statusOptions = ['ACTIVE', 'INACTIVE', 'TERMINATED', 'SUSPENDED'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EmployeeRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Filter by name or employee number',
                    prefixIcon: Icon(Icons.search, color: context.palette.textMuted),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _StatusChip(
                        label: 'All',
                        selected: _status == null,
                        onSelected: () => _setStatus(null),
                      ),
                      const SizedBox(width: 8),
                      for (final status in _statusOptions) ...[
                        _StatusChip(
                          label: status,
                          selected: _status == status,
                          onSelected: () => _setStatus(status),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedListView<EmployeeResponse>(
              key: _listKey,
              emptyMessage: 'No employees found.',
              fetchPage: (page, size) => repository.list(
                status: _status,
                page: page,
                size: size,
              ),
              itemBuilder: (context, employee) {
                if (_query.isNotEmpty &&
                    !employee.fullName.toLowerCase().contains(_query) &&
                    !employee.employeeNumber.toLowerCase().contains(_query)) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  leading: EmployeeAvatar(
                    photoUrl: employee.photoUrl,
                    initials: _initials(employee),
                  ),
                  title: Text(
                    employee.fullName,
                    style: TextStyle(
                      color: context.palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [employee.positionName, employee.departmentName]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: Text(
                    employee.status,
                    style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailScreen(employee: employee),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _setStatus(String? status) {
    setState(() => _status = status);
    _listKey.currentState?.refresh();
  }

  String _initials(EmployeeResponse employee) {
    final first = employee.firstName.isNotEmpty ? employee.firstName[0] : '';
    final last = employee.lastName.isNotEmpty ? employee.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: context.palette.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : context.palette.primary,
        fontSize: 12,
      ),
      backgroundColor: context.palette.surfaceAlt,
      side: BorderSide.none,
    );
  }
}
