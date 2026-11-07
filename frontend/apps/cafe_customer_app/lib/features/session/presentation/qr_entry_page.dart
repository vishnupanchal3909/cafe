import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'session_cubit.dart';

/// The whole no-install promise: a phone camera opens this, and the cafe, table and theme come from the token.
class QrEntryPage extends StatefulWidget {
  const QrEntryPage({super.key, required this.token});
  final String token;
  @override
  State<QrEntryPage> createState() => _QrEntryPageState();
}

class _QrEntryPageState extends State<QrEntryPage> {
  @override
  void initState() {
    super.initState();
    context.read<SessionCubit>().scan(widget.token);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<SessionCubit, SessionState>(
        listenWhen: (a, b) => a.context == null && b.context != null,
        listener: (c, s) => c.go('/menu'),
        builder: (c, s) {
          if (s.failure != null) {
            final invalid = s.failure!.status == 404;
            return Scaffold(body: invalid ? _Landing(icon: Icons.qr_code_2, message: c.l10n.qrInvalid) : ErrorState(failure: s.failure!, onRetry: () => c.read<SessionCubit>().scan(widget.token)));
          }
          return const Scaffold(body: _Landing(icon: Icons.qr_code_2, busy: true));
        },
      );
}

class NoTablePage extends StatelessWidget {
  const NoTablePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: _Landing(icon: Icons.qr_code_scanner, message: context.l10n.qrInvalid));
}

/// What a guest sees before the cafe is known: a lit badge over the platform's colours, with a message or a spinner.
class _Landing extends StatelessWidget {
  const _Landing({required this.icon, this.message, this.busy = false});
  final IconData icon;
  final String? message;
  final bool busy;
  @override
  Widget build(BuildContext context) => AuroraBackdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: FloatIn(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GlossyIcon(icon: icon, size: 96, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: Space.lg),
                if (busy) const SizedBox.square(dimension: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                if (message != null) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: Text(message!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
              ]),
            ),
          ),
        ),
      );
}
