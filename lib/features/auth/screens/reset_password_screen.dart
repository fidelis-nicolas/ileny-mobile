import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import '../data/password_policy.dart';
import '../widgets/auth_shell.dart';

/// Completes a password reset started from the emailed link.
///
/// The reset email points at the web app — `RESET_URL_BASE`, which in
/// production is `https://app.ileny.app/reset-password` — so on mobile the
/// token is not handed to us by a deep link: the user pastes the link (or the
/// bare token) here and [_extractToken] pulls the `token` query parameter out
/// of it. A `token` route parameter is honoured too, so registering that URL
/// as an Android App Link / iOS Universal Link later needs no change here.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  /// Token from a deep link, when there is one.
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.token ?? '');
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Keeps the requirements checklist in step with what's typed.
  void _onPasswordChanged() => setState(() {});

  /// Accepts either a bare token or the whole reset URL from the email.
  String _extractToken(String input) {
    final value = input.trim();
    if (!value.contains('token=')) return value;
    final token = Uri.tryParse(value)?.queryParameters['token'];
    return (token == null || token.isEmpty) ? value : token;
  }

  Future<void> _submit() async {
    final token = _extractToken(_tokenController.text);
    final password = _passwordController.text;

    if (token.isEmpty) {
      setState(() => _errorMessage = 'Paste the reset link from your email.');
      return;
    }
    if (!passwordMeetsPolicy(password)) {
      setState(() => _errorMessage = 'Your new password does not meet the requirements below.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthRepository>().resetPassword(
            token: token,
            newPassword: password,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset. Sign in with your new password.'),
        ),
      );
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.statusCode == 400
          ? 'This reset link is invalid or has expired. Request a new one.'
          : e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Reset your password',
      description: 'Paste the link from your reset email, then choose a new password.',
      children: [
        if (_errorMessage != null) AuthFormError(message: _errorMessage!),
        TextField(
          controller: _tokenController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          maxLines: 2,
          minLines: 1,
          style: const TextStyle(color: AppColors.primaryGreen, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Reset link or code'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autocorrect: false,
          style: const TextStyle(color: AppColors.primaryGreen),
          decoration: InputDecoration(
            hintText: 'New password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmController,
          obscureText: _obscurePassword,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitting ? null : _submit(),
          style: const TextStyle(color: AppColors.primaryGreen),
          decoration: const InputDecoration(hintText: 'Confirm new password'),
        ),
        const SizedBox(height: 16),
        _PasswordRequirements(value: _passwordController.text),
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
              : const Text('Reset password'),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}

/// Live checklist of the password policy — every rule stays visible, met or
/// not, so the target never moves while the user types.
class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: passwordRules.map((rule) {
        final met = rule.test(value);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                met ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: met ? AppColors.primaryGreen : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                rule.label,
                style: TextStyle(
                  fontSize: 13,
                  color: met ? AppColors.primaryGreen : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
