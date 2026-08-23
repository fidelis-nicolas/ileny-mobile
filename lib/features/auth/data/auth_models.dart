class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresIn;
}

/// One organisation a login could be for, when the address has accounts in
/// several tenants. Carries only what the picker has to render.
class TenantChoice {
  const TenantChoice({required this.tenantId, required this.tenantName});

  factory TenantChoice.fromJson(Map<String, dynamic> json) {
    return TenantChoice(
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
    );
  }

  final String tenantId;
  final String tenantName;
}

/// The outcome of a login attempt, in one of three shapes: a tenant choice
/// (the credentials were valid for more than one organisation, so the caller
/// re-submits them with the chosen `tenantId`), a two-factor challenge, or a
/// started session. Callers must check [tenantChoices] *before*
/// [twoFactorRequired] and [tokens] — the tenant-choice shape has neither of
/// those set, so code written against the older two-shape contract silently
/// does nothing.
class LoginResponse {
  const LoginResponse({
    required this.twoFactorRequired,
    this.tokens,
    this.tenantChoices,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      twoFactorRequired: json['twoFactorRequired'] as bool? ?? false,
      tokens: json['tokens'] == null
          ? null
          : TokenResponse.fromJson(json['tokens'] as Map<String, dynamic>),
      tenantChoices: json['tenantChoices'] == null
          ? null
          : (json['tenantChoices'] as List<dynamic>)
              .map((e) => TenantChoice.fromJson(e as Map<String, dynamic>))
              .toList(growable: false),
    );
  }

  final bool twoFactorRequired;
  final TokenResponse? tokens;
  final List<TenantChoice>? tenantChoices;

  /// True when the server answered with organisations to pick between.
  bool get tenantChoiceRequired => tenantChoices?.isNotEmpty ?? false;
}

class MeResponse {
  const MeResponse({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.roleNames,
    required this.permissions,
    this.employeeId,
    this.employeeFullName,
    this.subscriptionPlanName,
    this.isTrial,
    this.isTwoFactorEnabled,
    this.isOnPaidPlan,
    this.tenantName,
    this.tenantLogoUrl,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      email: json['email'] as String,
      roleNames: (json['roleNames'] as List<dynamic>).cast<String>(),
      // Tolerates absence so a client can talk to a backend that predates the field
      // rather than failing to parse the session outright.
      permissions:
          (json['permissions'] as List<dynamic>?)?.cast<String>() ?? const [],
      employeeId: json['employeeId'] as String?,
      employeeFullName: json['employeeFullName'] as String?,
      subscriptionPlanName: json['subscriptionPlanName'] as String?,
      isTrial: json['isTrial'] as bool?,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] as bool?,
      isOnPaidPlan: json['isOnPaidPlan'] as bool?,
      tenantName: json['tenantName'] as String?,
      tenantLogoUrl: json['tenantLogoUrl'] as String?,
    );
  }

  final String id;
  final String tenantId;
  final String email;
  final List<String> roleNames;

  /// Every permission the account holds, flattened across its roles — the same set
  /// the backend's @PreAuthorize checks.
  ///
  /// Gate on this rather than on [roleNames]. These are the very strings the server compares,
  /// so a check written against them cannot disagree with the one that actually decides;
  /// gating on a role name restates the backend's mapping here, where it drifts unnoticed.
  final List<String> permissions;
  final String? employeeId;
  final String? employeeFullName;
  final String? subscriptionPlanName;
  final bool? isTrial;
  final bool? isTwoFactorEnabled;
  final bool? isOnPaidPlan;
  final String? tenantName;
  final String? tenantLogoUrl;
}
