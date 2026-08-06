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

class LoginResponse {
  const LoginResponse({required this.twoFactorRequired, this.tokens});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      twoFactorRequired: json['twoFactorRequired'] as bool,
      tokens: json['tokens'] == null
          ? null
          : TokenResponse.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }

  final bool twoFactorRequired;
  final TokenResponse? tokens;
}

class MeResponse {
  const MeResponse({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.roleNames,
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
  final String? employeeId;
  final String? employeeFullName;
  final String? subscriptionPlanName;
  final bool? isTrial;
  final bool? isTwoFactorEnabled;
  final bool? isOnPaidPlan;
  final String? tenantName;
  final String? tenantLogoUrl;
}
