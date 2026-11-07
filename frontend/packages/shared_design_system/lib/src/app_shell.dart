import 'package:flutter/material.dart';
import 'depth.dart';
import 'tokens.dart';

class ShellDestination {
  const ShellDestination({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;
}

/// Sidebar on wide screens, drawer on phones. Everything else about the screen stays the same.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.title, required this.destinations, required this.currentPath, required this.onSelect, required this.child, this.actions = const [], this.userName, this.role, this.roleColor});
  final String title;

  /// Who is signed in, and as what. Shown in the sidebar and the top bar, so two portals open side by side are never confused.
  final String? userName;
  final String? role;

  /// The role's own colour, used for its badge and the sidebar's highlight.
  final Color? roleColor;
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
    // A router's nested navigator puts a modal barrier under each page, and that barrier hides every node painted
    // before it from screen readers: the sidebar and the top bar. A container here keeps the barrier inside the page.
    final child = Semantics(container: true, explicitChildNodes: true, child: this.child);
    if (!wide) {
      return AmbientBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(destinations[_index].label), actions: [if (role != null) Center(child: RoleBadge(label: role!, color: roleColor)), ...actions], backgroundColor: Colors.transparent),
          drawer: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            width: 280,
            child: AppSidebar(
              title: title,
              userName: userName,
              role: role,
              roleColor: roleColor,
              destinations: destinations,
              selected: _index,
              onSelect: (i) {
                Navigator.of(context).pop();
                onSelect(destinations[i].path);
              },
            ),
          ),
          body: child,
        ),
      );
    }
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(children: [
          AppSidebar(title: title, userName: userName, role: role, roleColor: roleColor, destinations: destinations, selected: _index, onSelect: (i) => onSelect(destinations[i].path)),
          Expanded(child: Column(children: [
            AppBar(title: Text(destinations[_index].label), actions: [if (role != null) Center(child: RoleBadge(label: role!, color: roleColor)), const SizedBox(width: Space.sm), ...actions, const SizedBox(width: Space.sm)], automaticallyImplyLeading: false, backgroundColor: Colors.transparent, toolbarHeight: 68),
            Expanded(child: child),
          ])),
        ]),
      ),
    );
  }
}

/// The navigation: a floating panel in a deep shade of the app's own colour, labels always visible.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.title, required this.destinations, required this.selected, required this.onSelect, this.userName, this.role, this.roleColor});
  final String title;
  final String? userName;
  final String? role;
  final Color? roleColor;
  final List<ShellDestination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deep = toneOf(scheme.primary, 0.11);
    const ink = Colors.white;
    final highlight = roleColor ?? scheme.secondary;
    final accent = toneOf(highlight, 0.62);
    final onAccent = toneOf(highlight, 0.12);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: 244,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [toneOf(scheme.primary, 0.2), deep, toneOf(scheme.primary, 0.08)]),
          boxShadow: [
            BoxShadow(color: deep.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 18), spreadRadius: -6),
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(children: [
            // Light falling on the panel from the top corner.
            Positioned(top: -120, left: -80, child: IgnorePointer(child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [toneOf(scheme.secondary, 0.5).withValues(alpha: 0.35), Colors.transparent]))))),
            SafeArea(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, 22, Space.md, 22),
                  child: Row(children: [
                    GlossyIcon(color: scheme.secondary, size: 44, child: Text(title.isEmpty ? '' : title.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2))),
                  ]),
                ),
                if (userName != null || role != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, Space.md),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.07), border: Border.all(color: highlight.withValues(alpha: 0.45))),
                      child: Row(children: [
                        GlossyIcon(circle: true, size: 36, color: highlight, child: Text((userName ?? role ?? '').isEmpty ? '' : (userName ?? role)!.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (userName != null) Text(userName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
                          if (role != null) ...[const SizedBox(height: 3), RoleBadge(label: role!, color: highlight, small: true)],
                        ])),
                      ]),
                    ),
                  ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: Space.md), child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                const SizedBox(height: Space.sm),
                Expanded(
                  child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Space.xs), children: [
                    for (var i = 0; i < destinations.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Semantics(
                          container: true,
                          selected: i == selected,
                          button: true,
                          label: destinations[i].label,
                          onTap: () => onSelect(i),
                          excludeSemantics: true,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: i == selected ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(accent, Colors.white, 0.3)!, accent, toneOf(highlight, 0.52)]) : null,
                              boxShadow: i == selected ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -4)] : null,
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => onSelect(i),
                                hoverColor: ink.withValues(alpha: 0.08),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(children: [
                                    Icon(destinations[i].icon, size: 21, color: i == selected ? onAccent : ink.withValues(alpha: 0.78)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(destinations[i].label, overflow: TextOverflow.ellipsis, style: TextStyle(color: i == selected ? onAccent : ink.withValues(alpha: 0.88), fontWeight: i == selected ? FontWeight.w800 : FontWeight.w500))),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The signed-in role as a lit pill, in the role's own colour, with an icon so it never relies on colour alone.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.label, this.color, this.small = false});
  final String label;
  final Color? color;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final base = toneOf(color ?? Theme.of(context).colorScheme.primary, 0.45);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 3 : 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [toneOf(base, 0.55), base]),
          boxShadow: [BoxShadow(color: base.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3), spreadRadius: -2)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_user_outlined, size: small ? 12 : 15, color: Colors.white),
          SizedBox(width: small ? 4 : 6),
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 11.5 : 13, letterSpacing: 0.2)),
        ]),
      ),
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
