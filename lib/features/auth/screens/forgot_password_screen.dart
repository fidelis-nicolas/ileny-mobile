import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_shell.dart';

/// Requests a password-reset email.
///
/// The confirmation is deliberately non-committal ("if that email is
/// registered") and replaces the form on success, so neither the copy nor the
/// behaviour reveals whether an address belongs to an account — same contract
/// as the web screen and the backend's own response.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthRepository>().forgotPassword(email);
      if (mounted) setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Forgot your password?',
      description: "Enter your work email and we'll send you a reset link.",
      children: _submitted ? _confirmation(context) : _form(context),
    );
  }

  List<Widget> _confirmation(BuildContext context) {
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: const Border(
            left: BorderSide(color: AppColors.primaryGreen, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.primaryGreen,
              size: 26,
            ),
            const SizedBox(height: 12),
            Text(
              'If that email is registered, a reset link has been sent.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.primaryGreen.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      ElevatedButton(
        onPressed: () => context.push('/reset-password'),
        child: const Text('I have the reset link'),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Back to sign in'),
      ),
    ];
  }

  List<Widget> _form(BuildContext context) {
    return [
      if (_errorMessage != null) AuthFormError(message: _errorMessage!),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        onSubmitted: (_) => _submitting ? null : _submit(),
        style: const TextStyle(color: AppColors.primaryGreen),
        decoration: const InputDecoration(hintText: 'you@company.com'),
      ),
      const SizedBox(height: 22),
      ElevatedButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Send reset link'),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: () => context.push('/reset-password'),
        child: const Text('I already have a reset link'),
      ),
      TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Back to sign in'),
      ),
    ];
  }
}
