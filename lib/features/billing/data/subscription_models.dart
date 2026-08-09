/// The organisation's own subscription (`GET /tenant/subscription`).
///
/// The stored Paystack authorization is never sent to a client — [cardLast4]
/// and [cardBrand] are all that comes back, and all that is needed to name the
/// card on file.
class SubscriptionResponse {
  const SubscriptionResponse({
    this.planName,
    this.maxEmployees,
    this.maxAdmins,
    required this.employeeCount,
    this.monthlyPrice,
    this.yearlyPrice,
    this.billingInterval,
    this.isTrial,
    this.trialExpiresAt,
    this.activeUntil,
    this.autoRenew,
    this.renewsOn,
    required this.lapsed,
    this.cardLast4,
    this.cardBrand,
    required this.hasPaymentMethod,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      planName: json['planName'] as String?,
      maxEmployees: (json['maxEmployees'] as num?)?.toInt(),
      maxAdmins: (json['maxAdmins'] as num?)?.toInt(),
      employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num?)?.toDouble(),
      billingInterval: json['billingInterval'] as String?,
      isTrial: json['isTrial'] as bool?,
      trialExpiresAt: json['trialExpiresAt'] as String?,
      activeUntil: json['activeUntil'] as String?,
      autoRenew: json['autoRenew'] as bool?,
      renewsOn: json['renewsOn'] as String?,
      lapsed: json['lapsed'] as bool? ?? false,
      cardLast4: json['cardLast4'] as String?,
      cardBrand: json['cardBrand'] as String?,
      hasPaymentMethod: json['hasPaymentMethod'] as bool? ?? false,
    );
  }

  final String? planName;
  final int? maxEmployees;
  final int? maxAdmins;
  final int employeeCount;
  final double? monthlyPrice;
  final double? yearlyPrice;
  final String? billingInterval;
  final bool? isTrial;
  final String? trialExpiresAt;
  final String? activeUntil;
  final bool? autoRenew;

  /// When the next charge will be attempted, or null when nothing will be
  /// charged — a trial, auto-renew off, or no card on file.
  final String? renewsOn;

  /// The paid period has ended.
  final bool lapsed;

  final String? cardLast4;
  final String? cardBrand;
  final bool hasPaymentMethod;
}

/// One line of the invoice history. Failed renewal attempts appear here too,
/// which is the point — an administrator asking why access stopped is owed the
/// attempt history, not just the successes.
class SubscriptionPaymentResponse {
  const SubscriptionPaymentResponse({
    required this.id,
    this.planName,
    required this.billingInterval,
    required this.amount,
    required this.currency,
    required this.status,
    required this.purpose,
    required this.paidAt,
    required this.periodStart,
    required this.periodEnd,
  });

  factory SubscriptionPaymentResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentResponse(
      id: json['id'] as String,
      planName: json['planName'] as String?,
      billingInterval: json['billingInterval'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      status: json['status'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      paidAt: json['paidAt'] as String,
      periodStart: json['periodStart'] as String,
      periodEnd: json['periodEnd'] as String,
    );
  }

  final String id;
  final String? planName;
  final String billingInterval;
  final double amount;
  final String currency;
  final String status;

  /// REGISTRATION, UPGRADE, or RENEWAL — the same amount means very different
  /// things depending on which.
  final String purpose;

  final String paidAt;
  final String periodStart;
  final String periodEnd;
}
