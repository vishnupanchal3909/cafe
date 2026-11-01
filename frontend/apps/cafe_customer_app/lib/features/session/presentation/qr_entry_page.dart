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
            return Scaffold(body: invalid ? EmptyState(icon: Icons.qr_code_2, message: c.l10n.qrInvalid) : ErrorState(failure: s.failure!, onRetry: () => c.read<SessionCubit>().scan(widget.token)));
          }
          return const Scaffold(body: SkeletonList());
        },
      );
}

class NoTablePage extends StatelessWidget {
  const NoTablePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: EmptyState(icon: Icons.qr_code_scanner, message: context.l10n.qrInvalid));
}
