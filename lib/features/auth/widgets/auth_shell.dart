import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

/// The rounded brand tile at the top of every signed-out screen.
class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
      backgroundColor: AppColors.background,
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
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.primaryGreen,
                  ),
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: AuthLogoMark(size: 72)),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textMuted,
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

/// Inline form-level error, styled the same as the sign-in screen's.
class AuthFormError extends StatelessWidget {
  const AuthFormError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.accentOrange, fontSize: 13),
      ),
    );
  }
}
