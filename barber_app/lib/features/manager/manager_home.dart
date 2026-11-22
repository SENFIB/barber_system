import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';

/// صفحه‌ی اصلی آرایشگاه (فعلاً: اطلاعات و وضعیت اشتراک)
class ManagerHome extends StatelessWidget {
  const ManagerHome({
    super.key,
    required this.settings,
    required this.session,
    required this.onRenew,
    required this.onLogout,
  });

  final AppSettings settings;
  final ManagerSession session;
  final VoidCallback onRenew;
  final VoidCallback onLogout;

  static String dateOnly(String iso) =>
      iso.length >= 10 ? iso.substring(0, 10) : iso;

  @override
  Widget build(BuildContext context) {
    final s = S(settings.lang);
    final theme = Theme.of(context);
    final sub = session.subscription;
    final planKey = 'plan_${session.shop.plan}';
    final planName = s.has(planKey) ? s.t(planKey) : session.shop.plan;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(session.shop.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${s.t(session.isOwner ? 'role_owner' : 'role_staff')}  ·  ${session.username}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (sub.expiringSoon && sub.daysLeft != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.tn('expiring_warning', sub.daysLeft!),
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (session.isOwner)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: onRenew,
                            child: Text(s.t('renew')),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t('subscription'),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    row(s.t('plan'), planName),
                    if (sub.free)
                      row(s.t('subscription'), s.t('sub_free'))
                    else ...[
                      row(s.t('subscription'), s.t('sub_active')),
                      if (sub.daysLeft != null)
                        row(s.t('days_left'), '${sub.daysLeft}'),
                      row(s.t('expires_at'), dateOnly(sub.expiresAt)),
                    ],
                    if (session.isOwner && !sub.free)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: onRenew,
                          icon: const Icon(Icons.vpn_key),
                          label: Text(s.t('renew')),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t('manager_soon'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: Text(s.t('logout')),
            ),
          ],
        ),
      ),
    );
  }
}
