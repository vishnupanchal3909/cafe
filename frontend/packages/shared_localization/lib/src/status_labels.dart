import 'generated/app_localizations.dart';

/// Status values are technical and never translated in the data. This is the only place they become words.
extension StatusLabels on AppLocalizations {
  String orderStatus(String status) => switch (status) {
        'pending_payment' => statusPendingPayment,
        'placed' => statusPlaced,
        'accepted' => statusAccepted,
        'preparing' => statusPreparing,
        'ready' => statusReady,
        'served' => statusServed,
        'completed' => statusCompleted,
        'cancelled' => statusCancelled,
        _ => status,
      };

  String paymentStatus(String status) => switch (status) {
        'unpaid' => payUnpaid,
        'partially_paid' => payPartial,
        'paid' => payPaid,
        'partially_refunded' => payPartRefund,
        'refunded' => payRefunded,
        _ => status,
      };

  String dietary(String value) => switch (value) {
        'veg' => veg,
        'non_veg' => nonVeg,
        'egg' => egg,
        'vegan' => vegan,
        _ => '',
      };

  /// Generic record states. An unknown value is shown as is, so a new backend state never blanks a screen.
  String statusLabel(String s) => switch (s) {
        'active' => stActive,
        'inactive' => stInactive,
        'available' => stAvailable,
        'occupied' => stOccupied,
        'reserved' => stReserved,
        'cleaning' => stCleaning,
        'suspended' => stSuspended,
        'rejected' => stRejected,
        'closed' => stClosed,
        'open' => stOpen,
        'resolved' => stResolved,
        'in_progress' => stInProgress,
        'invited' => stInvited,
        'requested' => stOpen,
        'pending_approval' => pendingCafes,
        _ => orderStatus(s),
      };

  /// Error codes come from the API. Screens prefer a specific phrase and fall back to the server's message.
  String failureMessage(String code, String serverMessage) => switch (code) {
        'NETWORK' => networkError,
        'INVALID_CREDENTIALS' => invalidCredentials,
        'ACCOUNT_LOCKED' => accountLocked,
        'RATE_LIMITED' => rateLimited,
        'CUSTOMER_LOGIN_REQUIRED' => signInToOrder,
        'SESSION_HAS_UNPAID_ORDERS' => tableHasUnpaid,
        'TABLE_PIN_REQUIRED' => enterTablePin,
        'TABLE_PIN_WRONG' => tablePinWrong,
        'RESET_LINK_INVALID' => resetLinkInvalid,
        'PASSWORD_RESET_UNAVAILABLE' => passwordResetUnavailable,
        _ => serverMessage.isNotEmpty ? serverMessage : errorTitle,
      };
}
