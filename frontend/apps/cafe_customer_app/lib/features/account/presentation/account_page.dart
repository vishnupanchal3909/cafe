import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
import '../../session/presentation/session_cubit.dart';
import '../data/account_repository.dart';

/// Accounts are optional. Ordering at a table never requires one.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AccountRepository get _repo => GetIt.I<AccountRepository>();

  @override
  Widget build(BuildContext context) {
    if (!_repo.signedIn) {
      return LoginView(
        title: context.l10n.signIn,
        onSubmit: (e, p, _) async { await _repo.signIn(e, p); if (mounted) setState(() {}); },
        footer: TextButton(onPressed: _register, child: Text(context.l10n.createAccount)),
      );
    }
    final l = context.l10n;
    final slug = context.read<SessionCubit>().state.context?.slug;
    return Scaffold(
      appBar: AppBar(title: Text(l.profile), actions: [
        IconButton(tooltip: l.signOut, icon: const Icon(Icons.logout), onPressed: () async { await _repo.signOut(); if (mounted) setState(() {}); }),
      ]),
      body: ListView(padding: const EdgeInsets.all(Space.md), children: [
        LoadViewBox(load: _repo.profile, builder: (p) => ListTile(leading: const Icon(Icons.person), title: Text('${p['fullName'] ?? ''}'), subtitle: Text('${p['email'] ?? ''}'))),
        if (slug != null) ...[
          LoadViewBox(load: () => _repo.loyalty(slug), builder: (d) => ListTile(leading: const Icon(Icons.loyalty), title: Text(l.offers), trailing: Text('${d['balance']}'))),
          ListTile(leading: const Icon(Icons.favorite_border), title: Text(l.favorites), trailing: IconButton(tooltip: l.add, icon: const Icon(Icons.add), onPressed: () async {
            try { await _repo.addFavorite(slug); if (mounted) setState(() {}); } on ApiFailure catch (f) { if (mounted) showFailure(context, f); }
          })),
        ],
        LoadViewBox(load: _repo.favorites, builder: (rows) => Column(children: [for (final f in rows) ListTile(dense: true, leading: const Icon(Icons.favorite), title: Text('${f['display_name']}'))])),
        if (slug != null) ...[
          const Divider(),
          ListTile(leading: const Icon(Icons.bookmark_border), title: Text(l.wishlist, style: Theme.of(context).textTheme.titleMedium)),
          LoadViewBox(load: () => _repo.wishlist(slug), builder: (rows) => Column(children: [
            for (final w in rows) ListTile(dense: true, title: Text('${w['name']}'), trailing: IconButton(tooltip: l.delete, icon: const Icon(Icons.close), onPressed: () async { await _repo.removeWish(slug, w['publicId'] as String); if (mounted) setState(() {}); })),
          ])),
          ListTile(leading: const Icon(Icons.event_seat), title: Text(l.reserveTable), trailing: const Icon(Icons.chevron_right), onTap: () => _reserve(slug)),
        ],
        const Divider(),
        ListTile(leading: const Icon(Icons.place_outlined), title: Text(l.addresses, style: Theme.of(context).textTheme.titleMedium), trailing: IconButton(tooltip: l.add, icon: const Icon(Icons.add), onPressed: _addAddress)),
        LoadViewBox(load: _repo.addresses, builder: (rows) => Column(children: [
          for (final x in rows) ListTile(dense: true, title: Text('${x['label'] ?? ''} ${x['address_line1']}'), subtitle: Text('${x['city']}'), trailing: IconButton(tooltip: l.delete, icon: const Icon(Icons.close), onPressed: () async { await _repo.removeAddress(x['public_id'] as String); if (mounted) setState(() {}); })),
        ])),
        const Divider(),
        ListTile(title: Text(l.myOrders, style: Theme.of(context).textTheme.titleMedium)),
        LoadViewBox(load: _repo.history, builder: (rows) => Column(children: [
          for (final o in rows)
            ListTile(
              title: Text('${o['cafe']}'),
              subtitle: Text('${l.orderNumber(o['order_number'] as int)} · ${l.orderStatus(o['status'] as String)}'),
              trailing: Text(context.money.formatAmount(o['total_amount'] as String, o['currency_code'] as String)),
            ),
        ])),
        const Divider(),
        TextButton.icon(
          icon: const Icon(Icons.delete_forever),
          label: Text(l.delete),
          onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(l.delete), content: Text(l.profile), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.confirm))]));
            if (ok != true) return;
            await _repo.deleteAccount();
            await _repo.signOut();
            if (mounted) setState(() {});
          },
        ),
      ]),
    );
  }

  Future<void> _addAddress() async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.addresses, fields: [CrudField('label', l.addressLabel, required: false), CrudField('addressLine1', l.address), CrudField('city', l.city), CrudField('countryCode', l.country, initial: context.read<SessionCubit>().state.context?.config.cafe.countryCode)]);
    if (v == null) return;
    try {
      await _repo.addAddress({...v}..removeWhere((_, x) => x.isEmpty));
      if (mounted) setState(() {});
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
    }
  }

  Future<void> _reserve(String slug) async {
    final l = context.l10n;
    final branch = context.read<SessionCubit>().state.context!.branchId;
    final v = await showFormDialog(context, title: l.reserveTable, fields: [CrudField('partySize', l.partySize, number: true, initial: '2'), CrudField('hours', '${l.date} (+h)', number: true, initial: '24'), CrudField('notes', l.notes, required: false)]);
    if (v == null) return;
    final start = DateTime.now().toUtc().add(Duration(hours: int.parse(v['hours']!)));
    try {
      await _repo.reserve(slug, {'branchId': branch, 'partySize': int.parse(v['partySize']!), 'startsAt': start.toIso8601String(), 'endsAt': start.add(const Duration(hours: 2)).toIso8601String(), if ((v['notes'] ?? '').isNotEmpty) 'notes': v['notes']});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.requestSent)));
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
    }
  }

  Future<void> _register() async {
    final l = context.l10n;
    final lang = context.read<SessionCubit>().state.language;
    final v = await showFormDialog(context, title: l.createAccount, fields: [CrudField('name', l.name), CrudField('email', l.email), CrudField('password', l.password, obscure: true)]);
    if (v == null) return;
    try {
      await _repo.register(v['email']!, v['password']!, v['name']!, lang);
      if (mounted) setState(() {});
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
    }
  }
}

class LoadViewBox<T> extends StatelessWidget {
  const LoadViewBox({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: load(),
        builder: (c, s) {
          if (s.hasError) return ListTile(leading: const Icon(Icons.error_outline), title: Text(c.l10n.errorTitle));
          if (!s.hasData) return const Padding(padding: EdgeInsets.all(Space.md), child: LinearProgressIndicator());
          return builder(s.data as T);
        },
      );
}
