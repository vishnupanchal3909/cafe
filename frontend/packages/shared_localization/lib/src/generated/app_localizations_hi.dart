// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get add => 'जोड़ें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get search => 'खोजें';

  @override
  String get close => 'बंद करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get emptyTitle => 'अभी यहां कुछ नहीं है';

  @override
  String get errorTitle => 'कुछ गलत हो गया';

  @override
  String get networkError =>
      'सर्वर से संपर्क नहीं हो पा रहा। अपना कनेक्शन जांचें।';

  @override
  String get invalidCredentials => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get accountLocked => 'बहुत अधिक प्रयास। बाद में कोशिश करें।';

  @override
  String get rateLimited => 'बहुत अधिक अनुरोध। कृपया थोड़ा रुकें।';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get name => 'नाम';

  @override
  String get language => 'भाषा';

  @override
  String get requiredField => 'आवश्यक';

  @override
  String get invalidValue => 'अमान्य मान';

  @override
  String get total => 'कुल';

  @override
  String get subtotal => 'उप-योग';

  @override
  String get discount => 'छूट';

  @override
  String get tax => 'कर';

  @override
  String get serviceCharge => 'सेवा शुल्क';

  @override
  String get status => 'स्थिति';

  @override
  String get date => 'तिथि';

  @override
  String get amount => 'राशि';

  @override
  String get quantity => 'मात्रा';

  @override
  String get notes => 'टिप्पणी';

  @override
  String get reason => 'कारण';

  @override
  String get refresh => 'ताज़ा करें';

  @override
  String welcomeTable(String table) {
    return 'टेबल $table';
  }

  @override
  String get menu => 'मेनू';

  @override
  String get cart => 'कार्ट';

  @override
  String get addToCart => 'कार्ट में जोड़ें';

  @override
  String get viewCart => 'कार्ट देखें';

  @override
  String get emptyCart => 'आपकी कार्ट खाली है';

  @override
  String get chooseOption => 'एक विकल्प चुनें';

  @override
  String get extras => 'अतिरिक्त';

  @override
  String get specialInstructions => 'विशेष निर्देश';

  @override
  String get placeOrder => 'ऑर्डर करें';

  @override
  String get orderPlaced => 'ऑर्डर हो गया';

  @override
  String orderNumber(int number) {
    return 'ऑर्डर #$number';
  }

  @override
  String get trackOrder => 'ऑर्डर ट्रैक करें';

  @override
  String get payNow => 'अभी भुगतान करें';

  @override
  String get payAtCounter => 'काउंटर पर भुगतान करें';

  @override
  String get onlinePaymentUnavailable =>
      'यहां अभी ऑनलाइन भुगतान उपलब्ध नहीं है। कृपया काउंटर पर भुगतान करें।';

  @override
  String get paymentPending => 'भुगतान की पुष्टि का इंतजार';

  @override
  String get receipt => 'रसीद';

  @override
  String get rateUs => 'अपने अनुभव को रेट करें';

  @override
  String get submit => 'भेजें';

  @override
  String get thanks => 'धन्यवाद!';

  @override
  String get callWaiter => 'वेटर को बुलाएं';

  @override
  String get requestBill => 'बिल मांगें';

  @override
  String get callStaff => 'स्टाफ को बुलाएं';

  @override
  String get requestSent => 'अनुरोध भेज दिया गया। स्टाफ को सूचित किया गया।';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get wishlist => 'इच्छा सूची';

  @override
  String get recentlyOrdered => 'हाल के ऑर्डर';

  @override
  String get coupon => 'कूपन कोड';

  @override
  String get apply => 'लागू करें';

  @override
  String get couponInvalid => 'यह कूपन उपयोग नहीं किया जा सकता';

  @override
  String get veg => 'शाकाहारी';

  @override
  String get nonVeg => 'मांसाहारी';

  @override
  String get egg => 'अंडा';

  @override
  String get vegan => 'वीगन';

  @override
  String get outOfStock => 'स्टॉक में नहीं';

  @override
  String get myOrders => 'मेरे ऑर्डर';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get offers => 'ऑफ़र';

  @override
  String get qrInvalid => 'यह QR कोड अब मान्य नहीं है। कृपया स्टाफ से पूछें।';

  @override
  String get noResults => 'कोई मिलता-जुलता आइटम नहीं';

  @override
  String get allCategories => 'सभी';

  @override
  String get statusPendingPayment => 'भुगतान बाकी';

  @override
  String get statusPlaced => 'नया';

  @override
  String get statusAccepted => 'स्वीकृत';

  @override
  String get statusPreparing => 'बन रहा है';

  @override
  String get statusReady => 'तैयार';

  @override
  String get statusServed => 'परोसा गया';

  @override
  String get statusCompleted => 'पूर्ण';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get payUnpaid => 'अवैतनिक';

  @override
  String get payPartial => 'आंशिक भुगतान';

  @override
  String get payPaid => 'भुगतान हो गया';

  @override
  String get payPartRefund => 'आंशिक वापसी';

  @override
  String get payRefunded => 'वापस किया गया';

  @override
  String get kitchenNew => 'नया';

  @override
  String get kitchenInProgress => 'जारी';

  @override
  String get kitchenReady => 'तैयार';

  @override
  String get accept => 'स्वीकारें';

  @override
  String get startPreparing => 'शुरू करें';

  @override
  String get markReady => 'तैयार';

  @override
  String get complete => 'पूरा करें';

  @override
  String get delayed => 'देरी';

  @override
  String minutesShort(int count) {
    return '$count मिनट';
  }

  @override
  String get priority => 'प्राथमिकता';

  @override
  String get allStations => 'सभी स्टेशन';

  @override
  String get noTickets => 'अभी कोई ऑर्डर नहीं';

  @override
  String get connectionLost => 'कनेक्शन टूट गया। फिर जुड़ रहा है…';

  @override
  String get takeaway => 'पार्सल';

  @override
  String get kitchenBranch => 'शाखा';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get orders => 'ऑर्डर';

  @override
  String get menuManage => 'मेनू';

  @override
  String get tables => 'टेबल';

  @override
  String get staff => 'स्टाफ';

  @override
  String get inventory => 'इन्वेंटरी';

  @override
  String get finance => 'वित्त';

  @override
  String get marketing => 'मार्केटिंग';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get revenue => 'राजस्व';

  @override
  String get ordersCount => 'ऑर्डर';

  @override
  String get averageOrder => 'औसत ऑर्डर';

  @override
  String get cancellationRate => 'रद्द करने की दर';

  @override
  String get topProducts => 'शीर्ष उत्पाद';

  @override
  String get peakHours => 'व्यस्त समय';

  @override
  String get noDataYet => 'इस अवधि का कोई डेटा नहीं';

  @override
  String get registerCafe => 'अपना कैफ़े पंजीकृत करें';

  @override
  String get cafeName => 'कैफ़े का नाम';

  @override
  String get legalName => 'कानूनी व्यवसाय नाम';

  @override
  String get country => 'देश';

  @override
  String get currency => 'मुद्रा';

  @override
  String get timezone => 'समय क्षेत्र';

  @override
  String get address => 'पता';

  @override
  String get city => 'शहर';

  @override
  String get ownerName => 'आपका नाम';

  @override
  String get pendingApproval =>
      'आपका कैफ़े अनुमोदन की प्रतीक्षा में है। तब तक आप इसे सेट कर सकते हैं।';

  @override
  String get categories => 'श्रेणियां';

  @override
  String get products => 'उत्पाद';

  @override
  String get newCategory => 'नई श्रेणी';

  @override
  String get newProduct => 'नया उत्पाद';

  @override
  String get price => 'कीमत';

  @override
  String get category => 'श्रेणी';

  @override
  String get tableNumber => 'टेबल नंबर';

  @override
  String get capacity => 'क्षमता';

  @override
  String get qrCode => 'QR कोड';

  @override
  String get regenerateQr => 'QR फिर बनाएं';

  @override
  String get inviteStaff => 'स्टाफ को आमंत्रित करें';

  @override
  String get role => 'भूमिका';

  @override
  String get ingredients => 'सामग्री';

  @override
  String get suppliers => 'आपूर्तिकर्ता';

  @override
  String get stock => 'स्टॉक';

  @override
  String get unit => 'इकाई';

  @override
  String get unitCost => 'इकाई लागत';

  @override
  String get stockIn => 'स्टॉक जोड़ें';

  @override
  String get expenses => 'खर्च';

  @override
  String get sales => 'बिक्री';

  @override
  String get profitLoss => 'लाभ और हानि';

  @override
  String get exportExcel => 'Excel निर्यात';

  @override
  String get exportPdf => 'PDF निर्यात';

  @override
  String get branding => 'ब्रांडिंग';

  @override
  String get primaryColor => 'मुख्य रंग';

  @override
  String get coupons => 'कूपन';

  @override
  String get code => 'कोड';

  @override
  String get percent => 'प्रतिशत';

  @override
  String get acceptOrder => 'स्वीकारें';

  @override
  String get markServed => 'परोसा गया';

  @override
  String get confirmCash => 'नकद की पुष्टि करें';

  @override
  String get refund => 'रिफंड';

  @override
  String get netProfit => 'शुद्ध लाभ';

  @override
  String get totalRevenue => 'कुल राजस्व';

  @override
  String get totalExpenses => 'कुल खर्च';

  @override
  String get invitationLink => 'यह आमंत्रण टोकन अपने कर्मचारी को भेजें';

  @override
  String get cancelOrder => 'ऑर्डर रद्द करें';

  @override
  String get selectBranch => 'शाखा चुनें';

  @override
  String get balance => 'बकाया राशि';

  @override
  String get customers => 'ग्राहक';

  @override
  String get reservations => 'आरक्षण';

  @override
  String get partySize => 'लोगों की संख्या';

  @override
  String get support => 'सहायता';

  @override
  String get subject => 'विषय';

  @override
  String get message => 'संदेश';

  @override
  String get cafes => 'कैफ़े';

  @override
  String get approve => 'स्वीकृत करें';

  @override
  String get suspend => 'निलंबित करें';

  @override
  String get activate => 'सक्रिय करें';

  @override
  String get plans => 'योजनाएं';

  @override
  String get auditLogs => 'ऑडिट लॉग';

  @override
  String get health => 'सिस्टम स्थिति';

  @override
  String get totalCafes => 'कुल कैफ़े';

  @override
  String get activeCafes => 'सक्रिय कैफ़े';

  @override
  String get totalCustomers => 'ग्राहक';

  @override
  String get totalOrders => 'कुल ऑर्डर';

  @override
  String get enrollMfa => 'दो-चरणीय साइन-इन सेट करें';

  @override
  String get mfaCode => '6 अंकों का कोड';

  @override
  String get mfaSecret => 'यह कुंजी अपने ऑथेंटिकेटर ऐप में जोड़ें';

  @override
  String get grossByCurrency => 'मुद्रा अनुसार सकल बिक्री';

  @override
  String get cafesByCountry => 'देश अनुसार कैफ़े';

  @override
  String get activeSubscriptions => 'सक्रिय सदस्यताएं';

  @override
  String get reasonPrompt => 'कारण बताएं। यह ऑडिट लॉग में दर्ज होगा।';

  @override
  String get action => 'कार्रवाई';

  @override
  String get database => 'डेटाबेस';

  @override
  String get pendingCafes => 'अनुमोदन बाकी';

  @override
  String get owner => 'मालिक';

  @override
  String get stActive => 'सक्रिय';

  @override
  String get stInactive => 'निष्क्रिय';

  @override
  String get stAvailable => 'उपलब्ध';

  @override
  String get stOccupied => 'भरा हुआ';

  @override
  String get stReserved => 'आरक्षित';

  @override
  String get stCleaning => 'सफ़ाई जारी';

  @override
  String get stSuspended => 'निलंबित';

  @override
  String get stRejected => 'अस्वीकृत';

  @override
  String get stClosed => 'बंद';

  @override
  String get stOpen => 'खुला';

  @override
  String get stResolved => 'हल किया गया';

  @override
  String get stInProgress => 'जारी';

  @override
  String get stInvited => 'आमंत्रित';

  @override
  String get roleManager => 'प्रबंधक';

  @override
  String get roleCashier => 'कैशियर';

  @override
  String get roleWaiter => 'वेटर';

  @override
  String get roleKitchen => 'रसोई स्टाफ';

  @override
  String get setPricesIncludeTax => 'कीमतों में कर शामिल है';

  @override
  String get setRequireAcceptance => 'पहले स्टाफ ऑर्डर स्वीकार करे';

  @override
  String get setGuestOrdering => 'QR से मेहमान ऑर्डर की अनुमति दें';

  @override
  String get setStockDeduction => 'रेसिपी से स्टॉक घटाएं';

  @override
  String get setPaymentPolicy => 'मेहमान कब भुगतान करें';

  @override
  String get policyPrepay => 'तैयारी से पहले भुगतान';

  @override
  String get policyPostpay => 'भोजन के बाद भुगतान';

  @override
  String get layoutList => 'सूची';

  @override
  String get layoutGrid => 'ग्रिड';

  @override
  String get layoutCompact => 'संक्षिप्त';

  @override
  String get periodMonthly => 'मासिक';

  @override
  String get periodYearly => 'वार्षिक';

  @override
  String get healthCache => 'कैश';

  @override
  String get healthEvents => 'प्रतीक्षारत इवेंट';

  @override
  String get healthWebhooks => 'विफल वेबहुक';

  @override
  String get phone => 'फ़ोन';

  @override
  String get notAvailable => 'लागू नहीं';

  @override
  String get plusTaxes => 'ऑर्डर करते समय कर की गणना होती है';

  @override
  String get variants => 'विकल्प';

  @override
  String get addVariant => 'विकल्प जोड़ें';

  @override
  String get addExtras => 'अतिरिक्त जोड़ें';

  @override
  String get optionName => 'विकल्प का नाम';

  @override
  String get uploadImage => 'छवि अपलोड करें';

  @override
  String get uploadLogo => 'लोगो अपलोड करें';

  @override
  String get uploadCover => 'कवर अपलोड करें';

  @override
  String get banners => 'बैनर';

  @override
  String get bannerTitle => 'बैनर शीर्षक';

  @override
  String get branches => 'शाखाएं';

  @override
  String get addBranch => 'शाखा जोड़ें';

  @override
  String get branchCode => 'शाखा कोड';

  @override
  String get businessHours => 'व्यावसायिक समय';

  @override
  String get opensAt => 'खुलता है';

  @override
  String get closesAt => 'बंद होता है';

  @override
  String get supportedLanguages => 'ग्राहक भाषाएं';

  @override
  String get gatewaySetup => 'भुगतान गेटवे';

  @override
  String get provider => 'प्रदाता';

  @override
  String get environment => 'मोड';

  @override
  String get apiKeyId => 'API की ID';

  @override
  String get apiKeySecret => 'API सीक्रेट';

  @override
  String get webhookSecret => 'वेबहुक सीक्रेट';

  @override
  String get webhookUrl => 'वेबहुक URL (इसे अपने गेटवे में जोड़ें)';

  @override
  String get paymentMethods => 'भुगतान के तरीके';

  @override
  String get subscription => 'सदस्यता';

  @override
  String get choosePlan => 'योजना चुनें';

  @override
  String get cancelSubscription => 'सदस्यता रद्द करें';

  @override
  String get splitBill => 'बिल बांटें';

  @override
  String get numberOfParts => 'हिस्सों की संख्या';

  @override
  String get transferTable => 'टेबल बदलें';

  @override
  String get recipe => 'रेसिपी';

  @override
  String get purchaseOrders => 'खरीद आदेश';

  @override
  String get newPurchaseOrder => 'नया खरीद आदेश';

  @override
  String get receiveGoods => 'माल प्राप्त करें';

  @override
  String get supplierInvoices => 'आपूर्तिकर्ता चालान';

  @override
  String get invoiceNumber => 'चालान संख्या';

  @override
  String get recordPayment => 'भुगतान दर्ज करें';

  @override
  String get expiringStock => 'समाप्त होने वाला स्टॉक';

  @override
  String get trialBalance => 'ट्रायल बैलेंस';

  @override
  String get debit => 'डेबिट';

  @override
  String get credit => 'क्रेडिट';

  @override
  String get balanceSheet => 'बैलेंस शीट';

  @override
  String get assets => 'संपत्ति';

  @override
  String get liabilities => 'देनदारियां';

  @override
  String get equity => 'इक्विटी';

  @override
  String get journal => 'जर्नल';

  @override
  String get reverse => 'उलटें';

  @override
  String get periods => 'अवधियां';

  @override
  String get closePeriod => 'अवधि बंद करें';

  @override
  String get cashRegisters => 'कैश रजिस्टर';

  @override
  String get openRegister => 'रजिस्टर खोलें';

  @override
  String get closeRegister => 'रजिस्टर बंद करें';

  @override
  String get openingFloat => 'प्रारंभिक नकद';

  @override
  String get countedCash => 'गिना हुआ नकद';

  @override
  String get expectedCash => 'अपेक्षित नकद';

  @override
  String get variance => 'अंतर';

  @override
  String get payroll => 'वेतन';

  @override
  String get grossPay => 'सकल वेतन';

  @override
  String get deductions => 'कटौती';

  @override
  String get markPaid => 'भुगतान किया चिह्नित करें';

  @override
  String get attendance => 'उपस्थिति';

  @override
  String get clockIn => 'क्लॉक इन';

  @override
  String get clockOut => 'क्लॉक आउट';

  @override
  String get clockedIn => 'हो गया';

  @override
  String get promotions => 'प्रचार';

  @override
  String get loyalty => 'लॉयल्टी';

  @override
  String get pointsPerUnit => 'प्रति मुद्रा इकाई अंक';

  @override
  String get valuePerPoint => 'एक अंक का मूल्य';

  @override
  String get reply => 'उत्तर दें';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get stations => 'रसोई स्टेशन';

  @override
  String get routeToStation => 'स्टेशन पर भेजें';

  @override
  String get users => 'उपयोगकर्ता';

  @override
  String get disable => 'अक्षम करें';

  @override
  String get translations => 'अनुवाद';

  @override
  String get translationKey => 'कुंजी';

  @override
  String get translationValue => 'पाठ';

  @override
  String get countries => 'देश';

  @override
  String get commissions => 'कमीशन';

  @override
  String get announcements => 'घोषणाएं';

  @override
  String get bodyText => 'संदेश';

  @override
  String get addresses => 'सहेजे गए पते';

  @override
  String get addressLabel => 'लेबल';

  @override
  String get completedOrders => 'पूर्ण ऑर्डर';

  @override
  String get chooseCafe => 'कैफ़े चुनें';

  @override
  String get reserveTable => 'टेबल आरक्षित करें';

  @override
  String get tomorrow => 'कल';

  @override
  String get payments => 'भुगतान';

  @override
  String get refunds => 'रिफंड';

  @override
  String get settlements => 'सेटलमेंट';

  @override
  String get syncSettlements => 'सेटलमेंट लाएं';

  @override
  String get paymentLink => 'भुगतान लिंक';

  @override
  String get createPaymentLink => 'भुगतान लिंक बनाएं';

  @override
  String get testConnection => 'कनेक्शन जांचें';

  @override
  String get connectionOk => 'जुड़ गया। ऑनलाइन भुगतान चालू है।';

  @override
  String get connectionFailed => 'गेटवे ने ये कुंजियां अस्वीकार कीं।';

  @override
  String get payPart => 'बिल का कुछ हिस्सा चुकाएं';

  @override
  String get amountToPay => 'चुकाने की राशि';

  @override
  String get paymentSuccessful => 'भुगतान मिल गया। धन्यवाद!';

  @override
  String get paymentNotCompleted =>
      'भुगतान पूरा नहीं हुआ। इस प्रयास के लिए कोई शुल्क नहीं लिया गया।';

  @override
  String get payOnline => 'ऑनलाइन भुगतान करें';

  @override
  String get gatewayFee => 'गेटवे शुल्क';

  @override
  String get referenceLabel => 'संदर्भ';

  @override
  String get paymentBreakdown => 'भुगतान सारांश';

  @override
  String get approveRefund => 'रिफंड स्वीकृत करें';

  @override
  String get refundRequested =>
      'रिफंड का अनुरोध किया गया। प्रबंधक की स्वीकृति चाहिए।';

  @override
  String get reconciled => 'मिलान हो गया';

  @override
  String get needsReview => 'जांच ज़रूरी';

  @override
  String get pendingKeys =>
      'सहेजा गया। ऑनलाइन भुगतान चालू करने के लिए कनेक्शन जांचें।';

  @override
  String get openingCheckout => 'सुरक्षित चेकआउट खुल रहा है…';

  @override
  String get welcomeBack => 'आपका फिर से स्वागत है';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get revenueTrend => 'दिन के अनुसार आय';

  @override
  String get recentOrders => 'हाल के ऑर्डर';

  @override
  String get addPhoto => 'फ़ोटो जोड़ें';

  @override
  String get changePhoto => 'फ़ोटो बदलें';

  @override
  String get removePhoto => 'फ़ोटो हटाएं';

  @override
  String get filterAll => 'सभी';

  @override
  String get available => 'उपलब्ध';

  @override
  String get loginTagline => 'अपना कैफ़े एक ही जगह से शानदार तरीके से चलाएं।';

  @override
  String get signInSubtitle => 'जारी रखने के लिए साइन इन करें';

  @override
  String get showPassword => 'पासवर्ड दिखाएँ';

  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get back => 'वापस';

  @override
  String get adminConsole => 'प्लेटफ़ॉर्म कंसोल';

  @override
  String get adminLoginTagline => 'प्लेटफ़ॉर्म के सभी कैफ़े, एक नज़र में।';

  @override
  String get kitchenDisplay => 'किचन डिस्प्ले';

  @override
  String get kitchenLoginTagline => 'हर टिकट, किचन के उस पार से भी साफ़।';

  @override
  String get customerLoginTagline =>
      'पसंदीदा सहेजें, ऑर्डर ट्रैक करें और रिवॉर्ड कमाएँ।';

  @override
  String get signInToOrder => 'ऑर्डर करने के लिए साइन इन करें';

  @override
  String get signInToOrderHint =>
      'जितना चाहें देखें। ऑर्डर करने के लिए साइन इन करें या खाता बनाएँ।';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get markAvailable => 'उपलब्ध करें';

  @override
  String get tableReleased => 'टेबल अब उपलब्ध है';

  @override
  String get tableHasUnpaid =>
      'इस टेबल के ऑर्डर का भुगतान अभी बाकी है। पहले बिल चुकाएँ।';

  @override
  String unpaidForMinutes(int minutes) {
    return '$minutes मिनट से भुगतान बाकी';
  }

  @override
  String tablePin(String pin) {
    return 'PIN $pin';
  }

  @override
  String get enterTablePin => 'टेबल PIN डालें';

  @override
  String get tablePinHint => 'अपनी टेबल का 4 अंकों का PIN स्टाफ से पूछें।';

  @override
  String get tablePinWrong => 'यह PIN मेल नहीं खाता। कृपया स्टाफ से पूछें।';

  @override
  String get setTablePin => 'ऑर्डर से पहले मेहमानों से टेबल PIN पूछें';

  @override
  String get setSessionEndAfterPayment =>
      'भुगतान के इतने समय बाद मेहमानों का टेबल सेशन खत्म करें';

  @override
  String get setUnpaidAlert =>
      'इतने समय बाद भी भुगतान न हुए ऑर्डर पर स्टाफ को चेताएँ';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get resetPassword => 'नया पासवर्ड सेट करें';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get passwordResetDone => 'पासवर्ड बदल गया। अब आप साइन इन कर सकते हैं।';

  @override
  String get resetLinkInvalid =>
      'यह रीसेट लिंक समाप्त हो गया है या पहले ही उपयोग हो चुका है।';

  @override
  String get passwordResetUnavailable => 'पासवर्ड रीसेट अभी उपलब्ध नहीं है।';

  @override
  String get minutesUnit => 'मिनट';

  @override
  String get resetLinkSent =>
      'अगर इस ईमेल का खाता है, तो रीसेट लिंक भेजा जा रहा है।';

  @override
  String countsForDay(String date) {
    return '$date में गिना गया';
  }
}
