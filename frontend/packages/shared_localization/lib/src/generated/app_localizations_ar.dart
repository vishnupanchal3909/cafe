// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get add => 'إضافة';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get search => 'بحث';

  @override
  String get close => 'إغلاق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get emptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get errorTitle => 'حدث خطأ ما';

  @override
  String get networkError => 'تعذر الوصول إلى الخادم. تحقق من اتصالك.';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get accountLocked => 'محاولات كثيرة جدًا. حاول لاحقًا.';

  @override
  String get rateLimited => 'طلبات كثيرة جدًا. يرجى الانتظار قليلًا.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get name => 'الاسم';

  @override
  String get language => 'اللغة';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get invalidValue => 'قيمة غير صالحة';

  @override
  String get total => 'الإجمالي';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get discount => 'الخصم';

  @override
  String get tax => 'الضريبة';

  @override
  String get serviceCharge => 'رسوم الخدمة';

  @override
  String get status => 'الحالة';

  @override
  String get date => 'التاريخ';

  @override
  String get amount => 'المبلغ';

  @override
  String get quantity => 'الكمية';

  @override
  String get notes => 'ملاحظات';

  @override
  String get reason => 'السبب';

  @override
  String get refresh => 'تحديث';

  @override
  String welcomeTable(String table) {
    return 'طاولة $table';
  }

  @override
  String get menu => 'القائمة';

  @override
  String get cart => 'السلة';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get emptyCart => 'سلتك فارغة';

  @override
  String get chooseOption => 'اختر خيارًا';

  @override
  String get extras => 'إضافات';

  @override
  String get specialInstructions => 'تعليمات خاصة';

  @override
  String get placeOrder => 'إرسال الطلب';

  @override
  String get orderPlaced => 'تم إرسال الطلب';

  @override
  String orderNumber(int number) {
    return 'الطلب رقم $number';
  }

  @override
  String get trackOrder => 'تتبع الطلب';

  @override
  String get payNow => 'ادفع الآن';

  @override
  String get payAtCounter => 'الدفع عند الكاشير';

  @override
  String get onlinePaymentUnavailable =>
      'الدفع عبر الإنترنت غير متاح هنا بعد. يرجى الدفع عند الكاشير.';

  @override
  String get paymentPending => 'في انتظار تأكيد الدفع';

  @override
  String get receipt => 'الإيصال';

  @override
  String get rateUs => 'قيّم تجربتك';

  @override
  String get submit => 'إرسال';

  @override
  String get thanks => 'شكرًا لك!';

  @override
  String get callWaiter => 'استدعاء النادل';

  @override
  String get requestBill => 'طلب الفاتورة';

  @override
  String get callStaff => 'استدعاء الموظفين';

  @override
  String get requestSent => 'تم إرسال الطلب وإبلاغ الموظفين.';

  @override
  String get favorites => 'المفضلة';

  @override
  String get wishlist => 'قائمة الرغبات';

  @override
  String get recentlyOrdered => 'طلبات حديثة';

  @override
  String get coupon => 'رمز القسيمة';

  @override
  String get apply => 'تطبيق';

  @override
  String get couponInvalid => 'لا يمكن استخدام هذه القسيمة';

  @override
  String get veg => 'نباتي';

  @override
  String get nonVeg => 'غير نباتي';

  @override
  String get egg => 'بيض';

  @override
  String get vegan => 'نباتي صرف';

  @override
  String get outOfStock => 'غير متوفر';

  @override
  String get myOrders => 'طلباتي';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get offers => 'العروض';

  @override
  String get qrInvalid => 'رمز QR هذا لم يعد صالحًا. يرجى سؤال أحد الموظفين.';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get allCategories => 'الكل';

  @override
  String get statusPendingPayment => 'في انتظار الدفع';

  @override
  String get statusPlaced => 'جديد';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusPreparing => 'قيد التحضير';

  @override
  String get statusReady => 'جاهز';

  @override
  String get statusServed => 'تم التقديم';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get payUnpaid => 'غير مدفوع';

  @override
  String get payPartial => 'مدفوع جزئيًا';

  @override
  String get payPaid => 'مدفوع';

  @override
  String get payPartRefund => 'مسترد جزئيًا';

  @override
  String get payRefunded => 'مسترد';

  @override
  String get kitchenNew => 'جديد';

  @override
  String get kitchenInProgress => 'قيد التنفيذ';

  @override
  String get kitchenReady => 'جاهز';

  @override
  String get accept => 'قبول';

  @override
  String get startPreparing => 'بدء';

  @override
  String get markReady => 'جاهز';

  @override
  String get complete => 'إكمال';

  @override
  String get delayed => 'متأخر';

  @override
  String minutesShort(int count) {
    return '$count د';
  }

  @override
  String get priority => 'الأولوية';

  @override
  String get allStations => 'كل المحطات';

  @override
  String get noTickets => 'لا توجد طلبات الآن';

  @override
  String get connectionLost => 'انقطع الاتصال. جارٍ إعادة الاتصال…';

  @override
  String get takeaway => 'سفري';

  @override
  String get kitchenBranch => 'الفرع';

  @override
  String get dashboard => 'لوحة المعلومات';

  @override
  String get orders => 'الطلبات';

  @override
  String get menuManage => 'القائمة';

  @override
  String get tables => 'الطاولات';

  @override
  String get staff => 'الموظفون';

  @override
  String get inventory => 'المخزون';

  @override
  String get finance => 'المالية';

  @override
  String get marketing => 'التسويق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get ordersCount => 'الطلبات';

  @override
  String get averageOrder => 'متوسط الطلب';

  @override
  String get cancellationRate => 'معدل الإلغاء';

  @override
  String get topProducts => 'الأكثر مبيعًا';

  @override
  String get peakHours => 'ساعات الذروة';

  @override
  String get noDataYet => 'لا توجد بيانات لهذه الفترة بعد';

  @override
  String get registerCafe => 'سجّل مقهاك';

  @override
  String get cafeName => 'اسم المقهى';

  @override
  String get legalName => 'الاسم التجاري القانوني';

  @override
  String get country => 'الدولة';

  @override
  String get currency => 'العملة';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get address => 'العنوان';

  @override
  String get city => 'المدينة';

  @override
  String get ownerName => 'اسمك';

  @override
  String get pendingApproval =>
      'مقهاك بانتظار الموافقة. يمكنك إعداده في هذه الأثناء.';

  @override
  String get categories => 'الفئات';

  @override
  String get products => 'المنتجات';

  @override
  String get newCategory => 'فئة جديدة';

  @override
  String get newProduct => 'منتج جديد';

  @override
  String get price => 'السعر';

  @override
  String get category => 'الفئة';

  @override
  String get tableNumber => 'رقم الطاولة';

  @override
  String get capacity => 'السعة';

  @override
  String get qrCode => 'رمز QR';

  @override
  String get regenerateQr => 'إعادة إنشاء QR';

  @override
  String get inviteStaff => 'دعوة موظف';

  @override
  String get role => 'الدور';

  @override
  String get ingredients => 'المكونات';

  @override
  String get suppliers => 'الموردون';

  @override
  String get stock => 'المخزون';

  @override
  String get unit => 'الوحدة';

  @override
  String get unitCost => 'تكلفة الوحدة';

  @override
  String get stockIn => 'إدخال مخزون';

  @override
  String get expenses => 'المصروفات';

  @override
  String get sales => 'المبيعات';

  @override
  String get profitLoss => 'الأرباح والخسائر';

  @override
  String get exportExcel => 'تصدير Excel';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get branding => 'الهوية';

  @override
  String get primaryColor => 'اللون الأساسي';

  @override
  String get coupons => 'القسائم';

  @override
  String get code => 'الرمز';

  @override
  String get percent => 'نسبة مئوية';

  @override
  String get acceptOrder => 'قبول';

  @override
  String get markServed => 'تم التقديم';

  @override
  String get confirmCash => 'تأكيد النقد';

  @override
  String get refund => 'استرداد';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get invitationLink => 'أرسل رمز الدعوة هذا إلى موظفك';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get selectBranch => 'اختر الفرع';

  @override
  String get balance => 'الرصيد المستحق';

  @override
  String get customers => 'العملاء';

  @override
  String get reservations => 'الحجوزات';

  @override
  String get partySize => 'عدد الأشخاص';

  @override
  String get support => 'الدعم';

  @override
  String get subject => 'الموضوع';

  @override
  String get message => 'الرسالة';

  @override
  String get cafes => 'المقاهي';

  @override
  String get approve => 'موافقة';

  @override
  String get suspend => 'تعليق';

  @override
  String get activate => 'تفعيل';

  @override
  String get plans => 'الخطط';

  @override
  String get auditLogs => 'سجل التدقيق';

  @override
  String get health => 'حالة النظام';

  @override
  String get totalCafes => 'إجمالي المقاهي';

  @override
  String get activeCafes => 'المقاهي النشطة';

  @override
  String get totalCustomers => 'العملاء';

  @override
  String get totalOrders => 'إجمالي الطلبات';

  @override
  String get enrollMfa => 'إعداد تسجيل الدخول بخطوتين';

  @override
  String get mfaCode => 'رمز من 6 أرقام';

  @override
  String get mfaSecret => 'أضف هذا المفتاح إلى تطبيق المصادقة';

  @override
  String get grossByCurrency => 'إجمالي المبيعات حسب العملة';

  @override
  String get cafesByCountry => 'المقاهي حسب الدولة';

  @override
  String get activeSubscriptions => 'الاشتراكات النشطة';

  @override
  String get reasonPrompt => 'اذكر السبب. سيتم تسجيله في سجل التدقيق.';

  @override
  String get action => 'الإجراء';

  @override
  String get database => 'قاعدة البيانات';

  @override
  String get pendingCafes => 'بانتظار الموافقة';

  @override
  String get owner => 'المالك';

  @override
  String get stActive => 'نشط';

  @override
  String get stInactive => 'غير نشط';

  @override
  String get stAvailable => 'متاحة';

  @override
  String get stOccupied => 'مشغولة';

  @override
  String get stReserved => 'محجوزة';

  @override
  String get stCleaning => 'قيد التنظيف';

  @override
  String get stSuspended => 'معلّق';

  @override
  String get stRejected => 'مرفوض';

  @override
  String get stClosed => 'مغلق';

  @override
  String get stOpen => 'مفتوح';

  @override
  String get stResolved => 'تم الحل';

  @override
  String get stInProgress => 'قيد التنفيذ';

  @override
  String get stInvited => 'مدعو';

  @override
  String get roleManager => 'مدير';

  @override
  String get roleCashier => 'أمين صندوق';

  @override
  String get roleWaiter => 'نادل';

  @override
  String get roleKitchen => 'موظف مطبخ';

  @override
  String get setPricesIncludeTax => 'الأسعار تشمل الضريبة';

  @override
  String get setRequireAcceptance => 'الموظفون يقبلون الطلبات أولًا';

  @override
  String get setGuestOrdering => 'السماح بطلبات QR';

  @override
  String get setStockDeduction => 'خصم المخزون حسب الوصفات';

  @override
  String get setPaymentPolicy => 'متى يدفع الضيوف';

  @override
  String get policyPrepay => 'الدفع قبل التحضير';

  @override
  String get policyPostpay => 'الدفع بعد الوجبة';

  @override
  String get layoutList => 'قائمة';

  @override
  String get layoutGrid => 'شبكة';

  @override
  String get layoutCompact => 'مضغوط';

  @override
  String get periodMonthly => 'شهري';

  @override
  String get periodYearly => 'سنوي';

  @override
  String get healthCache => 'ذاكرة مؤقتة';

  @override
  String get healthEvents => 'أحداث منتظرة';

  @override
  String get healthWebhooks => 'Webhooks فاشلة';

  @override
  String get phone => 'الهاتف';

  @override
  String get notAvailable => 'لا ينطبق';

  @override
  String get plusTaxes => 'تُحسب الضرائب عند إرسال الطلب';

  @override
  String get variants => 'الخيارات';

  @override
  String get addVariant => 'إضافة خيار';

  @override
  String get addExtras => 'إضافة إضافات';

  @override
  String get optionName => 'اسم الخيار';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get uploadLogo => 'رفع الشعار';

  @override
  String get uploadCover => 'رفع الغلاف';

  @override
  String get banners => 'اللافتات';

  @override
  String get bannerTitle => 'عنوان اللافتة';

  @override
  String get branches => 'الفروع';

  @override
  String get addBranch => 'إضافة فرع';

  @override
  String get branchCode => 'رمز الفرع';

  @override
  String get businessHours => 'ساعات العمل';

  @override
  String get opensAt => 'يفتح';

  @override
  String get closesAt => 'يغلق';

  @override
  String get supportedLanguages => 'لغات العملاء';

  @override
  String get gatewaySetup => 'بوابة الدفع';

  @override
  String get provider => 'المزود';

  @override
  String get environment => 'الوضع';

  @override
  String get apiKeyId => 'معرّف مفتاح API';

  @override
  String get apiKeySecret => 'سر API';

  @override
  String get webhookSecret => 'سر Webhook';

  @override
  String get webhookUrl => 'رابط Webhook (أضفه في بوابتك)';

  @override
  String get paymentMethods => 'طرق الدفع';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get choosePlan => 'اختر خطة';

  @override
  String get cancelSubscription => 'إلغاء الاشتراك';

  @override
  String get splitBill => 'تقسيم الفاتورة';

  @override
  String get numberOfParts => 'عدد الأجزاء';

  @override
  String get transferTable => 'نقل إلى طاولة';

  @override
  String get recipe => 'الوصفة';

  @override
  String get purchaseOrders => 'أوامر الشراء';

  @override
  String get newPurchaseOrder => 'أمر شراء جديد';

  @override
  String get receiveGoods => 'استلام البضاعة';

  @override
  String get supplierInvoices => 'فواتير الموردين';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String get expiringStock => 'مخزون قارب على الانتهاء';

  @override
  String get trialBalance => 'ميزان المراجعة';

  @override
  String get debit => 'مدين';

  @override
  String get credit => 'دائن';

  @override
  String get balanceSheet => 'الميزانية العمومية';

  @override
  String get assets => 'الأصول';

  @override
  String get liabilities => 'الالتزامات';

  @override
  String get equity => 'حقوق الملكية';

  @override
  String get journal => 'دفتر اليومية';

  @override
  String get reverse => 'عكس القيد';

  @override
  String get periods => 'الفترات';

  @override
  String get closePeriod => 'إغلاق الفترة';

  @override
  String get cashRegisters => 'صناديق النقد';

  @override
  String get openRegister => 'فتح الصندوق';

  @override
  String get closeRegister => 'إغلاق الصندوق';

  @override
  String get openingFloat => 'الرصيد الافتتاحي';

  @override
  String get countedCash => 'النقد المعدود';

  @override
  String get expectedCash => 'النقد المتوقع';

  @override
  String get variance => 'الفرق';

  @override
  String get payroll => 'الرواتب';

  @override
  String get grossPay => 'إجمالي الراتب';

  @override
  String get deductions => 'الاستقطاعات';

  @override
  String get markPaid => 'تحديد كمدفوع';

  @override
  String get attendance => 'الحضور';

  @override
  String get clockIn => 'تسجيل الدخول للعمل';

  @override
  String get clockOut => 'تسجيل الخروج من العمل';

  @override
  String get clockedIn => 'تم';

  @override
  String get promotions => 'العروض الترويجية';

  @override
  String get loyalty => 'الولاء';

  @override
  String get pointsPerUnit => 'نقاط لكل وحدة عملة';

  @override
  String get valuePerPoint => 'قيمة النقطة';

  @override
  String get reply => 'رد';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get stations => 'محطات المطبخ';

  @override
  String get routeToStation => 'إرسال إلى محطة';

  @override
  String get users => 'المستخدمون';

  @override
  String get disable => 'تعطيل';

  @override
  String get translations => 'الترجمات';

  @override
  String get translationKey => 'المفتاح';

  @override
  String get translationValue => 'النص';

  @override
  String get countries => 'الدول';

  @override
  String get commissions => 'العمولات';

  @override
  String get announcements => 'الإعلانات';

  @override
  String get bodyText => 'نص الرسالة';

  @override
  String get addresses => 'العناوين المحفوظة';

  @override
  String get addressLabel => 'التسمية';

  @override
  String get completedOrders => 'الطلبات المكتملة';

  @override
  String get chooseCafe => 'اختر مقهى';

  @override
  String get reserveTable => 'حجز طاولة';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get payments => 'المدفوعات';

  @override
  String get refunds => 'المبالغ المستردة';

  @override
  String get settlements => 'التسويات';

  @override
  String get syncSettlements => 'جلب التسويات';

  @override
  String get paymentLink => 'رابط الدفع';

  @override
  String get createPaymentLink => 'إنشاء رابط دفع';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get connectionOk => 'تم الاتصال. الدفع عبر الإنترنت مفعّل.';

  @override
  String get connectionFailed => 'رفضت البوابة هذه المفاتيح.';

  @override
  String get payPart => 'دفع جزء من الفاتورة';

  @override
  String get amountToPay => 'المبلغ المراد دفعه';

  @override
  String get paymentSuccessful => 'تم استلام الدفعة. شكرًا لك!';

  @override
  String get paymentNotCompleted =>
      'لم تكتمل عملية الدفع. لم يتم خصم هذه المحاولة.';

  @override
  String get payOnline => 'ادفع عبر الإنترنت';

  @override
  String get gatewayFee => 'رسوم البوابة';

  @override
  String get referenceLabel => 'المرجع';

  @override
  String get paymentBreakdown => 'ملخص المدفوعات';

  @override
  String get approveRefund => 'الموافقة على الاسترداد';

  @override
  String get refundRequested => 'تم طلب الاسترداد. يجب أن يوافق المدير.';

  @override
  String get reconciled => 'تمت المطابقة';

  @override
  String get needsReview => 'تحتاج إلى مراجعة';

  @override
  String get pendingKeys =>
      'تم الحفظ. اختبر الاتصال لتفعيل الدفع عبر الإنترنت.';

  @override
  String get openingCheckout => 'جارٍ فتح صفحة الدفع الآمنة…';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get revenueTrend => 'الإيرادات حسب اليوم';

  @override
  String get recentOrders => 'الطلبات الأخيرة';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get filterAll => 'الكل';

  @override
  String get available => 'متوفر';

  @override
  String get loginTagline => 'أدر مقهاك بأناقة من مكان واحد.';

  @override
  String get signInSubtitle => 'سجّل الدخول للمتابعة';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get back => 'رجوع';

  @override
  String get adminConsole => 'لوحة تحكم المنصة';

  @override
  String get adminLoginTagline => 'كل مقاهي المنصة في لمحة واحدة.';

  @override
  String get kitchenDisplay => 'شاشة المطبخ';

  @override
  String get kitchenLoginTagline => 'كل طلب واضح من أي مكان في المطبخ.';

  @override
  String get customerLoginTagline =>
      'احفظ المفضلة وتتبّع طلباتك واكسب المكافآت.';

  @override
  String get signInToOrder => 'سجّل الدخول لتطلب';

  @override
  String get signInToOrderHint =>
      'تصفّح كما تشاء. لتقديم طلب، سجّل الدخول أو أنشئ حسابًا.';

  @override
  String get roleOwner => 'المالك';

  @override
  String get markAvailable => 'تعيين كمتاحة';

  @override
  String get tableReleased => 'الطاولة متاحة الآن';

  @override
  String get tableHasUnpaid =>
      'لهذه الطاولة طلبات غير مدفوعة. سدّد الفاتورة أولًا.';

  @override
  String unpaidForMinutes(int minutes) {
    return 'غير مدفوع منذ $minutes دقيقة';
  }

  @override
  String tablePin(String pin) {
    return 'الرمز $pin';
  }

  @override
  String get enterTablePin => 'أدخل رمز الطاولة';

  @override
  String get tablePinHint =>
      'اطلب من الموظفين الرمز المكوّن من 4 أرقام لطاولتك.';

  @override
  String get tablePinWrong => 'هذا الرمز غير صحيح. يُرجى التحقق مع الموظفين.';

  @override
  String get setTablePin => 'اطلب من الضيوف رمز الطاولة قبل الطلب';

  @override
  String get setSessionEndAfterPayment =>
      'أنهِ جلسة الطاولة بعد الدفع بهذه المدة';

  @override
  String get setUnpaidAlert => 'نبّه الموظفين إلى الطلبات غير المدفوعة بعد';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get resetPassword => 'تعيين كلمة مرور جديدة';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordResetDone =>
      'تم تغيير كلمة المرور. يمكنك تسجيل الدخول الآن.';

  @override
  String get resetLinkInvalid =>
      'انتهت صلاحية رابط إعادة التعيين أو تم استخدامه.';

  @override
  String get passwordResetUnavailable =>
      'إعادة تعيين كلمة المرور غير متاحة بعد.';

  @override
  String get minutesUnit => 'دقيقة';

  @override
  String get resetLinkSent =>
      'إذا كان لهذا البريد حساب، فسيصلك رابط إعادة التعيين.';

  @override
  String countsForDay(String date) {
    return 'يُحتسب ليوم $date';
  }
}
