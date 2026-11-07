/// Still owes money and not cancelled.
bool owes(Map<String, dynamic> r) => const ['unpaid', 'partially_paid'].contains(r['payment_status']) && r['status'] != 'cancelled';

/// Minutes an order has gone unpaid once past the cafe's alert time, or null while it is within it. Catches walk-outs.
int? unpaidMinutes(Map<String, dynamic> r, {required int alertMinutes, DateTime? now}) {
  final placed = r['placed_at'];
  if (!owes(r) || placed == null) return null;
  final minutes = (now ?? DateTime.now()).difference(DateTime.parse('$placed')).inMinutes;
  return minutes >= alertMinutes ? minutes : null;
}
