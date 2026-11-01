import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
import 'tokens.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.title, required this.onSubmit, this.footer});
  final String title;

  /// A failure with code MFA_REQUIRED reveals the code field. Anything else is shown to the person.
  final Future<void> Function(String email, String password, String? totp) onSubmit;
  final Widget? footer;

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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: Space.lg),
                  TextFormField(controller: _email, decoration: InputDecoration(labelText: l.email), keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], validator: (v) => (v == null || !v.contains('@')) ? l.invalidValue : null),
                  const SizedBox(height: Space.md),
                  TextFormField(controller: _password, decoration: InputDecoration(labelText: l.password), obscureText: true, autofillHints: const [AutofillHints.password], validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null, onFieldSubmitted: (_) => _submit()),
                  if (_needsTotp) ...[
                    const SizedBox(height: Space.md),
                    TextFormField(controller: _totp, autofocus: true, decoration: InputDecoration(labelText: l.mfaCode), keyboardType: TextInputType.number, validator: (v) => (v == null || v.length != 6) ? l.invalidValue : null),
                  ],
                  if (_error != null) ...[const SizedBox(height: Space.md), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center)],
                  const SizedBox(height: Space.lg),
                  FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.signIn)),
                  if (widget.footer != null) ...[const SizedBox(height: Space.md), widget.footer!],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
