import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('mr'),
    Locale('pt'),
  ];

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection.'**
  String get networkError;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get invalidCredentials;

  /// No description provided for @accountLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get accountLocked;

  /// No description provided for @rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get rateLimited;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get invalidValue;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @serviceCharge.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get serviceCharge;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @welcomeTable.
  ///
  /// In en, this message translates to:
  /// **'Table {table}'**
  String welcomeTable(String table);

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get viewCart;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// No description provided for @chooseOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get chooseOption;

  /// No description provided for @extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get specialInstructions;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrder;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get orderPlaced;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(int number);

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @payAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Pay at the counter'**
  String get payAtCounter;

  /// No description provided for @onlinePaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online payment isn\'t available here yet. Please pay at the counter.'**
  String get onlinePaymentUnavailable;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment confirmation'**
  String get paymentPending;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateUs;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @thanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thanks;

  /// No description provided for @callWaiter.
  ///
  /// In en, this message translates to:
  /// **'Call waiter'**
  String get callWaiter;

  /// No description provided for @requestBill.
  ///
  /// In en, this message translates to:
  /// **'Request bill'**
  String get requestBill;

  /// No description provided for @callStaff.
  ///
  /// In en, this message translates to:
  /// **'Call staff'**
  String get callStaff;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Staff have been notified.'**
  String get requestSent;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favorites;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @recentlyOrdered.
  ///
  /// In en, this message translates to:
  /// **'Recently ordered'**
  String get recentlyOrdered;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon code'**
  String get coupon;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @couponInvalid.
  ///
  /// In en, this message translates to:
  /// **'This coupon can\'t be used'**
  String get couponInvalid;

  /// No description provided for @veg.
  ///
  /// In en, this message translates to:
  /// **'Veg'**
  String get veg;

  /// No description provided for @nonVeg.
  ///
  /// In en, this message translates to:
  /// **'Non-veg'**
  String get nonVeg;

  /// No description provided for @egg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get egg;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @qrInvalid.
  ///
  /// In en, this message translates to:
  /// **'This QR code is no longer valid. Please ask a member of staff.'**
  String get qrInvalid;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get noResults;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @statusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get statusPendingPayment;

  /// No description provided for @statusPlaced.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusPlaced;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusServed.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get statusServed;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @payUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get payUnpaid;

  /// No description provided for @payPartial.
  ///
  /// In en, this message translates to:
  /// **'Part paid'**
  String get payPartial;

  /// No description provided for @payPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payPaid;

  /// No description provided for @payPartRefund.
  ///
  /// In en, this message translates to:
  /// **'Part refunded'**
  String get payPartRefund;

  /// No description provided for @payRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get payRefunded;

  /// No description provided for @kitchenNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get kitchenNew;

  /// No description provided for @kitchenInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get kitchenInProgress;

  /// No description provided for @kitchenReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get kitchenReady;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @startPreparing.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPreparing;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get markReady;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @delayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @allStations.
  ///
  /// In en, this message translates to:
  /// **'All stations'**
  String get allStations;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No orders right now'**
  String get noTickets;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Reconnecting…'**
  String get connectionLost;

  /// No description provided for @takeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get takeaway;

  /// No description provided for @kitchenBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get kitchenBranch;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @menuManage.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuManage;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tables;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersCount;

  /// No description provided for @averageOrder.
  ///
  /// In en, this message translates to:
  /// **'Average order'**
  String get averageOrder;

  /// No description provided for @cancellationRate.
  ///
  /// In en, this message translates to:
  /// **'Cancellation rate'**
  String get cancellationRate;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProducts;

  /// No description provided for @peakHours.
  ///
  /// In en, this message translates to:
  /// **'Peak hours'**
  String get peakHours;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data for this period yet'**
  String get noDataYet;

  /// No description provided for @registerCafe.
  ///
  /// In en, this message translates to:
  /// **'Register your cafe'**
  String get registerCafe;

  /// No description provided for @cafeName.
  ///
  /// In en, this message translates to:
  /// **'Cafe name'**
  String get cafeName;

  /// No description provided for @legalName.
  ///
  /// In en, this message translates to:
  /// **'Legal business name'**
  String get legalName;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timezone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get ownerName;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your cafe is awaiting approval. You can set it up in the meantime.'**
  String get pendingApproval;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get newProduct;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @tableNumber.
  ///
  /// In en, this message translates to:
  /// **'Table number'**
  String get tableNumber;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCode;

  /// No description provided for @regenerateQr.
  ///
  /// In en, this message translates to:
  /// **'Regenerate QR'**
  String get regenerateQr;

  /// No description provided for @inviteStaff.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get inviteStaff;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get unitCost;

  /// No description provided for @stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get stockIn;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit and loss'**
  String get profitLoss;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @branding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get branding;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary colour'**
  String get primaryColor;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get percent;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptOrder;

  /// No description provided for @markServed.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get markServed;

  /// No description provided for @confirmCash.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash'**
  String get confirmCash;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get totalRevenue;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get totalExpenses;

  /// No description provided for @invitationLink.
  ///
  /// In en, this message translates to:
  /// **'Send this invitation token to your employee'**
  String get invitationLink;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get selectBranch;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get balance;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @partySize.
  ///
  /// In en, this message translates to:
  /// **'Party size'**
  String get partySize;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @cafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get cafes;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit logs'**
  String get auditLogs;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'System health'**
  String get health;

  /// No description provided for @totalCafes.
  ///
  /// In en, this message translates to:
  /// **'Total cafes'**
  String get totalCafes;

  /// No description provided for @activeCafes.
  ///
  /// In en, this message translates to:
  /// **'Active cafes'**
  String get activeCafes;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get totalCustomers;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get totalOrders;

  /// No description provided for @enrollMfa.
  ///
  /// In en, this message translates to:
  /// **'Set up two-factor sign-in'**
  String get enrollMfa;

  /// No description provided for @mfaCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get mfaCode;

  /// No description provided for @mfaSecret.
  ///
  /// In en, this message translates to:
  /// **'Add this key to your authenticator app'**
  String get mfaSecret;

  /// No description provided for @grossByCurrency.
  ///
  /// In en, this message translates to:
  /// **'Gross sales by currency'**
  String get grossByCurrency;

  /// No description provided for @cafesByCountry.
  ///
  /// In en, this message translates to:
  /// **'Cafes by country'**
  String get cafesByCountry;

  /// No description provided for @activeSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Active subscriptions'**
  String get activeSubscriptions;

  /// No description provided for @reasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Give a reason. This is recorded in the audit log.'**
  String get reasonPrompt;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @pendingCafes.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingCafes;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @stActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stActive;

  /// No description provided for @stInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get stInactive;

  /// No description provided for @stAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get stAvailable;

  /// No description provided for @stOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get stOccupied;

  /// No description provided for @stReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get stReserved;

  /// No description provided for @stCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get stCleaning;

  /// No description provided for @stSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get stSuspended;

  /// No description provided for @stRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get stRejected;

  /// No description provided for @stClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get stClosed;

  /// No description provided for @stOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get stOpen;

  /// No description provided for @stResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get stResolved;

  /// No description provided for @stInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get stInProgress;

  /// No description provided for @stInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get stInvited;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get roleCashier;

  /// No description provided for @roleWaiter.
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get roleWaiter;

  /// No description provided for @roleKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen staff'**
  String get roleKitchen;

  /// No description provided for @setPricesIncludeTax.
  ///
  /// In en, this message translates to:
  /// **'Prices include tax'**
  String get setPricesIncludeTax;

  /// No description provided for @setRequireAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Staff accept orders first'**
  String get setRequireAcceptance;

  /// No description provided for @setGuestOrdering.
  ///
  /// In en, this message translates to:
  /// **'Allow QR guest ordering'**
  String get setGuestOrdering;

  /// No description provided for @setStockDeduction.
  ///
  /// In en, this message translates to:
  /// **'Deduct stock from recipes'**
  String get setStockDeduction;

  /// No description provided for @setPaymentPolicy.
  ///
  /// In en, this message translates to:
  /// **'When guests pay'**
  String get setPaymentPolicy;

  /// No description provided for @policyPrepay.
  ///
  /// In en, this message translates to:
  /// **'Pay before preparation'**
  String get policyPrepay;

  /// No description provided for @policyPostpay.
  ///
  /// In en, this message translates to:
  /// **'Pay after the meal'**
  String get policyPostpay;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get layoutGrid;

  /// No description provided for @layoutCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get layoutCompact;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get periodYearly;

  /// No description provided for @healthCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get healthCache;

  /// No description provided for @healthEvents.
  ///
  /// In en, this message translates to:
  /// **'Events waiting'**
  String get healthEvents;

  /// No description provided for @healthWebhooks.
  ///
  /// In en, this message translates to:
  /// **'Failed webhooks'**
  String get healthWebhooks;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notAvailable;

  /// No description provided for @plusTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes are calculated when you place the order'**
  String get plusTaxes;

  /// No description provided for @variants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get variants;

  /// No description provided for @addVariant.
  ///
  /// In en, this message translates to:
  /// **'Add variant'**
  String get addVariant;

  /// No description provided for @addExtras.
  ///
  /// In en, this message translates to:
  /// **'Add extras'**
  String get addExtras;

  /// No description provided for @optionName.
  ///
  /// In en, this message translates to:
  /// **'Option name'**
  String get optionName;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload logo'**
  String get uploadLogo;

  /// No description provided for @uploadCover.
  ///
  /// In en, this message translates to:
  /// **'Upload cover'**
  String get uploadCover;

  /// No description provided for @banners.
  ///
  /// In en, this message translates to:
  /// **'Banners'**
  String get banners;

  /// No description provided for @bannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Banner title'**
  String get bannerTitle;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add branch'**
  String get addBranch;

  /// No description provided for @branchCode.
  ///
  /// In en, this message translates to:
  /// **'Branch code'**
  String get branchCode;

  /// No description provided for @businessHours.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get businessHours;

  /// No description provided for @opensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get opensAt;

  /// No description provided for @closesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closesAt;

  /// No description provided for @supportedLanguages.
  ///
  /// In en, this message translates to:
  /// **'Customer languages'**
  String get supportedLanguages;

  /// No description provided for @gatewaySetup.
  ///
  /// In en, this message translates to:
  /// **'Payment gateway'**
  String get gatewaySetup;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get environment;

  /// No description provided for @apiKeyId.
  ///
  /// In en, this message translates to:
  /// **'API key ID'**
  String get apiKeyId;

  /// No description provided for @apiKeySecret.
  ///
  /// In en, this message translates to:
  /// **'API secret'**
  String get apiKeySecret;

  /// No description provided for @webhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Webhook secret'**
  String get webhookSecret;

  /// No description provided for @webhookUrl.
  ///
  /// In en, this message translates to:
  /// **'Webhook URL (add this in your gateway)'**
  String get webhookUrl;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get choosePlan;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @splitBill.
  ///
  /// In en, this message translates to:
  /// **'Split bill'**
  String get splitBill;

  /// No description provided for @numberOfParts.
  ///
  /// In en, this message translates to:
  /// **'Number of parts'**
  String get numberOfParts;

  /// No description provided for @transferTable.
  ///
  /// In en, this message translates to:
  /// **'Move to table'**
  String get transferTable;

  /// No description provided for @recipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipe;

  /// No description provided for @purchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Purchase orders'**
  String get purchaseOrders;

  /// No description provided for @newPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'New purchase order'**
  String get newPurchaseOrder;

  /// No description provided for @receiveGoods.
  ///
  /// In en, this message translates to:
  /// **'Receive goods'**
  String get receiveGoods;

  /// No description provided for @supplierInvoices.
  ///
  /// In en, this message translates to:
  /// **'Supplier invoices'**
  String get supplierInvoices;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceNumber;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @expiringStock.
  ///
  /// In en, this message translates to:
  /// **'Expiring stock'**
  String get expiringStock;

  /// No description provided for @trialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial balance'**
  String get trialBalance;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @balanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance sheet'**
  String get balanceSheet;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @liabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get liabilities;

  /// No description provided for @equity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get equity;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @reverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get reverse;

  /// No description provided for @periods.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get periods;

  /// No description provided for @closePeriod.
  ///
  /// In en, this message translates to:
  /// **'Close period'**
  String get closePeriod;

  /// No description provided for @cashRegisters.
  ///
  /// In en, this message translates to:
  /// **'Cash registers'**
  String get cashRegisters;

  /// No description provided for @openRegister.
  ///
  /// In en, this message translates to:
  /// **'Open register'**
  String get openRegister;

  /// No description provided for @closeRegister.
  ///
  /// In en, this message translates to:
  /// **'Close register'**
  String get closeRegister;

  /// No description provided for @openingFloat.
  ///
  /// In en, this message translates to:
  /// **'Opening float'**
  String get openingFloat;

  /// No description provided for @countedCash.
  ///
  /// In en, this message translates to:
  /// **'Counted cash'**
  String get countedCash;

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected cash'**
  String get expectedCash;

  /// No description provided for @variance.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get variance;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @grossPay.
  ///
  /// In en, this message translates to:
  /// **'Gross pay'**
  String get grossPay;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductions;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get clockOut;

  /// No description provided for @clockedIn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get clockedIn;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @loyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyalty;

  /// No description provided for @pointsPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Points per currency unit'**
  String get pointsPerUnit;

  /// No description provided for @valuePerPoint.
  ///
  /// In en, this message translates to:
  /// **'Value of one point'**
  String get valuePerPoint;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @stations.
  ///
  /// In en, this message translates to:
  /// **'Kitchen stations'**
  String get stations;

  /// No description provided for @routeToStation.
  ///
  /// In en, this message translates to:
  /// **'Send to station'**
  String get routeToStation;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @translations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get translations;

  /// No description provided for @translationKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get translationKey;

  /// No description provided for @translationValue.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get translationValue;

  /// No description provided for @countries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get countries;

  /// No description provided for @commissions.
  ///
  /// In en, this message translates to:
  /// **'Commissions'**
  String get commissions;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @bodyText.
  ///
  /// In en, this message translates to:
  /// **'Message text'**
  String get bodyText;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get addresses;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabel;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed orders'**
  String get completedOrders;

  /// No description provided for @chooseCafe.
  ///
  /// In en, this message translates to:
  /// **'Choose a cafe'**
  String get chooseCafe;

  /// No description provided for @reserveTable.
  ///
  /// In en, this message translates to:
  /// **'Reserve a table'**
  String get reserveTable;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @refunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refunds;

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @syncSettlements.
  ///
  /// In en, this message translates to:
  /// **'Fetch settlements'**
  String get syncSettlements;

  /// No description provided for @paymentLink.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get paymentLink;

  /// No description provided for @createPaymentLink.
  ///
  /// In en, this message translates to:
  /// **'Create payment link'**
  String get createPaymentLink;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @connectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connected. Online payments are on.'**
  String get connectionOk;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'The gateway refused these keys.'**
  String get connectionFailed;

  /// No description provided for @payPart.
  ///
  /// In en, this message translates to:
  /// **'Pay part of the bill'**
  String get payPart;

  /// No description provided for @amountToPay.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get amountToPay;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Thank you!'**
  String get paymentSuccessful;

  /// No description provided for @paymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'The payment wasn\'t completed. You have not been charged for this attempt.'**
  String get paymentNotCompleted;

  /// No description provided for @payOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay online'**
  String get payOnline;

  /// No description provided for @gatewayFee.
  ///
  /// In en, this message translates to:
  /// **'Gateway fee'**
  String get gatewayFee;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get referenceLabel;

  /// No description provided for @paymentBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get paymentBreakdown;

  /// No description provided for @approveRefund.
  ///
  /// In en, this message translates to:
  /// **'Approve refund'**
  String get approveRefund;

  /// No description provided for @refundRequested.
  ///
  /// In en, this message translates to:
  /// **'Refund requested. A manager needs to approve it.'**
  String get refundRequested;

  /// No description provided for @reconciled.
  ///
  /// In en, this message translates to:
  /// **'Reconciled'**
  String get reconciled;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get needsReview;

  /// No description provided for @pendingKeys.
  ///
  /// In en, this message translates to:
  /// **'Saved. Now test the connection to switch online payments on.'**
  String get pendingKeys;

  /// No description provided for @openingCheckout.
  ///
  /// In en, this message translates to:
  /// **'Opening secure checkout…'**
  String get openingCheckout;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @revenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue by day'**
  String get revenueTrend;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent orders'**
  String get recentOrders;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Run your cafe beautifully, from one place.'**
  String get loginTagline;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInSubtitle;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Platform console'**
  String get adminConsole;

  /// No description provided for @adminLoginTagline.
  ///
  /// In en, this message translates to:
  /// **'Every cafe on the platform, at a glance.'**
  String get adminLoginTagline;

  /// No description provided for @kitchenDisplay.
  ///
  /// In en, this message translates to:
  /// **'Kitchen display'**
  String get kitchenDisplay;

  /// No description provided for @kitchenLoginTagline.
  ///
  /// In en, this message translates to:
  /// **'Every ticket, clear from across the kitchen.'**
  String get kitchenLoginTagline;

  /// No description provided for @customerLoginTagline.
  ///
  /// In en, this message translates to:
  /// **'Save favourites, track orders and earn rewards.'**
  String get customerLoginTagline;

  /// No description provided for @signInToOrder.
  ///
  /// In en, this message translates to:
  /// **'Sign in to order'**
  String get signInToOrder;

  /// No description provided for @signInToOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Browse as much as you like. To place an order, sign in or create an account.'**
  String get signInToOrderHint;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @markAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark available'**
  String get markAvailable;

  /// No description provided for @tableReleased.
  ///
  /// In en, this message translates to:
  /// **'Table is now available'**
  String get tableReleased;

  /// No description provided for @tableHasUnpaid.
  ///
  /// In en, this message translates to:
  /// **'This table still has unpaid orders. Settle the bill first.'**
  String get tableHasUnpaid;

  /// No description provided for @unpaidForMinutes.
  ///
  /// In en, this message translates to:
  /// **'Unpaid for {minutes} min'**
  String unpaidForMinutes(int minutes);

  /// No description provided for @tablePin.
  ///
  /// In en, this message translates to:
  /// **'PIN {pin}'**
  String tablePin(String pin);

  /// No description provided for @enterTablePin.
  ///
  /// In en, this message translates to:
  /// **'Enter the table PIN'**
  String get enterTablePin;

  /// No description provided for @tablePinHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the staff for the 4-digit PIN for your table.'**
  String get tablePinHint;

  /// No description provided for @tablePinWrong.
  ///
  /// In en, this message translates to:
  /// **'That PIN doesn\'t match. Please check with the staff.'**
  String get tablePinWrong;

  /// No description provided for @setTablePin.
  ///
  /// In en, this message translates to:
  /// **'Ask guests for a table PIN before ordering'**
  String get setTablePin;

  /// No description provided for @setSessionEndAfterPayment.
  ///
  /// In en, this message translates to:
  /// **'End the guests\' table session this long after they pay'**
  String get setSessionEndAfterPayment;

  /// No description provided for @setUnpaidAlert.
  ///
  /// In en, this message translates to:
  /// **'Warn staff about orders still unpaid after'**
  String get setUnpaidAlert;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. You can sign in now.'**
  String get passwordResetDone;

  /// No description provided for @resetLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'This reset link has expired or was already used.'**
  String get resetLinkInvalid;

  /// No description provided for @passwordResetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password reset isn\'t available yet.'**
  String get passwordResetUnavailable;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If that email has an account, a reset link is on its way.'**
  String get resetLinkSent;

  /// No description provided for @countsForDay.
  ///
  /// In en, this message translates to:
  /// **'counts for {date}'**
  String countsForDay(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'mr',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'mr':
      return AppLocalizationsMr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
