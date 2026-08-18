import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/subscription_models.dart';
import '../data/subscription_repository.dart';

/// What the organisation is paying for, when it renews, and what has been
/// charged.
///
/// Read-only by design — see [SubscriptionRepository] for why plan changes stay
/// on the web. The value of having it on a phone is the renewal answer: a
/// "renewal failed" push at 2am is useless if the only way to see what happened
/// is to find a laptop.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Future<_SubscriptionView> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SubscriptionView> _load() async {
    final repository = context.read<SubscriptionRepository>();
    final subscription = await repository.current();
    // Payments are secondary: a tenant with a readable subscription but an
    // unreadable history should still see the top half rather than an error
    // page, so this failure degrades to an empty list.
    List<SubscriptionPaymentResponse> payments;
    try {
      payments = await repository.payments();
    } on ApiException {
      payments = const [];
    }
    return _SubscriptionView(subscription: subscription, payments: payments);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: FutureBuilder<_SubscriptionView>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _ErrorView(
              message: error is ApiException
                  ? error.message
                  : "Your subscription couldn't be loaded.",
              onRetry: _reload,
            );
          }

          final view = snapshot.data!;
          final subscription = view.subscription;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (subscription.lapsed)
                  _Banner(
                    icon: Icons.error_outline,
                    colour: context.palette.danger,
                    title: 'Your subscription has ended.',
                    body: 'Your data is all still here and still readable. Renew from '
                        'Settings → Billing on the web to start making changes again.',
                  )
                else if (subscription.isTrial == true)
                  _Banner(
                    icon: Icons.schedule,
                    colour: context.palette.warning,
                    title: subscription.trialExpiresAt == null
                        ? "You're on the Free Trial."
                        : "You're on the Free Trial until "
                            '${_formatDate(subscription.trialExpiresAt!)}.',
                    body: 'When it ends your organisation becomes read-only until you '
                        'choose a plan. Nothing is deleted.',
                  ),

                const SizedBox(height: 4),
                _DetailCard(
                  rows: [
                    _Row('Plan', subscription.planName ?? '—'),
                    _Row('Billing', _billingLine(subscription)),
                    _Row(
                      'Employees',
                      subscription.maxEmployees == null
                          ? '${subscription.employeeCount}'
                          : '${subscription.employeeCount} of ${subscription.maxEmployees}',
                    ),
                    _Row(
                      subscription.renewsOn != null ? 'Renews' : 'Active until',
                      _activeLine(subscription),
                    ),
                    _Row('Automatic renewal', subscription.autoRenew == true ? 'On' : 'Off'),
                    _Row('Card on file', _cardLine(subscription)),
                  ],
                ),

                if (subscription.maxEmployees != null &&
                    subscription.employeeCount >= subscription.maxEmployees!) ...[
                  const SizedBox(height: 12),
                  Text(
                    "You've reached your plan's employee limit — upgrade on the web to add more.",
                    style: TextStyle(color: context.palette.danger, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 12),
                Text(
                  'Plans are changed on the web dashboard, where payment is handled — '
                  'Settings → Billing.',
                  style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                ),

                const SizedBox(height: 28),
                Text(
                  'Payment history',
                  style: TextStyle(
                    color: context.palette.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (view.payments.isEmpty)
                  Text(
                    'No payments yet.',
                    style: TextStyle(color: context.palette.textMuted),
                  )
                else
                  for (final payment in view.payments) _PaymentTile(payment: payment),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _billingLine(SubscriptionResponse s) {
  if (s.billingInterval == 'YEARLY') {
    return '${_money(s.yearlyPrice)} / year';
  }
  if (s.billingInterval == 'MONTHLY') {
    return '${_money(s.monthlyPrice)} / month';
  }
  return 'Not billed yet';
}

String _activeLine(SubscriptionResponse s) {
  final date = s.activeUntil ?? s.trialExpiresAt;
  return date == null ? '—' : _formatDate(date);
}

String _cardLine(SubscriptionResponse s) {
  if (!s.hasPaymentMethod) return 'None saved';
  return '${s.cardBrand ?? 'Card'} ending ${s.cardLast4 ?? '••••'}';
}

String _money(double? amount) {
  if (amount == null) return '—';
  return NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0).format(amount);
}

String _formatDate(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return iso;
  return DateFormat('d MMM y').format(date);
}

class _SubscriptionView {
  const _SubscriptionView({required this.subscription, required this.payments});

  final SubscriptionResponse subscription;
  final List<SubscriptionPaymentResponse> payments;
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.colour,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: context.palette.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String value;
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: TextStyle(color: context.palette.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: context.palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final SubscriptionPaymentResponse payment;

  @override
  Widget build(BuildContext context) {
    final failed = payment.status != 'SUCCESS';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            failed ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: failed ? context.palette.danger : context.palette.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.planName ?? 'Subscription'} · ${_purposeLabel(payment.purpose)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatDate(payment.paidAt)} · '
                  '${_formatDate(payment.periodStart)} – ${_formatDate(payment.periodEnd)}',
                  style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(payment.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: failed ? context.palette.textMuted : context.palette.primary,
              decoration: failed ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  String _purposeLabel(String purpose) {
    switch (purpose) {
      case 'REGISTRATION':
        return 'Signup';
      case 'UPGRADE':
        return 'Plan change';
      case 'RENEWAL':
        return 'Renewal';
      default:
        return purpose;
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
