import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
import '../core/admin_repository.dart';

AdminRepository get _r => GetIt.I<AdminRepository>();
String _s(Object? v) => v?.toString() ?? '';
String _when(BuildContext c, Object? v) => v == null ? '' : c.dates.dateTime(DateTime.parse(v.toString()));

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LoadView<Map<String, dynamic>>(
      load: _r.dashboard,
      builder: (c, d, reload) {
        final cafes = d['cafes'] as Map;
        final orders = d['orders'] as Map;
        final subs = d['subscriptions'] as Map;
        num n(Object? v) => num.tryParse('${v ?? 0}') ?? 0;
        final gross = (d['grossByCurrency'] as List).cast<Map<dynamic, dynamic>>();
        final countries = (d['cafesByCountry'] as List).cast<Map<dynamic, dynamic>>();
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(Space.md), children: [
            StatGrid(children: [
              StatCard(label: l.totalCafes, value: c.dates.number(n(cafes['total'])), icon: Icons.storefront, color: Colors.indigo.shade600),
              StatCard(label: l.activeCafes, value: c.dates.number(n(cafes['active'])), icon: Icons.check_circle_outline, color: Colors.green.shade700),
              StatCard(label: l.pendingCafes, value: c.dates.number(n(cafes['pending'])), icon: Icons.hourglass_top, color: Colors.orange.shade800),
              StatCard(label: l.totalCustomers, value: c.dates.number(n(d['customers'])), icon: Icons.people_outline, color: Colors.cyan.shade700),
              StatCard(label: l.totalOrders, value: c.dates.number(n(orders['total'])), icon: Icons.receipt_long, color: Colors.purple.shade600),
              StatCard(label: l.activeSubscriptions, value: c.dates.number(n(subs['active'])), icon: Icons.card_membership, color: Colors.pink.shade600),
            ]),
            const SizedBox(height: Space.md),
            // Shown per currency. Adding different currencies together would be a false number.
            BarList(title: l.grossByCurrency, icon: Icons.payments_outlined, rows: [for (final g in gross) (_s(g['currency_code']), double.parse(_s(g['gross'])), c.money.formatAmount(_s(g['gross']), _s(g['currency_code'])))]),
            const SizedBox(height: Space.md),
            BarList(title: l.cafesByCountry, icon: Icons.public, rows: [for (final g in countries) (_s(g['country_code']), double.parse(_s(g['cafes'])), _s(g['cafes']))]),
          ]),
        );
      },
    );
  }
}

Future<String?> _askReason(BuildContext c) async => (await showFormDialog(c, title: c.l10n.reasonPrompt, fields: [CrudField('reason', c.l10n.reason)]))?['reason'];

class CafesScreen extends StatelessWidget {
  const CafesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Future<void> act(BuildContext c, Map<String, dynamic> r, String status) async {
      final reason = await _askReason(c);
      if (reason != null) await _r.setCafeStatus(r['public_id'] as String, status, reason);
    }
    return CrudPage(
      load: _r.cafes,
      columns: [
        CrudColumn(l.cafeName, (r) => _s(r['display_name'])),
        CrudColumn(l.owner, (r) => '${_s(r['owner_name'])} <${_s(r['owner_email'])}>'),
        CrudColumn(l.country, (r) => _s(r['country_code'])),
        CrudColumn(l.currency, (r) => _s(r['currency_code'])),
        CrudColumn(l.status, (r) => _s(r['status']), status: true),
        CrudColumn(l.date, (r) => _when(context, r['created_at'])),
      ],
      actions: [
        RowAction(l.approve, Icons.check, (c, r) => act(c, r, 'active'), visible: (r) => ['pending_approval', 'rejected', 'suspended'].contains(r['status'])),
        RowAction(l.suspend, Icons.block, (c, r) => act(c, r, 'suspended'), visible: (r) => r['status'] == 'active'),
        RowAction(l.health, Icons.visibility_outlined, (c, r) async {
          final reason = await _askReason(c);
          if (reason == null) return;
          final d = await _r.cafe(r['public_id'] as String, reason);
          if (!c.mounted) return;
          await showDialog<void>(context: c, builder: (x) => AlertDialog(title: Text(_s(d['display_name'])), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${l.legalName}: ${_s(d['legal_name'])}'),
            Text('${l.branches}: ${(d['branches'] as List).length}'),
            Text('${l.staff}: ${_s(d['staffCount'])}'),
            Text('${l.totalOrders}: ${_s(d['orderCount'])}'),
            Text('${l.sales}: ${c.money.formatAmount(_s(d['grossSales']), _s(d['currency_code']))}'),
          ]), actions: [FilledButton(onPressed: () => Navigator.pop(x), child: Text(l.close))]));
        }),
      ],
    );
  }
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(load: _r.users, columns: [
      CrudColumn(l.name, (r) => _s(r['full_name'])),
      CrudColumn(l.email, (r) => _s(r['email'])),
      CrudColumn(l.status, (r) => _s(r['status']), status: true),
      CrudColumn(l.date, (r) => _when(context, r['last_login_at'])),
    ], actions: [
      RowAction(l.disable, Icons.person_off, (c, r) async { final reason = await _askReason(c); if (reason != null) await _r.setUserStatus(r['public_id'] as String, 'disabled', reason); }, visible: (r) => r['status'] != 'disabled'),
      RowAction(l.activate, Icons.person, (c, r) async { final reason = await _askReason(c); if (reason != null) await _r.setUserStatus(r['public_id'] as String, 'active', reason); }, visible: (r) => r['status'] == 'disabled'),
    ]);
  }
}

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = <(String, Widget)>[
      (l.language, CrudPage(
        load: _r.languages,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.notes, (r) => _s(r['native_name']))],
        createFields: [CrudField('code', l.code), CrudField('name', l.name), CrudField('nativeName', l.notes), CrudField('direction', l.language, options: const [('ltr', 'LTR'), ('rtl', 'RTL')], initial: 'ltr')],
        onCreate: (_, v) => _r.saveLanguage(v),
      )),
      (l.currency, CrudPage(
        load: _r.currencies,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.notes, (r) => _s(r['symbol'])), CrudColumn(l.unit, (r) => _s(r['minor_unit']))],
        createFields: [CrudField('code', l.code), CrudField('numericCode', 'ISO 4217'), CrudField('name', l.name), CrudField('symbol', l.notes), CrudField('minorUnit', l.unit, number: true, initial: '2')],
        onCreate: (_, v) => _r.saveCurrency({...v, 'minorUnit': int.parse(v['minorUnit']!)}),
      )),
      (l.countries, CrudPage(
        load: _r.countries,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.currency, (r) => _s(r['default_currency_code'])), CrudColumn(l.timezone, (r) => _s(r['default_timezone']))],
        createFields: [CrudField('code', l.code), CrudField('name', l.name), CrudField('defaultCurrency', l.currency), CrudField('defaultLanguage', l.language), CrudField('defaultTimezone', l.timezone)],
        onCreate: (_, v) => _r.saveCountry(v),
      )),
      (l.translations, CrudPage(
        load: _r.translations,
        columns: [CrudColumn(l.translationKey, (r) => '${_s(r['namespace'])}.${_s(r['translation_key'])}'), CrudColumn(l.language, (r) => _s(r['language_code'])), CrudColumn(l.translationValue, (r) => _s(r['value'])), CrudColumn(l.confirm, (r) => r['is_reviewed'] == 1 ? '✓' : '')],
        createFields: [CrudField('namespace', l.code, initial: 'errors'), CrudField('key', l.translationKey), CrudField('language', l.language), CrudField('value', l.translationValue)],
        onCreate: (_, v) => _r.saveTranslation({...v, 'isReviewed': true}),
      )),
      (l.commissions, CrudPage(
        load: _r.commissions,
        columns: [CrudColumn(l.cafes, (r) => _s(r['display_name'])), CrudColumn(l.percent, (r) => _s(r['rate_percent'])), CrudColumn(l.date, (r) => _when(context, r['valid_from']))],
        createFields: [CrudField('ratePercent', l.percent, number: true)],
        onCreate: (_, v) => _r.addCommission({'ratePercent': v['ratePercent'], 'validFrom': DateTime.now().toUtc().toIso8601String()}),
      )),
      (l.announcements, CrudPage(
        load: _r.announcements,
        columns: [CrudColumn(l.subject, (r) => (r['translations'] as List).map((t) => t['title']).join(' · ')), CrudColumn(l.date, (r) => _when(context, r['starts_at']))],
        createFields: [CrudField('title', l.subject), CrudField('body', l.bodyText), CrudField('language', l.language, initial: 'en')],
        onCreate: (_, v) => _r.announce(v['title']!, v['body']!, v['language']!),
      )),
    ];
    return DefaultTabController(length: tabs.length, child: Column(children: [
      TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t.$1)]),
      Expanded(child: TabBarView(children: [for (final t in tabs) t.$2])),
    ]));
  }
}

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(
      load: _r.plans,
      columns: [
        CrudColumn(l.code, (r) => _s(r['code'])),
        CrudColumn(l.name, (r) => _s(r['name'])),
        CrudColumn(l.status, (r) => r['is_active'] == 1 ? 'active' : 'inactive', status: true),
        CrudColumn(l.price, (r) => (r['prices'] as List).cast<Map<dynamic, dynamic>>().map((p) => '${p['billing_interval']}: ${context.money.formatAmount(_s(p['amount']), _s(p['currency_code']))}').join(', ')),
      ],
      actions: [
        RowAction(l.edit, Icons.edit, (c, r) async {
          final v = await showFormDialog(c, title: _s(r['name']), fields: [
            CrudField('currency', l.currency),
            CrudField('amount', l.price, number: true),
            CrudField('interval', l.date, options: [('monthly', l.periodMonthly), ('yearly', l.periodYearly)]),
            CrudField('active', l.status, options: [('true', l.stActive), ('false', l.stInactive)]),
          ]);
          if (v == null) return;
          final active = v['active'] == 'true';
          await _r.savePlan(r['code'] as String, {'isActive': active, 'isPublic': active, 'prices': [{'currency': v['currency'], 'interval': v['interval'], 'amount': v['amount']}]});
        }),
      ],
    );
  }
}

class CurrenciesScreen extends StatelessWidget {
  const CurrenciesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(
      load: _r.rates,
      createFields: [CrudField('base', l.currency), CrudField('quote', l.currency), CrudField('rate', l.amount, number: true), CrudField('provider', l.name)],
      onCreate: (_, v) => _r.addRate({'base': v['base'], 'quote': v['quote'], 'rate': v['rate'], 'provider': v['provider'], 'effectiveAt': DateTime.now().toUtc().toIso8601String()}),
      columns: [
        CrudColumn(l.currency, (r) => '${_s(r['base_currency_code'])} → ${_s(r['quote_currency_code'])}'),
        CrudColumn(l.amount, (r) => _s(r['rate'])),
        CrudColumn(l.name, (r) => _s(r['provider'])),
        CrudColumn(l.date, (r) => _when(context, r['effective_at'])),
      ],
    );
  }
}

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(load: _r.audit, columns: [
      CrudColumn(l.date, (r) => _when(context, r['occurred_at'])),
      CrudColumn(l.action, (r) => _s(r['action'])),
      CrudColumn(l.cafes, (r) => _s(r['cafe'])),
      CrudColumn(l.reason, (r) => _s(r['reason'])),
    ]);
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(load: _r.tickets, columns: [
      CrudColumn(l.subject, (r) => _s(r['subject'])),
      CrudColumn(l.cafes, (r) => _s(r['cafe'])),
      CrudColumn(l.status, (r) => _s(r['status']), status: true),
      CrudColumn(l.priority, (r) => _s(r['priority'])),
    ], actions: [
      RowAction(l.message, Icons.reply, (c, r) async {
        final v = await showFormDialog(c, title: _s(r['subject']), fields: [CrudField('body', l.message)]);
        if (v != null) await _r.replyTicket(r['public_id'] as String, v['body']!);
      }),
    ]);
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LoadView<Map<String, dynamic>>(
      load: _r.health,
      builder: (c, h, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(padding: const EdgeInsets.all(Space.md), children: [
          StatGrid(children: [
            StatCard(label: l.status, value: _s(h['status'])),
            StatCard(label: l.database, value: _s(h['database'])),
            StatCard(label: l.healthCache, value: _s(h['redis'])),
            StatCard(label: l.healthEvents, value: _s(h['outboxLag'])),
            StatCard(label: l.healthWebhooks, value: _s(h['failedWebhooks'])),
          ]),
        ]),
      ),
    );
  }
}

class MfaScreen extends StatefulWidget {
  const MfaScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final _code = TextEditingController();
  late final Future<Map<String, dynamic>> _begin = _r.beginMfa();

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.enrollMfa)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _begin,
        builder: (c, s) {
          if (!s.hasData) return const SkeletonList(count: 2);
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Padding(padding: const EdgeInsets.all(Space.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.mfaSecret),
            const SizedBox(height: Space.sm),
            SelectableText(_s(s.data!['secret']), style: Theme.of(c).textTheme.titleMedium),
            const SizedBox(height: Space.md),
            TextField(controller: _code, decoration: InputDecoration(labelText: l.mfaCode), keyboardType: TextInputType.number),
            const SizedBox(height: Space.md),
            FilledButton(onPressed: () async {
              try { await _r.confirmMfa(_code.text.trim()); widget.onDone(); } catch (e) { if (c.mounted) showFailure(c, e); }
            }, child: Text(l.confirm)),
          ]))));
        },
      ),
    );
  }
}
