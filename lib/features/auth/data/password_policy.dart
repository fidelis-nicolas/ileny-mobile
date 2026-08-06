/// Mirrors the backend's `util/PasswordPolicy` (and the web's
/// `lib/password-schema.ts`) so the form can show what's still missing while
/// the user types instead of after a round-trip. The server stays the
/// authority — if the policy there changes, change this list with it.
class PasswordRule {
  PasswordRule({required this.label, required this.test});

  /// Short label for the live requirements checklist.
  final String label;
  final bool Function(String value) test;
}

final List<PasswordRule> passwordRules = [
  PasswordRule(
    label: 'At least 10 characters',
    test: (value) => value.length >= 10,
  ),
  PasswordRule(
    label: 'A lowercase letter',
    test: (value) => RegExp(r'[a-z]').hasMatch(value),
  ),
  PasswordRule(
    label: 'An uppercase letter',
    test: (value) => RegExp(r'[A-Z]').hasMatch(value),
  ),
  PasswordRule(
    label: 'A number',
    test: (value) => RegExp(r'\d').hasMatch(value),
  ),
  PasswordRule(
    label: 'A special character',
    test: (value) => RegExp(r'[^A-Za-z0-9]').hasMatch(value),
  ),
];

bool passwordMeetsPolicy(String value) =>
    passwordRules.every((rule) => rule.test(value));
