import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shape.dart';

/// The rounded brand tile at the top of every signed-out screen.
class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: palette.border),
        boxShadow: palette.elevation2,
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/ileny_mark.svg',
          width: size * 0.52,
          height: size * 0.52,
        ),
      ),
    );
  }
}

/// Shared plate for the account-recovery screens (forgot password, reset
/// password) — mirrors the web's AuthLayout so the two clients read the same:
/// brand mark, heading, one line of explanation, then the form.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: AuthLogoMark(size: 72)),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.palette.textMuted,
                    ),
              ),
              const SizedBox(height: 32),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline form-level error, styled the same as the sign-in screen's — a tinted
/// plate rather than loose red text.
class AuthFormError extends StatelessWidget {
  const AuthFormError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.danger.withValues(alpha: 0.10),
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: palette.danger.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 18, color: palette.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.danger,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
