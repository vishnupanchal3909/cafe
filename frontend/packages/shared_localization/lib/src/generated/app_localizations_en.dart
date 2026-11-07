// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get networkError => 'Can\'t reach the server. Check your connection.';

  @override
  String get invalidCredentials => 'Incorrect email or password.';

  @override
  String get accountLocked => 'Too many attempts. Try again later.';

  @override
  String get rateLimited => 'Too many requests. Please wait a moment.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get language => 'Language';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidValue => 'Invalid value';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get tax => 'Tax';

  @override
  String get serviceCharge => 'Service charge';

  @override
  String get status => 'Status';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Amount';

  @override
  String get quantity => 'Quantity';

  @override
  String get notes => 'Notes';

  @override
  String get reason => 'Reason';

  @override
  String get refresh => 'Refresh';

  @override
  String welcomeTable(String table) {
    return 'Table $table';
  }

  @override
  String get menu => 'Menu';

  @override
  String get cart => 'Cart';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get viewCart => 'View cart';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get chooseOption => 'Choose an option';

  @override
  String get extras => 'Extras';

  @override
  String get specialInstructions => 'Special instructions';

  @override
  String get placeOrder => 'Place order';

  @override
  String get orderPlaced => 'Order placed';

  @override
  String orderNumber(int number) {
    return 'Order #$number';
  }

  @override
  String get trackOrder => 'Track order';

  @override
  String get payNow => 'Pay now';

  @override
  String get payAtCounter => 'Pay at the counter';

  @override
  String get onlinePaymentUnavailable =>
      'Online payment isn\'t available here yet. Please pay at the counter.';

  @override
  String get paymentPending => 'Waiting for payment confirmation';

  @override
  String get receipt => 'Receipt';

  @override
  String get rateUs => 'Rate your experience';

  @override
  String get submit => 'Submit';

  @override
  String get thanks => 'Thank you!';

  @override
  String get callWaiter => 'Call waiter';

  @override
  String get requestBill => 'Request bill';

  @override
  String get callStaff => 'Call staff';

  @override
  String get requestSent => 'Request sent. Staff have been notified.';

  @override
  String get favorites => 'Favourites';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get recentlyOrdered => 'Recently ordered';

  @override
  String get coupon => 'Coupon code';

  @override
  String get apply => 'Apply';

  @override
  String get couponInvalid => 'This coupon can\'t be used';

  @override
  String get veg => 'Veg';

  @override
  String get nonVeg => 'Non-veg';

  @override
  String get egg => 'Egg';

  @override
  String get vegan => 'Vegan';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get myOrders => 'My orders';

  @override
  String get profile => 'Profile';

  @override
  String get createAccount => 'Create account';

  @override
  String get offers => 'Offers';

  @override
  String get qrInvalid =>
      'This QR code is no longer valid. Please ask a member of staff.';

  @override
  String get noResults => 'No matching items';

  @override
  String get allCategories => 'All';

  @override
  String get statusPendingPayment => 'Awaiting payment';

  @override
  String get statusPlaced => 'New';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusServed => 'Served';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get payUnpaid => 'Unpaid';

  @override
  String get payPartial => 'Part paid';

  @override
  String get payPaid => 'Paid';

  @override
  String get payPartRefund => 'Part refunded';

  @override
  String get payRefunded => 'Refunded';

  @override
  String get kitchenNew => 'New';

  @override
  String get kitchenInProgress => 'In progress';

  @override
  String get kitchenReady => 'Ready';

  @override
  String get accept => 'Accept';

  @override
  String get startPreparing => 'Start';

  @override
  String get markReady => 'Ready';

  @override
  String get complete => 'Complete';

  @override
  String get delayed => 'Delayed';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get priority => 'Priority';

  @override
  String get allStations => 'All stations';

  @override
  String get noTickets => 'No orders right now';

  @override
  String get connectionLost => 'Connection lost. Reconnecting…';

  @override
  String get takeaway => 'Takeaway';

  @override
  String get kitchenBranch => 'Branch';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get orders => 'Orders';

  @override
  String get menuManage => 'Menu';

  @override
  String get tables => 'Tables';

  @override
  String get staff => 'Staff';

  @override
  String get inventory => 'Inventory';

  @override
  String get finance => 'Finance';

  @override
  String get marketing => 'Marketing';

  @override
  String get settings => 'Settings';

  @override
  String get revenue => 'Revenue';

  @override
  String get ordersCount => 'Orders';

  @override
  String get averageOrder => 'Average order';

  @override
  String get cancellationRate => 'Cancellation rate';

  @override
  String get topProducts => 'Top products';

  @override
  String get peakHours => 'Peak hours';

  @override
  String get noDataYet => 'No data for this period yet';

  @override
  String get registerCafe => 'Register your cafe';

  @override
  String get cafeName => 'Cafe name';

  @override
  String get legalName => 'Legal business name';

  @override
  String get country => 'Country';

  @override
  String get currency => 'Currency';

  @override
  String get timezone => 'Time zone';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get ownerName => 'Your name';

  @override
  String get pendingApproval =>
      'Your cafe is awaiting approval. You can set it up in the meantime.';

  @override
  String get categories => 'Categories';

  @override
  String get products => 'Products';

  @override
  String get newCategory => 'New category';

  @override
  String get newProduct => 'New product';

  @override
  String get price => 'Price';

  @override
  String get category => 'Category';

  @override
  String get tableNumber => 'Table number';

  @override
  String get capacity => 'Capacity';

  @override
  String get qrCode => 'QR code';

  @override
  String get regenerateQr => 'Regenerate QR';

  @override
  String get inviteStaff => 'Invite staff';

  @override
  String get role => 'Role';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get stock => 'Stock';

  @override
  String get unit => 'Unit';

  @override
  String get unitCost => 'Unit cost';

  @override
  String get stockIn => 'Stock in';

  @override
  String get expenses => 'Expenses';

  @override
  String get sales => 'Sales';

  @override
  String get profitLoss => 'Profit and loss';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get branding => 'Branding';

  @override
  String get primaryColor => 'Primary colour';

  @override
  String get coupons => 'Coupons';

  @override
  String get code => 'Code';

  @override
  String get percent => 'Percent';

  @override
  String get acceptOrder => 'Accept';

  @override
  String get markServed => 'Served';

  @override
  String get confirmCash => 'Confirm cash';

  @override
  String get refund => 'Refund';

  @override
  String get netProfit => 'Net profit';

  @override
  String get totalRevenue => 'Total revenue';

  @override
  String get totalExpenses => 'Total expenses';

  @override
  String get invitationLink => 'Send this invitation token to your employee';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get selectBranch => 'Select branch';

  @override
  String get balance => 'Balance due';

  @override
  String get customers => 'Customers';

  @override
  String get reservations => 'Reservations';

  @override
  String get partySize => 'Party size';

  @override
  String get support => 'Support';

  @override
  String get subject => 'Subject';

  @override
  String get message => 'Message';

  @override
  String get cafes => 'Cafes';

  @override
  String get approve => 'Approve';

  @override
  String get suspend => 'Suspend';

  @override
  String get activate => 'Activate';

  @override
  String get plans => 'Plans';

  @override
  String get auditLogs => 'Audit logs';

  @override
  String get health => 'System health';

  @override
  String get totalCafes => 'Total cafes';

  @override
  String get activeCafes => 'Active cafes';

  @override
  String get totalCustomers => 'Customers';

  @override
  String get totalOrders => 'Total orders';

  @override
  String get enrollMfa => 'Set up two-factor sign-in';

  @override
  String get mfaCode => '6-digit code';

  @override
  String get mfaSecret => 'Add this key to your authenticator app';

  @override
  String get grossByCurrency => 'Gross sales by currency';

  @override
  String get cafesByCountry => 'Cafes by country';

  @override
  String get activeSubscriptions => 'Active subscriptions';

  @override
  String get reasonPrompt =>
      'Give a reason. This is recorded in the audit log.';

  @override
  String get action => 'Action';

  @override
  String get database => 'Database';

  @override
  String get pendingCafes => 'Pending approval';

  @override
  String get owner => 'Owner';

  @override
  String get stActive => 'Active';

  @override
  String get stInactive => 'Inactive';

  @override
  String get stAvailable => 'Available';

  @override
  String get stOccupied => 'Occupied';

  @override
  String get stReserved => 'Reserved';

  @override
  String get stCleaning => 'Cleaning';

  @override
  String get stSuspended => 'Suspended';

  @override
  String get stRejected => 'Rejected';

  @override
  String get stClosed => 'Closed';

  @override
  String get stOpen => 'Open';

  @override
  String get stResolved => 'Resolved';

  @override
  String get stInProgress => 'In progress';

  @override
  String get stInvited => 'Invited';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get roleWaiter => 'Waiter';

  @override
  String get roleKitchen => 'Kitchen staff';

  @override
  String get setPricesIncludeTax => 'Prices include tax';

  @override
  String get setRequireAcceptance => 'Staff accept orders first';

  @override
  String get setGuestOrdering => 'Allow QR guest ordering';

  @override
  String get setStockDeduction => 'Deduct stock from recipes';

  @override
  String get setPaymentPolicy => 'When guests pay';

  @override
  String get policyPrepay => 'Pay before preparation';

  @override
  String get policyPostpay => 'Pay after the meal';

  @override
  String get layoutList => 'List';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get layoutCompact => 'Compact';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodYearly => 'Yearly';

  @override
  String get healthCache => 'Cache';

  @override
  String get healthEvents => 'Events waiting';

  @override
  String get healthWebhooks => 'Failed webhooks';

  @override
  String get phone => 'Phone';

  @override
  String get notAvailable => 'Not applicable';

  @override
  String get plusTaxes => 'Taxes are calculated when you place the order';

  @override
  String get variants => 'Variants';

  @override
  String get addVariant => 'Add variant';

  @override
  String get addExtras => 'Add extras';

  @override
  String get optionName => 'Option name';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get uploadLogo => 'Upload logo';

  @override
  String get uploadCover => 'Upload cover';

  @override
  String get banners => 'Banners';

  @override
  String get bannerTitle => 'Banner title';

  @override
  String get branches => 'Branches';

  @override
  String get addBranch => 'Add branch';

  @override
  String get branchCode => 'Branch code';

  @override
  String get businessHours => 'Business hours';

  @override
  String get opensAt => 'Opens';

  @override
  String get closesAt => 'Closes';

  @override
  String get supportedLanguages => 'Customer languages';

  @override
  String get gatewaySetup => 'Payment gateway';

  @override
  String get provider => 'Provider';

  @override
  String get environment => 'Mode';

  @override
  String get apiKeyId => 'API key ID';

  @override
  String get apiKeySecret => 'API secret';

  @override
  String get webhookSecret => 'Webhook secret';

  @override
  String get webhookUrl => 'Webhook URL (add this in your gateway)';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get subscription => 'Subscription';

  @override
  String get choosePlan => 'Choose a plan';

  @override
  String get cancelSubscription => 'Cancel subscription';

  @override
  String get splitBill => 'Split bill';

  @override
  String get numberOfParts => 'Number of parts';

  @override
  String get transferTable => 'Move to table';

  @override
  String get recipe => 'Recipe';

  @override
  String get purchaseOrders => 'Purchase orders';

  @override
  String get newPurchaseOrder => 'New purchase order';

  @override
  String get receiveGoods => 'Receive goods';

  @override
  String get supplierInvoices => 'Supplier invoices';

  @override
  String get invoiceNumber => 'Invoice number';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get expiringStock => 'Expiring stock';

  @override
  String get trialBalance => 'Trial balance';

  @override
  String get debit => 'Debit';

  @override
  String get credit => 'Credit';

  @override
  String get balanceSheet => 'Balance sheet';

  @override
  String get assets => 'Assets';

  @override
  String get liabilities => 'Liabilities';

  @override
  String get equity => 'Equity';

  @override
  String get journal => 'Journal';

  @override
  String get reverse => 'Reverse';

  @override
  String get periods => 'Periods';

  @override
  String get closePeriod => 'Close period';

  @override
  String get cashRegisters => 'Cash registers';

  @override
  String get openRegister => 'Open register';

  @override
  String get closeRegister => 'Close register';

  @override
  String get openingFloat => 'Opening float';

  @override
  String get countedCash => 'Counted cash';

  @override
  String get expectedCash => 'Expected cash';

  @override
  String get variance => 'Difference';

  @override
  String get payroll => 'Payroll';

  @override
  String get grossPay => 'Gross pay';

  @override
  String get deductions => 'Deductions';

  @override
  String get markPaid => 'Mark paid';

  @override
  String get attendance => 'Attendance';

  @override
  String get clockIn => 'Clock in';

  @override
  String get clockOut => 'Clock out';

  @override
  String get clockedIn => 'Done';

  @override
  String get promotions => 'Promotions';

  @override
  String get loyalty => 'Loyalty';

  @override
  String get pointsPerUnit => 'Points per currency unit';

  @override
  String get valuePerPoint => 'Value of one point';

  @override
  String get reply => 'Reply';

  @override
  String get notifications => 'Notifications';

  @override
  String get stations => 'Kitchen stations';

  @override
  String get routeToStation => 'Send to station';

  @override
  String get users => 'Users';

  @override
  String get disable => 'Disable';

  @override
  String get translations => 'Translations';

  @override
  String get translationKey => 'Key';

  @override
  String get translationValue => 'Text';

  @override
  String get countries => 'Countries';

  @override
  String get commissions => 'Commissions';

  @override
  String get announcements => 'Announcements';

  @override
  String get bodyText => 'Message text';

  @override
  String get addresses => 'Saved addresses';

  @override
  String get addressLabel => 'Label';

  @override
  String get completedOrders => 'Completed orders';

  @override
  String get chooseCafe => 'Choose a cafe';

  @override
  String get reserveTable => 'Reserve a table';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get payments => 'Payments';

  @override
  String get refunds => 'Refunds';

  @override
  String get settlements => 'Settlements';

  @override
  String get syncSettlements => 'Fetch settlements';

  @override
  String get paymentLink => 'Payment link';

  @override
  String get createPaymentLink => 'Create payment link';

  @override
  String get testConnection => 'Test connection';

  @override
  String get connectionOk => 'Connected. Online payments are on.';

  @override
  String get connectionFailed => 'The gateway refused these keys.';

  @override
  String get payPart => 'Pay part of the bill';

  @override
  String get amountToPay => 'Amount to pay';

  @override
  String get paymentSuccessful => 'Payment received. Thank you!';

  @override
  String get paymentNotCompleted =>
      'The payment wasn\'t completed. You have not been charged for this attempt.';

  @override
  String get payOnline => 'Pay online';

  @override
  String get gatewayFee => 'Gateway fee';

  @override
  String get referenceLabel => 'Reference';

  @override
  String get paymentBreakdown => 'Payment summary';

  @override
  String get approveRefund => 'Approve refund';

  @override
  String get refundRequested =>
      'Refund requested. A manager needs to approve it.';

  @override
  String get reconciled => 'Reconciled';

  @override
  String get needsReview => 'Needs review';

  @override
  String get pendingKeys =>
      'Saved. Now test the connection to switch online payments on.';

  @override
  String get openingCheckout => 'Opening secure checkout…';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get thisMonth => 'This month';

  @override
  String get revenueTrend => 'Revenue by day';

  @override
  String get recentOrders => 'Recent orders';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get filterAll => 'All';

  @override
  String get available => 'Available';

  @override
  String get loginTagline => 'Run your cafe beautifully, from one place.';

  @override
  String get signInSubtitle => 'Sign in to continue';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get back => 'Back';

  @override
  String get adminConsole => 'Platform console';

  @override
  String get adminLoginTagline => 'Every cafe on the platform, at a glance.';

  @override
  String get kitchenDisplay => 'Kitchen display';

  @override
  String get kitchenLoginTagline =>
      'Every ticket, clear from across the kitchen.';

  @override
  String get customerLoginTagline =>
      'Save favourites, track orders and earn rewards.';

  @override
  String get signInToOrder => 'Sign in to order';

  @override
  String get signInToOrderHint =>
      'Browse as much as you like. To place an order, sign in or create an account.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get markAvailable => 'Mark available';

  @override
  String get tableReleased => 'Table is now available';

  @override
  String get tableHasUnpaid =>
      'This table still has unpaid orders. Settle the bill first.';

  @override
  String unpaidForMinutes(int minutes) {
    return 'Unpaid for $minutes min';
  }

  @override
  String tablePin(String pin) {
    return 'PIN $pin';
  }

  @override
  String get enterTablePin => 'Enter the table PIN';

  @override
  String get tablePinHint =>
      'Ask the staff for the 4-digit PIN for your table.';

  @override
  String get tablePinWrong =>
      'That PIN doesn\'t match. Please check with the staff.';

  @override
  String get setTablePin => 'Ask guests for a table PIN before ordering';

  @override
  String get setSessionEndAfterPayment =>
      'End the guests\' table session this long after they pay';

  @override
  String get setUnpaidAlert => 'Warn staff about orders still unpaid after';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Set a new password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordResetDone => 'Password changed. You can sign in now.';

  @override
  String get resetLinkInvalid =>
      'This reset link has expired or was already used.';

  @override
  String get passwordResetUnavailable => 'Password reset isn\'t available yet.';

  @override
  String get minutesUnit => 'min';

  @override
  String get resetLinkSent =>
      'If that email has an account, a reset link is on its way.';

  @override
  String countsForDay(String date) {
    return 'counts for $date';
  }
}
