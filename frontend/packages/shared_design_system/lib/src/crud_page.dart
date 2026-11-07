import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
import 'async_view.dart';
import 'depth.dart';
import 'theme.dart';
import 'tokens.dart';

typedef Row_ = Map<String, dynamic>;

class CrudColumn {
  const CrudColumn(this.label, this.value, {this.status = false, this.avatar = false});
  final String label;
  final String Function(Row_ row) value;
  final bool status;

  /// Shows the value with its initial in a circle, for people.
  final bool avatar;
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

/// One choice in the filter row above a [CrudPage].
class CrudFilter {
  const CrudFilter(this.label, this.matches);
  final String label;
  final bool Function(Row_ row) matches;
}

/// Runs a row action with the page's error handling, then reloads.
typedef RunRowAction = Future<void> Function(RowAction action);

/// The actions of a card, tucked behind one button.
class RowActionsMenu extends StatelessWidget {
  const RowActionsMenu({super.key, required this.actions, required this.run, this.icon = Icons.more_vert});
  final List<RowAction> actions;
  final RunRowAction run;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PopupMenuButton<RowAction>(
        icon: Icon(icon),
        tooltip: context.l10n.action,
        onSelected: run,
        itemBuilder: (_) => [
          for (final a in actions)
            PopupMenuItem(value: a, child: Row(children: [Icon(a.icon, size: 20), const SizedBox(width: 12), Flexible(child: Text(a.label))])),
        ],
      );
}

/// A list, a create form and row actions, from a description. Loading, empty and error states come with it.
/// Used for the many plain record screens, so each one needs only the fields it adds.
class CrudPage extends StatelessWidget {
  const CrudPage({super.key, required this.load, required this.columns, this.createFields, this.onCreate, this.createLabel, this.actions = const [], this.header, this.cardBuilder, this.cardWidth = 280, this.cardHeight = 200, this.filters = const [], this.searchText, this.initialFilter = 0, this.onFilterChanged});
  final Future<List<dynamic>> Function() load;
  final List<CrudColumn> columns;
  final List<CrudField>? createFields;
  final Future<void> Function(BuildContext context, Map<String, String> values)? onCreate;
  final String? createLabel;
  final List<RowAction> actions;
  final Widget? header;

  /// When set, rows are shown as a grid of these cards rather than a table.
  final Widget Function(BuildContext context, Row_ row, List<RowAction> visibleActions, RunRowAction run)? cardBuilder;
  final double cardWidth;
  final double cardHeight;
  final List<CrudFilter> filters;

  /// When set, a search box looks through this text.
  final String Function(Row_ row)? searchText;
  final int initialFilter;
  final ValueChanged<int>? onFilterChanged;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => LoadCubit<List<dynamic>>(load)..load(),
        child: Builder(builder: (c) {
          Future<void> reload() => c.read<LoadCubit<List<dynamic>>>().load(silent: true);
          return Scaffold(
            backgroundColor: Colors.transparent,
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
                builder: (rows) => RefreshIndicator(onRefresh: reload, child: _CrudBody(page: this, rows: rows, reload: reload)),
              ),
            ),
          );
        }),
      );
}

class _CrudBody extends StatefulWidget {
  const _CrudBody({required this.page, required this.rows, required this.reload});
  final CrudPage page;
  final List<dynamic> rows;
  final Future<void> Function() reload;
  @override
  State<_CrudBody> createState() => _CrudBodyState();
}

class _CrudBodyState extends State<_CrudBody> {
  late int _filter = widget.page.initialFilter;
  String _search = '';

  Future<void> _run(BuildContext c, RowAction a, Row_ r) async {
    try {
      await a.run(c, r);
      await widget.reload();
    } catch (e) {
      if (c.mounted) showFailure(c, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final all = widget.rows.cast<Map<dynamic, dynamic>>().map((r) => r.cast<String, dynamic>());
    final query = _search.trim().toLowerCase();
    final data = all.where((r) {
      if (page.filters.isNotEmpty && !page.filters[_filter.clamp(0, page.filters.length - 1)].matches(r)) return false;
      return query.isEmpty || page.searchText == null || page.searchText!(r).toLowerCase().contains(query);
    }).toList();
    return LayoutBuilder(builder: (c, box) {
      return ListView(padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 96), children: [
        if (page.header != null) ...[page.header!, const SizedBox(height: Space.md)],
        if (page.searchText != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: depthShadows(Theme.of(c).colorScheme, lift: 0.5)),
                child: TextField(decoration: InputDecoration(hintText: c.l10n.search, prefixIcon: const Icon(Icons.search), isDense: true), onChanged: (v) => setState(() => _search = v)),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
        ],
        if (page.filters.length > 1) ...[
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            for (var i = 0; i < page.filters.length; i++)
              ChoiceChip(
                label: Text(page.filters[i].label),
                selected: i == _filter,
                showCheckmark: false,
                labelStyle: TextStyle(color: i == _filter ? Theme.of(c).colorScheme.onPrimary : Theme.of(c).colorScheme.onSurface, fontWeight: FontWeight.w600),
                onSelected: (_) {
                  setState(() => _filter = i);
                  page.onFilterChanged?.call(i);
                },
              ),
          ]),
          const SizedBox(height: Space.md),
        ],
        if (data.isEmpty && (query.isNotEmpty || page.filters.isNotEmpty))
          const SizedBox(height: 240, child: EmptyState())
        else if (page.cardBuilder != null)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: page.cardWidth, mainAxisExtent: page.cardHeight, crossAxisSpacing: Space.md, mainAxisSpacing: Space.md),
            itemCount: data.length,
            itemBuilder: (c, i) {
              final r = data[i];
              return page.cardBuilder!(c, r, [for (final a in page.actions) if (a.visible?.call(r) ?? true) a], (a) => _run(c, a, r));
            },
          )
        else if (box.maxWidth < Breakpoints.medium)
          for (final r in data) _RowCard(row: r, columns: page.columns, actions: page.actions, reload: widget.reload)
        else
          Raised(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: box.maxWidth - Space.lg),
                child: DataTable(
                  columns: [for (final col in page.columns) DataColumn(label: Text(col.label)), if (page.actions.isNotEmpty) DataColumn(label: Text(c.l10n.action))],
                  rows: [
                    for (final r in data)
                      DataRow(cells: [
                        for (final col in page.columns)
                          DataCell(col.status
                              ? StatusChip(label: c.l10n.statusLabel(col.value(r)), status: col.value(r))
                              : col.avatar
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      GlossyIcon(circle: true, size: 34, color: _avatarColor(Theme.of(c).colorScheme, col.value(r)), child: Text(col.value(r).isEmpty ? '' : col.value(r).characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
                                      const SizedBox(width: 10),
                                      Text(col.value(r), style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ])
                                  : Text(col.value(r))),
                        if (page.actions.isNotEmpty) DataCell(Row(mainAxisSize: MainAxisSize.min, children: _buttons(c, r, page.actions, widget.reload))),
                      ]),
                  ],
                ),
              ),
            ),
          ),
      ]);
    });
  }
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
        padding: const EdgeInsets.only(bottom: Space.md),
        child: Raised(
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

/// One of the theme's colours, picked by name, so the same person always gets the same badge.
Color _avatarColor(ColorScheme s, String name) {
  final options = [s.primary, s.secondary, s.tertiary];
  return options[name.codeUnits.fold<int>(0, (a, b) => a + b) % options.length];
}
