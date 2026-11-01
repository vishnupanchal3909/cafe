import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
import 'async_view.dart';
import 'theme.dart';
import 'tokens.dart';

typedef Row_ = Map<String, dynamic>;

class CrudColumn {
  const CrudColumn(this.label, this.value, {this.status = false});
  final String label;
  final String Function(Row_ row) value;
  final bool status;
}

class CrudField {
  const CrudField(this.key, this.label, {this.required = true, this.number = false, this.options, this.obscure = false, this.initial});
  final String key;
  final String label;
  final bool required;
  final bool number;
  final List<(String value, String label)>? options;
  final bool obscure;
  final String? initial;
}

class RowAction {
  const RowAction(this.label, this.icon, this.run, {this.visible});
  final String label;
  final IconData icon;
  final Future<void> Function(BuildContext context, Row_ row) run;
  final bool Function(Row_ row)? visible;
}

/// A list, a create form and row actions, from a description. Loading, empty and error states come with it.
/// Used for the many plain record screens, so each one needs only the fields it adds.
class CrudPage extends StatelessWidget {
  const CrudPage({super.key, required this.load, required this.columns, this.createFields, this.onCreate, this.createLabel, this.actions = const [], this.header});
  final Future<List<dynamic>> Function() load;
  final List<CrudColumn> columns;
  final List<CrudField>? createFields;
  final Future<void> Function(BuildContext context, Map<String, String> values)? onCreate;
  final String? createLabel;
  final List<RowAction> actions;
  final Widget? header;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => LoadCubit<List<dynamic>>(load)..load(),
        child: Builder(builder: (c) {
          Future<void> reload() => c.read<LoadCubit<List<dynamic>>>().load(silent: true);
          return Scaffold(
            floatingActionButton: createFields == null
                ? null
                : FloatingActionButton.extended(
                    icon: const Icon(Icons.add),
                    label: Text(createLabel ?? c.l10n.add),
                    onPressed: () async {
                      final values = createFields!.isEmpty ? <String, String>{} : await showFormDialog(c, title: createLabel ?? c.l10n.add, fields: createFields!);
                      if (values == null || !c.mounted) return;
                      try {
                        await onCreate!(c, values);
                        await reload();
                      } catch (e) {
                        if (c.mounted) showFailure(c, e);
                      }
                    },
                  ),
            body: BlocBuilder<LoadCubit<List<dynamic>>, ViewState<List<dynamic>>>(
              builder: (c, s) => AsyncView<List<dynamic>>(
                state: s,
                onRetry: () => c.read<LoadCubit<List<dynamic>>>().load(),
                builder: (rows) => RefreshIndicator(
                  onRefresh: reload,
                  child: LayoutBuilder(builder: (c, box) {
                    final data = rows.cast<Map<dynamic, dynamic>>().map((r) => r.cast<String, dynamic>()).toList();
                    return ListView(padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 96), children: [
                      if (header != null) ...[header!, const SizedBox(height: Space.md)],
                      if (box.maxWidth < Breakpoints.medium)
                        for (final r in data) _RowCard(row: r, columns: columns, actions: actions, reload: reload)
                      else
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [for (final col in columns) DataColumn(label: Text(col.label)), if (actions.isNotEmpty) DataColumn(label: Text(c.l10n.action))],
                              rows: [
                                for (final r in data)
                                  DataRow(cells: [
                                    for (final col in columns) DataCell(col.status ? StatusChip(label: c.l10n.statusLabel(col.value(r)), status: col.value(r)) : Text(col.value(r))),
                                    if (actions.isNotEmpty) DataCell(Row(mainAxisSize: MainAxisSize.min, children: _buttons(c, r, actions, reload))),
                                  ]),
                              ],
                            ),
                          ),
                        ),
                    ]);
                  }),
                ),
              ),
            ),
          );
        }),
      );
}

List<Widget> _buttons(BuildContext c, Row_ r, List<RowAction> actions, Future<void> Function() reload) => [
      for (final a in actions)
        if (a.visible?.call(r) ?? true)
          IconButton(
            tooltip: a.label,
            icon: Icon(a.icon),
            onPressed: () async {
              try {
                await a.run(c, r);
                await reload();
              } catch (e) {
                if (c.mounted) showFailure(c, e);
              }
            },
          ),
    ];

class _RowCard extends StatelessWidget {
  const _RowCard({required this.row, required this.columns, required this.actions, required this.reload});
  final Row_ row;
  final List<CrudColumn> columns;
  final List<RowAction> actions;
  final Future<void> Function() reload;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final c in columns)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 120, child: Text(c.label, style: Theme.of(context).textTheme.labelMedium)),
                    Expanded(child: c.status ? Align(alignment: AlignmentDirectional.centerStart, child: StatusChip(label: context.l10n.statusLabel(c.value(row)), status: c.value(row))) : Text(c.value(row))),
                  ]),
                ),
              if (actions.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.end, children: _buttons(context, row, actions, reload)),
            ]),
          ),
        ),
      );
}

Future<Map<String, String>?> showFormDialog(BuildContext context, {required String title, required List<CrudField> fields}) {
  final form = GlobalKey<FormState>();
  final values = <String, String>{for (final f in fields) if (f.initial != null) f.key: f.initial!};
  return showDialog<Map<String, String>>(
    context: context,
    builder: (c) {
      final l = c.l10n;
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: f.options != null
                        ? DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: f.label),
                            initialValue: f.initial,
                            isExpanded: true,
                            items: [for (final o in f.options!) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
                            onChanged: (v) => values[f.key] = v ?? '',
                            validator: (v) => f.required && (v == null || v.isEmpty) ? l.requiredField : null,
                          )
                        : TextFormField(
                            initialValue: f.initial,
                            decoration: InputDecoration(labelText: f.label),
                            obscureText: f.obscure,
                            keyboardType: f.number ? const TextInputType.numberWithOptions(decimal: true) : null,
                            validator: (v) {
                              if (f.required && (v == null || v.trim().isEmpty)) return l.requiredField;
                              if (f.number && v != null && v.isNotEmpty && double.tryParse(v) == null) return l.invalidValue;
                              return null;
                            },
                            onSaved: (v) => values[f.key] = v?.trim() ?? '',
                          ),
                  ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              form.currentState!.save();
              Navigator.pop(c, values);
            },
            child: Text(l.save),
          ),
        ],
      );
    },
  );
}
