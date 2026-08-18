import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/auth_models.dart';

/// The organisation step of a multi-account login: one tappable tile per
/// tenant the submitted credentials matched. Picking one re-submits the same
/// email and password with that tenant's id — see [SignInScreen].
///
/// Purely presentational: it never sees the password, and holds no state of
/// its own beyond what the sign-in screen passes in.
class OrganisationPicker extends StatelessWidget {
  const OrganisationPicker({
    super.key,
    required this.choices,
    required this.onSelected,
    this.enabled = true,
  });

  final List<TenantChoice> choices;
  final ValueChanged<TenantChoice> onSelected;

  /// False while a selection is in flight, so a second tap can't fire a
  /// second login call.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in choices) ...[
          _OrganisationTile(
            choice: choice,
            onTap: enabled ? () => onSelected(choice) : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OrganisationTile extends StatelessWidget {
  const _OrganisationTile({required this.choice, required this.onTap});

  final TenantChoice choice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.palette.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.apartment_outlined,
                size: 20,
                color: context.palette.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  choice.tenantName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.palette.primary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
