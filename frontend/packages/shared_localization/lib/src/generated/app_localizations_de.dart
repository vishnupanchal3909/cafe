// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get search => 'Suchen';

  @override
  String get close => 'Schließen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get emptyTitle => 'Noch nichts vorhanden';

  @override
  String get errorTitle => 'Etwas ist schiefgelaufen';

  @override
  String get networkError => 'Server nicht erreichbar. Prüfe deine Verbindung.';

  @override
  String get invalidCredentials => 'E-Mail oder Passwort ist falsch.';

  @override
  String get accountLocked =>
      'Zu viele Versuche. Bitte später erneut versuchen.';

  @override
  String get rateLimited => 'Zu viele Anfragen. Bitte kurz warten.';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get name => 'Name';

  @override
  String get language => 'Sprache';

  @override
  String get requiredField => 'Erforderlich';

  @override
  String get invalidValue => 'Ungültiger Wert';

  @override
  String get total => 'Gesamt';

  @override
  String get subtotal => 'Zwischensumme';

  @override
  String get discount => 'Rabatt';

  @override
  String get tax => 'Steuer';

  @override
  String get serviceCharge => 'Servicegebühr';

  @override
  String get status => 'Status';

  @override
  String get date => 'Datum';

  @override
  String get amount => 'Betrag';

  @override
  String get quantity => 'Menge';

  @override
  String get notes => 'Notizen';

  @override
  String get reason => 'Grund';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String welcomeTable(String table) {
    return 'Tisch $table';
  }

  @override
  String get menu => 'Speisekarte';

  @override
  String get cart => 'Warenkorb';

  @override
  String get addToCart => 'In den Warenkorb';

  @override
  String get viewCart => 'Warenkorb ansehen';

  @override
  String get emptyCart => 'Dein Warenkorb ist leer';

  @override
  String get chooseOption => 'Option wählen';

  @override
  String get extras => 'Extras';

  @override
  String get specialInstructions => 'Besondere Wünsche';

  @override
  String get placeOrder => 'Bestellen';

  @override
  String get orderPlaced => 'Bestellung aufgegeben';

  @override
  String orderNumber(int number) {
    return 'Bestellung #$number';
  }

  @override
  String get trackOrder => 'Bestellung verfolgen';

  @override
  String get payNow => 'Jetzt bezahlen';

  @override
  String get payAtCounter => 'An der Kasse bezahlen';

  @override
  String get onlinePaymentUnavailable =>
      'Onlinezahlung ist hier noch nicht verfügbar. Bitte an der Kasse bezahlen.';

  @override
  String get paymentPending => 'Warte auf Zahlungsbestätigung';

  @override
  String get receipt => 'Beleg';

  @override
  String get rateUs => 'Bewerte dein Erlebnis';

  @override
  String get submit => 'Senden';

  @override
  String get thanks => 'Danke!';

  @override
  String get callWaiter => 'Bedienung rufen';

  @override
  String get requestBill => 'Rechnung anfordern';

  @override
  String get callStaff => 'Personal rufen';

  @override
  String get requestSent => 'Anfrage gesendet. Das Personal wurde informiert.';

  @override
  String get favorites => 'Favoriten';

  @override
  String get wishlist => 'Wunschliste';

  @override
  String get recentlyOrdered => 'Zuletzt bestellt';

  @override
  String get coupon => 'Gutscheincode';

  @override
  String get apply => 'Einlösen';

  @override
  String get couponInvalid => 'Dieser Gutschein kann nicht verwendet werden';

  @override
  String get veg => 'Vegetarisch';

  @override
  String get nonVeg => 'Nicht vegetarisch';

  @override
  String get egg => 'Ei';

  @override
  String get vegan => 'Vegan';

  @override
  String get outOfStock => 'Ausverkauft';

  @override
  String get myOrders => 'Meine Bestellungen';

  @override
  String get profile => 'Profil';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get offers => 'Angebote';

  @override
  String get qrInvalid =>
      'Dieser QR-Code ist nicht mehr gültig. Bitte frage das Personal.';

  @override
  String get noResults => 'Keine Treffer';

  @override
  String get allCategories => 'Alle';

  @override
  String get statusPendingPayment => 'Zahlung ausstehend';

  @override
  String get statusPlaced => 'Neu';

  @override
  String get statusAccepted => 'Angenommen';

  @override
  String get statusPreparing => 'In Zubereitung';

  @override
  String get statusReady => 'Fertig';

  @override
  String get statusServed => 'Serviert';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get statusCancelled => 'Storniert';

  @override
  String get payUnpaid => 'Unbezahlt';

  @override
  String get payPartial => 'Teilweise bezahlt';

  @override
  String get payPaid => 'Bezahlt';

  @override
  String get payPartRefund => 'Teilweise erstattet';

  @override
  String get payRefunded => 'Erstattet';

  @override
  String get kitchenNew => 'Neu';

  @override
  String get kitchenInProgress => 'In Arbeit';

  @override
  String get kitchenReady => 'Fertig';

  @override
  String get accept => 'Annehmen';

  @override
  String get startPreparing => 'Starten';

  @override
  String get markReady => 'Fertig';

  @override
  String get complete => 'Abschließen';

  @override
  String get delayed => 'Verspätet';

  @override
  String minutesShort(int count) {
    return '$count Min.';
  }

  @override
  String get priority => 'Priorität';

  @override
  String get allStations => 'Alle Stationen';

  @override
  String get noTickets => 'Derzeit keine Bestellungen';

  @override
  String get connectionLost => 'Verbindung verloren. Verbinde neu…';

  @override
  String get takeaway => 'Zum Mitnehmen';

  @override
  String get kitchenBranch => 'Filiale';

  @override
  String get dashboard => 'Übersicht';

  @override
  String get orders => 'Bestellungen';

  @override
  String get menuManage => 'Speisekarte';

  @override
  String get tables => 'Tische';

  @override
  String get staff => 'Personal';

  @override
  String get inventory => 'Lager';

  @override
  String get finance => 'Finanzen';

  @override
  String get marketing => 'Marketing';

  @override
  String get settings => 'Einstellungen';

  @override
  String get revenue => 'Umsatz';

  @override
  String get ordersCount => 'Bestellungen';

  @override
  String get averageOrder => 'Durchschnittsbestellung';

  @override
  String get cancellationRate => 'Stornoquote';

  @override
  String get topProducts => 'Topseller';

  @override
  String get peakHours => 'Stoßzeiten';

  @override
  String get noDataYet => 'Noch keine Daten für diesen Zeitraum';

  @override
  String get registerCafe => 'Registriere dein Café';

  @override
  String get cafeName => 'Name des Cafés';

  @override
  String get legalName => 'Firmenname';

  @override
  String get country => 'Land';

  @override
  String get currency => 'Währung';

  @override
  String get timezone => 'Zeitzone';

  @override
  String get address => 'Adresse';

  @override
  String get city => 'Stadt';

  @override
  String get ownerName => 'Dein Name';

  @override
  String get pendingApproval =>
      'Dein Café wartet auf Freigabe. Du kannst es in der Zwischenzeit einrichten.';

  @override
  String get categories => 'Kategorien';

  @override
  String get products => 'Produkte';

  @override
  String get newCategory => 'Neue Kategorie';

  @override
  String get newProduct => 'Neues Produkt';

  @override
  String get price => 'Preis';

  @override
  String get category => 'Kategorie';

  @override
  String get tableNumber => 'Tischnummer';

  @override
  String get capacity => 'Plätze';

  @override
  String get qrCode => 'QR-Code';

  @override
  String get regenerateQr => 'QR neu erzeugen';

  @override
  String get inviteStaff => 'Personal einladen';

  @override
  String get role => 'Rolle';

  @override
  String get ingredients => 'Zutaten';

  @override
  String get suppliers => 'Lieferanten';

  @override
  String get stock => 'Bestand';

  @override
  String get unit => 'Einheit';

  @override
  String get unitCost => 'Stückkosten';

  @override
  String get stockIn => 'Wareneingang';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get sales => 'Verkäufe';

  @override
  String get profitLoss => 'Gewinn und Verlust';

  @override
  String get exportExcel => 'Excel-Export';

  @override
  String get exportPdf => 'PDF-Export';

  @override
  String get branding => 'Markenauftritt';

  @override
  String get primaryColor => 'Hauptfarbe';

  @override
  String get coupons => 'Gutscheine';

  @override
  String get code => 'Code';

  @override
  String get percent => 'Prozent';

  @override
  String get acceptOrder => 'Annehmen';

  @override
  String get markServed => 'Serviert';

  @override
  String get confirmCash => 'Barzahlung bestätigen';

  @override
  String get refund => 'Erstattung';

  @override
  String get netProfit => 'Nettogewinn';

  @override
  String get totalRevenue => 'Gesamteinnahmen';

  @override
  String get totalExpenses => 'Gesamtausgaben';

  @override
  String get invitationLink =>
      'Sende dieses Einladungstoken an deinen Mitarbeiter';

  @override
  String get cancelOrder => 'Bestellung stornieren';

  @override
  String get selectBranch => 'Filiale wählen';

  @override
  String get balance => 'Offener Betrag';

  @override
  String get customers => 'Kunden';

  @override
  String get reservations => 'Reservierungen';

  @override
  String get partySize => 'Personenzahl';

  @override
  String get support => 'Support';

  @override
  String get subject => 'Betreff';

  @override
  String get message => 'Nachricht';

  @override
  String get cafes => 'Cafés';

  @override
  String get approve => 'Freigeben';

  @override
  String get suspend => 'Sperren';

  @override
  String get activate => 'Aktivieren';

  @override
  String get plans => 'Tarife';

  @override
  String get auditLogs => 'Prüfprotokoll';

  @override
  String get health => 'Systemstatus';

  @override
  String get totalCafes => 'Cafés gesamt';

  @override
  String get activeCafes => 'Aktive Cafés';

  @override
  String get totalCustomers => 'Kunden';

  @override
  String get totalOrders => 'Bestellungen gesamt';

  @override
  String get enrollMfa => 'Zwei-Faktor-Anmeldung einrichten';

  @override
  String get mfaCode => '6-stelliger Code';

  @override
  String get mfaSecret =>
      'Füge diesen Schlüssel deiner Authenticator-App hinzu';

  @override
  String get grossByCurrency => 'Bruttoumsatz nach Währung';

  @override
  String get cafesByCountry => 'Cafés nach Land';

  @override
  String get activeSubscriptions => 'Aktive Abos';

  @override
  String get reasonPrompt =>
      'Gib einen Grund an. Er wird im Prüfprotokoll festgehalten.';

  @override
  String get action => 'Aktion';

  @override
  String get database => 'Datenbank';

  @override
  String get pendingCafes => 'Warten auf Freigabe';

  @override
  String get owner => 'Inhaber';

  @override
  String get stActive => 'Aktiv';

  @override
  String get stInactive => 'Inaktiv';

  @override
  String get stAvailable => 'Frei';

  @override
  String get stOccupied => 'Besetzt';

  @override
  String get stReserved => 'Reserviert';

  @override
  String get stCleaning => 'Reinigung';

  @override
  String get stSuspended => 'Gesperrt';

  @override
  String get stRejected => 'Abgelehnt';

  @override
  String get stClosed => 'Geschlossen';

  @override
  String get stOpen => 'Offen';

  @override
  String get stResolved => 'Gelöst';

  @override
  String get stInProgress => 'In Bearbeitung';

  @override
  String get stInvited => 'Eingeladen';

  @override
  String get roleManager => 'Leitung';

  @override
  String get roleCashier => 'Kassierer';

  @override
  String get roleWaiter => 'Bedienung';

  @override
  String get roleKitchen => 'Küchenpersonal';

  @override
  String get setPricesIncludeTax => 'Preise enthalten Steuern';

  @override
  String get setRequireAcceptance => 'Personal nimmt Bestellungen zuerst an';

  @override
  String get setGuestOrdering => 'QR-Bestellungen erlauben';

  @override
  String get setStockDeduction => 'Bestand nach Rezept abziehen';

  @override
  String get setPaymentPolicy => 'Wann Gäste zahlen';

  @override
  String get policyPrepay => 'Zahlung vor Zubereitung';

  @override
  String get policyPostpay => 'Zahlung nach dem Essen';

  @override
  String get layoutList => 'Liste';

  @override
  String get layoutGrid => 'Raster';

  @override
  String get layoutCompact => 'Kompakt';

  @override
  String get periodMonthly => 'Monatlich';

  @override
  String get periodYearly => 'Jährlich';

  @override
  String get healthCache => 'Cache';

  @override
  String get healthEvents => 'Wartende Ereignisse';

  @override
  String get healthWebhooks => 'Fehlgeschlagene Webhooks';

  @override
  String get phone => 'Telefon';

  @override
  String get notAvailable => 'Nicht zutreffend';

  @override
  String get plusTaxes => 'Steuern werden bei der Bestellung berechnet';

  @override
  String get variants => 'Varianten';

  @override
  String get addVariant => 'Variante hinzufügen';

  @override
  String get addExtras => 'Extras hinzufügen';

  @override
  String get optionName => 'Optionsname';

  @override
  String get uploadImage => 'Bild hochladen';

  @override
  String get uploadLogo => 'Logo hochladen';

  @override
  String get uploadCover => 'Titelbild hochladen';

  @override
  String get banners => 'Banner';

  @override
  String get bannerTitle => 'Bannertitel';

  @override
  String get branches => 'Filialen';

  @override
  String get addBranch => 'Filiale hinzufügen';

  @override
  String get branchCode => 'Filialcode';

  @override
  String get businessHours => 'Öffnungszeiten';

  @override
  String get opensAt => 'Öffnet';

  @override
  String get closesAt => 'Schließt';

  @override
  String get supportedLanguages => 'Kundensprachen';

  @override
  String get gatewaySetup => 'Zahlungsanbieter';

  @override
  String get provider => 'Anbieter';

  @override
  String get environment => 'Modus';

  @override
  String get apiKeyId => 'API-Schlüssel-ID';

  @override
  String get apiKeySecret => 'API-Geheimnis';

  @override
  String get webhookSecret => 'Webhook-Geheimnis';

  @override
  String get webhookUrl => 'Webhook-URL (bei deinem Anbieter eintragen)';

  @override
  String get paymentMethods => 'Zahlungsarten';

  @override
  String get subscription => 'Abonnement';

  @override
  String get choosePlan => 'Tarif wählen';

  @override
  String get cancelSubscription => 'Abo kündigen';

  @override
  String get splitBill => 'Rechnung teilen';

  @override
  String get numberOfParts => 'Anzahl der Teile';

  @override
  String get transferTable => 'An Tisch verlegen';

  @override
  String get recipe => 'Rezept';

  @override
  String get purchaseOrders => 'Bestellungen beim Lieferanten';

  @override
  String get newPurchaseOrder => 'Neue Lieferantenbestellung';

  @override
  String get receiveGoods => 'Ware annehmen';

  @override
  String get supplierInvoices => 'Lieferantenrechnungen';

  @override
  String get invoiceNumber => 'Rechnungsnummer';

  @override
  String get recordPayment => 'Zahlung erfassen';

  @override
  String get expiringStock => 'Bald ablaufender Bestand';

  @override
  String get trialBalance => 'Saldenliste';

  @override
  String get debit => 'Soll';

  @override
  String get credit => 'Haben';

  @override
  String get balanceSheet => 'Bilanz';

  @override
  String get assets => 'Aktiva';

  @override
  String get liabilities => 'Verbindlichkeiten';

  @override
  String get equity => 'Eigenkapital';

  @override
  String get journal => 'Journal';

  @override
  String get reverse => 'Stornieren';

  @override
  String get periods => 'Perioden';

  @override
  String get closePeriod => 'Periode abschließen';

  @override
  String get cashRegisters => 'Kassen';

  @override
  String get openRegister => 'Kasse öffnen';

  @override
  String get closeRegister => 'Kasse schließen';

  @override
  String get openingFloat => 'Anfangsbestand';

  @override
  String get countedCash => 'Gezähltes Bargeld';

  @override
  String get expectedCash => 'Erwartetes Bargeld';

  @override
  String get variance => 'Differenz';

  @override
  String get payroll => 'Lohnabrechnung';

  @override
  String get grossPay => 'Bruttolohn';

  @override
  String get deductions => 'Abzüge';

  @override
  String get markPaid => 'Als bezahlt markieren';

  @override
  String get attendance => 'Anwesenheit';

  @override
  String get clockIn => 'Einstempeln';

  @override
  String get clockOut => 'Ausstempeln';

  @override
  String get clockedIn => 'Erledigt';

  @override
  String get promotions => 'Aktionen';

  @override
  String get loyalty => 'Treueprogramm';

  @override
  String get pointsPerUnit => 'Punkte pro Währungseinheit';

  @override
  String get valuePerPoint => 'Wert eines Punkts';

  @override
  String get reply => 'Antworten';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get stations => 'Küchenstationen';

  @override
  String get routeToStation => 'An Station senden';

  @override
  String get users => 'Benutzer';

  @override
  String get disable => 'Deaktivieren';

  @override
  String get translations => 'Übersetzungen';

  @override
  String get translationKey => 'Schlüssel';

  @override
  String get translationValue => 'Text';

  @override
  String get countries => 'Länder';

  @override
  String get commissions => 'Provisionen';

  @override
  String get announcements => 'Ankündigungen';

  @override
  String get bodyText => 'Nachrichtentext';

  @override
  String get addresses => 'Gespeicherte Adressen';

  @override
  String get addressLabel => 'Bezeichnung';

  @override
  String get completedOrders => 'Abgeschlossene Bestellungen';

  @override
  String get chooseCafe => 'Café wählen';

  @override
  String get reserveTable => 'Tisch reservieren';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get payments => 'Zahlungen';

  @override
  String get refunds => 'Erstattungen';

  @override
  String get settlements => 'Auszahlungen';

  @override
  String get syncSettlements => 'Auszahlungen abrufen';

  @override
  String get paymentLink => 'Zahlungslink';

  @override
  String get createPaymentLink => 'Zahlungslink erstellen';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get connectionOk => 'Verbunden. Onlinezahlungen sind aktiv.';

  @override
  String get connectionFailed => 'Der Anbieter hat diese Schlüssel abgelehnt.';

  @override
  String get payPart => 'Teil der Rechnung zahlen';

  @override
  String get amountToPay => 'Zu zahlender Betrag';

  @override
  String get paymentSuccessful => 'Zahlung erhalten. Danke!';

  @override
  String get paymentNotCompleted =>
      'Die Zahlung wurde nicht abgeschlossen. Dieser Versuch wurde nicht berechnet.';

  @override
  String get payOnline => 'Online bezahlen';

  @override
  String get gatewayFee => 'Anbietergebühr';

  @override
  String get referenceLabel => 'Referenz';

  @override
  String get paymentBreakdown => 'Zahlungsübersicht';

  @override
  String get approveRefund => 'Erstattung genehmigen';

  @override
  String get refundRequested =>
      'Erstattung beantragt. Die Leitung muss sie genehmigen.';

  @override
  String get reconciled => 'Abgeglichen';

  @override
  String get needsReview => 'Prüfung nötig';

  @override
  String get pendingKeys =>
      'Gespeichert. Teste die Verbindung, um Onlinezahlungen zu aktivieren.';

  @override
  String get openingCheckout => 'Sichere Zahlung wird geöffnet…';
}
