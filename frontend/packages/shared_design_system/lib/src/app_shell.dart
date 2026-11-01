import 'package:flutter/material.dart';
import 'tokens.dart';

class ShellDestination {
  const ShellDestination({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;
}

/// Rail on wide screens, drawer on phones. Everything else about the screen stays the same.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.title, required this.destinations, required this.currentPath, required this.onSelect, required this.child, this.actions = const []});
  final String title;
  final List<ShellDestination> destinations;
  final String currentPath;
  final ValueChanged<String> onSelect;
  final Widget child;
  final List<Widget> actions;

  int get _index {
    final i = destinations.indexWhere((d) => currentPath.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;
    final appBar = AppBar(title: Text(wide ? title : destinations[_index].label), actions: actions);
    if (!wide) {
      return Scaffold(
        appBar: appBar,
        drawer: NavigationDrawer(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            Navigator.of(context).pop();
            onSelect(destinations[i].path);
          },
          children: [
            Padding(padding: const EdgeInsets.all(Space.md), child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            for (final d in destinations) NavigationDrawerDestination(icon: Icon(d.icon), label: Text(d.label)),
          ],
        ),
        body: child,
      );
    }
    return Scaffold(
      appBar: appBar,
      body: Row(children: [
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - kToolbarHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedIndex: _index,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => onSelect(destinations[i].path),
                destinations: [for (final d in destinations) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label))],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key, required this.languages, required this.onSelected});
  final List<(String code, String label)> languages;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Icons.language),
        tooltip: context.l10n.language,
        onSelected: onSelected,
        itemBuilder: (_) => [for (final l in languages) PopupMenuItem(value: l.$1, child: Text(l.$2))],
      );
}
