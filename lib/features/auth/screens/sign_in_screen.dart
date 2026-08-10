import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../legal/widgets/legal_consent_footer.dart';
import '../data/auth_models.dart';
import '../state/auth_state.dart';
import '../widgets/auth_shell.dart';
import '../widgets/organisation_picker.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthState authState) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      if (authState.twoFactorPending) {
        await authState.verifyTwoFactor(_codeController.text.trim());
      } else {
        await authState.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Second half of a multi-organisation login: the same credentials go up
  /// again with the chosen tenant. The password is read straight out of the
  /// field for this one call — it is never persisted, logged, or copied into
  /// [AuthState], and goes away with the controller when this screen does.
  ///
  /// The chosen account may itself have two-factor on, in which case
  /// [AuthState] flips `twoFactorPending` and the form switches to the code
  /// field exactly as it does for a single-account login.
  Future<void> _selectOrganisation(
    AuthState authState,
    TenantChoice choice,
  ) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await authState.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        tenantId: choice.tenantId,
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final tenantChoicePending = authState.tenantChoicePending;
    final twoFactorPending = authState.twoFactorPending;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      const AuthLogoMark(),
                      const SizedBox(height: 20),
                      const Text(
                        'ileny',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          tenantChoicePending
                              ? 'This email is used at more than one organisation. Choose the one to sign in to.'
                              : twoFactorPending
                                  ? 'Enter the verification code sent to your email.'
                                  : 'Your people workspace, in your pocket.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (tenantChoicePending)
                        OrganisationPicker(
                          choices: authState.tenantChoices,
                          enabled: !_submitting,
                          onSelected: (choice) =>
                              _selectOrganisation(authState, choice),
                        )
                      else if (twoFactorPending)
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.primaryGreen),
                          decoration: const InputDecoration(hintText: '6-digit code'),
                        )
                      else ...[
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.primaryGreen),
                          decoration: const InputDecoration(
                            hintText: 'jonas.weber@maplecrest.com',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.primaryGreen),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (tenantChoicePending) ...[
                        // The picker submits on tap, so there's no primary
                        // button here — just the in-flight indicator and a
                        // way back to the ordinary form.
                        if (_submitting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () {
                                  setState(() => _errorMessage = null);
                                  authState.cancelTenantChoice();
                                },
                          child: const Text('Back to sign in'),
                        ),
                      ] else
                        ElevatedButton(
                          onPressed:
                              _submitting ? null : () => _submit(authState),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(twoFactorPending ? 'Verify' : 'Sign in'),
                        ),
                      const SizedBox(height: 14),
                      if (!tenantChoicePending && !twoFactorPending) ...[
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Sign in with SSO'),
                        ),
                      ],
                      const Spacer(flex: 2),
                      const LegalConsentFooter(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
