import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
import 'depth.dart';
import 'tokens.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.title, required this.onSubmit, this.footer, this.tagline, this.icon = Icons.local_cafe, this.paneIcons = const [Icons.local_cafe, Icons.receipt_long, Icons.insights], this.onBack});
  final String title;

  /// The app's mark, shown on a glossy badge above the form.
  final IconData icon;

  /// What the floating panes beside the form carry on wide screens.
  final List<IconData> paneIcons;

  /// When set, a back button sits in the top corner.
  final VoidCallback? onBack;

  /// A failure with code MFA_REQUIRED reveals the code field. Anything else is shown to the person.
  final Future<void> Function(String email, String password, String? totp) onSubmit;
  final Widget? footer;

  /// When set, wide screens get a branded panel carrying this line beside the form.
  final String? tagline;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _totp = TextEditingController();
  bool _needsTotp = false;
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await widget.onSubmit(_email.text.trim(), _password.text, _needsTotp ? _totp.text.trim() : null);
    } on ApiFailure catch (f) {
      if (!mounted) return;
      if (f.code == 'MFA_REQUIRED') {
        setState(() => _needsTotp = true);
      } else {
        setState(() => _error = context.l10n.failureMessage(f.code, f.message));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); _totp.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;
    final form = AutofillGroup(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Center(child: GlossyIcon(icon: widget.icon, size: 64)),
          const SizedBox(height: Space.md),
          Text(widget.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4), textAlign: TextAlign.center),
          const SizedBox(height: Space.xs),
          Text(l.signInSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: Space.lg),
          TextFormField(controller: _email, decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.alternate_email)), keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], validator: (v) => (v == null || !v.contains('@')) ? l.invalidValue : null),
          const SizedBox(height: Space.md),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              labelText: l.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(tooltip: _hidden ? l.showPassword : l.hidePassword, icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hidden = !_hidden)),
            ),
            obscureText: _hidden,
            autofillHints: const [AutofillHints.password],
            validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_needsTotp) ...[
            const SizedBox(height: Space.md),
            TextFormField(controller: _totp, autofocus: true, decoration: InputDecoration(labelText: l.mfaCode, prefixIcon: const Icon(Icons.pin_outlined)), keyboardType: TextInputType.number, autofillHints: const [AutofillHints.oneTimeCode], validator: (v) => (v == null || v.length != 6) ? l.invalidValue : null, onFieldSubmitted: (_) => _submit()),
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20), const SizedBox(width: Space.sm), Expanded(child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)))]),
            ),
          ],
          const SizedBox(height: Space.lg),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(l.signIn), const SizedBox(width: Space.sm), const Icon(Icons.arrow_forward, size: 18)]),
          ),
          if (widget.footer != null) ...[const SizedBox(height: Space.sm), widget.footer!],
        ]),
      ),
    );
    final card = FloatIn(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: scheme.brightness == Brightness.dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
            border: Border.all(color: Colors.white.withValues(alpha: scheme.brightness == Brightness.dark ? 0.08 : 0.6)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 60, offset: const Offset(0, 30), spreadRadius: -10),
              BoxShadow(color: toneOf(scheme.primary, 0.5).withValues(alpha: 0.35), blurRadius: 80, spreadRadius: -20),
            ],
          ),
          child: form,
        ),
      ),
    );
    final tagline = widget.tagline;
    return Scaffold(
      body: AuroraBackdrop(
        child: SafeArea(
          child: Stack(children: [
            Positioned.fill(child: _layout(context, wide, tagline, card)),
            if (widget.onBack != null)
              PositionedDirectional(top: Space.sm, start: Space.sm, child: IconButton.filledTonal(tooltip: l.back, onPressed: widget.onBack, icon: const BackButtonIcon())),
          ]),
        ),
      ),
    );
  }

  Widget _layout(BuildContext context, bool wide, String? tagline, Widget card) {
    final theme = Theme.of(context);
    return wide && tagline != null
        ? Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(64, 40, 32, 40),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FloatingPanes(icons: widget.paneIcons, size: 320),
                  const SizedBox(height: Space.xl),
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Text(tagline, style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.12, letterSpacing: -0.8))),
                ]),
              ),
            ),
            Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(Space.lg), child: card))),
          ])
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.md),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (tagline != null) ...[
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Text(tagline, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.2))),
                  const SizedBox(height: Space.lg),
                ],
                card,
              ]),
            ),
          );
  }
}
