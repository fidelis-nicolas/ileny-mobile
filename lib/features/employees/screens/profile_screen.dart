import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../legal/legal_documents.dart';
import '../data/employee_models.dart';
import '../data/employee_repository.dart';
import 'employee_avatar.dart';
import 'employee_labels.dart';

/// View-only "me" profile, plus a Phase 5 self-service photo change.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<EmployeeResponse> _future;
  bool _changingPhoto = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<EmployeeRepository>().me();
  }

  Future<void> _reload() async {
    final future = context.read<EmployeeRepository>().me();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (photo == null || !mounted) return;

    final repository = context.read<EmployeeRepository>();
    setState(() => _changingPhoto = true);
    try {
      final updated = await repository.uploadMyPhoto(photo.path);
      setState(() => _future = Future.value(updated));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder<EmployeeResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load your profile.';
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final employee = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _changingPhoto ? null : _changePhoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        EmployeeAvatar(
                          photoUrl: employee.photoUrl,
                          initials: _initials(employee),
                          radius: 44,
                        ),
                        if (_changingPhoto)
                          const Positioned.fill(
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.palette.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    employee.fullName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.palette.primary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    employee.employeeNumber,
                    style: TextStyle(color: context.palette.textMuted),
                  ),
                ),
                const SizedBox(height: 24),
                _InfoTile(label: 'Position', value: employee.positionName),
                _InfoTile(label: 'Department', value: employee.departmentName),
                _InfoTile(label: 'Branch', value: employee.branchName),
                _InfoTile(label: 'Employment type', value: employee.employmentType),
                _InfoTile(label: 'Status', value: employee.status),
                _InfoTile(label: 'Email', value: employee.email),
                _InfoTile(label: 'Phone', value: employee.phone),
                _InfoTile(label: 'Hire date', value: employee.hireDate),
                _InfoTile(
                  label: 'Qualification',
                  value: qualificationLabel(employee.qualification),
                ),
                const _LegalSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  String _initials(EmployeeResponse employee) {
    final first = employee.firstName.isNotEmpty ? employee.firstName[0] : '';
    final last = employee.lastName.isNotEmpty ? employee.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

/// Where the terms and privacy policy are reachable from once signed in.
/// Google Play expects the policy to be findable inside the app, not only on
/// the store listing. Both open in the browser — see [LegalDocument].
class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: context.palette.border),
        Padding(
          padding: EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            'Legal',
            style: TextStyle(color: context.palette.textMuted, fontSize: 13),
          ),
        ),
        for (final document in LegalDocument.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              document.title,
              style: TextStyle(
                color: context.palette.primary,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: context.palette.textMuted,
            ),
            onTap: () => document.open(context),
          ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: context.palette.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value!.isEmpty) ? '—' : value!,
              style: TextStyle(color: context.palette.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
