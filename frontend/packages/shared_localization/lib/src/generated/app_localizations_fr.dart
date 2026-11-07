// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get add => 'Ajouter';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get search => 'Rechercher';

  @override
  String get close => 'Fermer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get emptyTitle => 'Rien ici pour le moment';

  @override
  String get errorTitle => 'Une erreur s\'est produite';

  @override
  String get networkError =>
      'Impossible de joindre le serveur. Vérifiez votre connexion.';

  @override
  String get invalidCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get accountLocked => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String get rateLimited => 'Trop de requêtes. Veuillez patienter.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get name => 'Nom';

  @override
  String get language => 'Langue';

  @override
  String get requiredField => 'Obligatoire';

  @override
  String get invalidValue => 'Valeur non valide';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get discount => 'Remise';

  @override
  String get tax => 'Taxe';

  @override
  String get serviceCharge => 'Frais de service';

  @override
  String get status => 'Statut';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Montant';

  @override
  String get quantity => 'Quantité';

  @override
  String get notes => 'Notes';

  @override
  String get reason => 'Motif';

  @override
  String get refresh => 'Actualiser';

  @override
  String welcomeTable(String table) {
    return 'Table $table';
  }

  @override
  String get menu => 'Menu';

  @override
  String get cart => 'Panier';

  @override
  String get addToCart => 'Ajouter au panier';

  @override
  String get viewCart => 'Voir le panier';

  @override
  String get emptyCart => 'Votre panier est vide';

  @override
  String get chooseOption => 'Choisissez une option';

  @override
  String get extras => 'Suppléments';

  @override
  String get specialInstructions => 'Instructions particulières';

  @override
  String get placeOrder => 'Commander';

  @override
  String get orderPlaced => 'Commande passée';

  @override
  String orderNumber(int number) {
    return 'Commande n° $number';
  }

  @override
  String get trackOrder => 'Suivre la commande';

  @override
  String get payNow => 'Payer maintenant';

  @override
  String get payAtCounter => 'Payer au comptoir';

  @override
  String get onlinePaymentUnavailable =>
      'Le paiement en ligne n\'est pas encore disponible ici. Veuillez payer au comptoir.';

  @override
  String get paymentPending => 'En attente de confirmation du paiement';

  @override
  String get receipt => 'Reçu';

  @override
  String get rateUs => 'Évaluez votre expérience';

  @override
  String get submit => 'Envoyer';

  @override
  String get thanks => 'Merci !';

  @override
  String get callWaiter => 'Appeler le serveur';

  @override
  String get requestBill => 'Demander l\'addition';

  @override
  String get callStaff => 'Appeler le personnel';

  @override
  String get requestSent => 'Demande envoyée. Le personnel a été prévenu.';

  @override
  String get favorites => 'Favoris';

  @override
  String get wishlist => 'Liste de souhaits';

  @override
  String get recentlyOrdered => 'Commandés récemment';

  @override
  String get coupon => 'Code promo';

  @override
  String get apply => 'Appliquer';

  @override
  String get couponInvalid => 'Ce code ne peut pas être utilisé';

  @override
  String get veg => 'Végétarien';

  @override
  String get nonVeg => 'Non végétarien';

  @override
  String get egg => 'Œuf';

  @override
  String get vegan => 'Végan';

  @override
  String get outOfStock => 'Épuisé';

  @override
  String get myOrders => 'Mes commandes';

  @override
  String get profile => 'Profil';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get offers => 'Offres';

  @override
  String get qrInvalid =>
      'Ce code QR n\'est plus valide. Veuillez demander au personnel.';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get allCategories => 'Tout';

  @override
  String get statusPendingPayment => 'En attente de paiement';

  @override
  String get statusPlaced => 'Nouvelle';

  @override
  String get statusAccepted => 'Acceptée';

  @override
  String get statusPreparing => 'En préparation';

  @override
  String get statusReady => 'Prête';

  @override
  String get statusServed => 'Servie';

  @override
  String get statusCompleted => 'Terminée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get payUnpaid => 'Non payée';

  @override
  String get payPartial => 'Payée en partie';

  @override
  String get payPaid => 'Payée';

  @override
  String get payPartRefund => 'Remboursée en partie';

  @override
  String get payRefunded => 'Remboursée';

  @override
  String get kitchenNew => 'Nouvelles';

  @override
  String get kitchenInProgress => 'En cours';

  @override
  String get kitchenReady => 'Prêtes';

  @override
  String get accept => 'Accepter';

  @override
  String get startPreparing => 'Commencer';

  @override
  String get markReady => 'Prête';

  @override
  String get complete => 'Terminer';

  @override
  String get delayed => 'En retard';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get priority => 'Priorité';

  @override
  String get allStations => 'Tous les postes';

  @override
  String get noTickets => 'Aucune commande pour le moment';

  @override
  String get connectionLost => 'Connexion perdue. Reconnexion…';

  @override
  String get takeaway => 'À emporter';

  @override
  String get kitchenBranch => 'Établissement';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get orders => 'Commandes';

  @override
  String get menuManage => 'Carte';

  @override
  String get tables => 'Tables';

  @override
  String get staff => 'Personnel';

  @override
  String get inventory => 'Stocks';

  @override
  String get finance => 'Finances';

  @override
  String get marketing => 'Marketing';

  @override
  String get settings => 'Réglages';

  @override
  String get revenue => 'Chiffre d\'affaires';

  @override
  String get ordersCount => 'Commandes';

  @override
  String get averageOrder => 'Commande moyenne';

  @override
  String get cancellationRate => 'Taux d\'annulation';

  @override
  String get topProducts => 'Meilleures ventes';

  @override
  String get peakHours => 'Heures de pointe';

  @override
  String get noDataYet => 'Aucune donnée pour cette période';

  @override
  String get registerCafe => 'Inscrivez votre café';

  @override
  String get cafeName => 'Nom du café';

  @override
  String get legalName => 'Raison sociale';

  @override
  String get country => 'Pays';

  @override
  String get currency => 'Devise';

  @override
  String get timezone => 'Fuseau horaire';

  @override
  String get address => 'Adresse';

  @override
  String get city => 'Ville';

  @override
  String get ownerName => 'Votre nom';

  @override
  String get pendingApproval =>
      'Votre café est en attente d\'approbation. Vous pouvez le configurer en attendant.';

  @override
  String get categories => 'Catégories';

  @override
  String get products => 'Produits';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String get newProduct => 'Nouveau produit';

  @override
  String get price => 'Prix';

  @override
  String get category => 'Catégorie';

  @override
  String get tableNumber => 'Numéro de table';

  @override
  String get capacity => 'Capacité';

  @override
  String get qrCode => 'Code QR';

  @override
  String get regenerateQr => 'Régénérer le QR';

  @override
  String get inviteStaff => 'Inviter du personnel';

  @override
  String get role => 'Rôle';

  @override
  String get ingredients => 'Ingrédients';

  @override
  String get suppliers => 'Fournisseurs';

  @override
  String get stock => 'Stock';

  @override
  String get unit => 'Unité';

  @override
  String get unitCost => 'Coût unitaire';

  @override
  String get stockIn => 'Entrée de stock';

  @override
  String get expenses => 'Dépenses';

  @override
  String get sales => 'Ventes';

  @override
  String get profitLoss => 'Compte de résultat';

  @override
  String get exportExcel => 'Exporter Excel';

  @override
  String get exportPdf => 'Exporter PDF';

  @override
  String get branding => 'Image de marque';

  @override
  String get primaryColor => 'Couleur principale';

  @override
  String get coupons => 'Codes promo';

  @override
  String get code => 'Code';

  @override
  String get percent => 'Pourcentage';

  @override
  String get acceptOrder => 'Accepter';

  @override
  String get markServed => 'Servie';

  @override
  String get confirmCash => 'Confirmer l\'espèce';

  @override
  String get refund => 'Remboursement';

  @override
  String get netProfit => 'Bénéfice net';

  @override
  String get totalRevenue => 'Total des recettes';

  @override
  String get totalExpenses => 'Total des dépenses';

  @override
  String get invitationLink => 'Envoyez ce jeton d\'invitation à votre employé';

  @override
  String get cancelOrder => 'Annuler la commande';

  @override
  String get selectBranch => 'Choisir l\'établissement';

  @override
  String get balance => 'Solde dû';

  @override
  String get customers => 'Clients';

  @override
  String get reservations => 'Réservations';

  @override
  String get partySize => 'Couverts';

  @override
  String get support => 'Assistance';

  @override
  String get subject => 'Objet';

  @override
  String get message => 'Message';

  @override
  String get cafes => 'Cafés';

  @override
  String get approve => 'Approuver';

  @override
  String get suspend => 'Suspendre';

  @override
  String get activate => 'Activer';

  @override
  String get plans => 'Formules';

  @override
  String get auditLogs => 'Journal d\'audit';

  @override
  String get health => 'État du système';

  @override
  String get totalCafes => 'Total des cafés';

  @override
  String get activeCafes => 'Cafés actifs';

  @override
  String get totalCustomers => 'Clients';

  @override
  String get totalOrders => 'Total des commandes';

  @override
  String get enrollMfa => 'Configurer la connexion à deux facteurs';

  @override
  String get mfaCode => 'Code à 6 chiffres';

  @override
  String get mfaSecret =>
      'Ajoutez cette clé à votre application d\'authentification';

  @override
  String get grossByCurrency => 'Ventes brutes par devise';

  @override
  String get cafesByCountry => 'Cafés par pays';

  @override
  String get activeSubscriptions => 'Abonnements actifs';

  @override
  String get reasonPrompt =>
      'Indiquez un motif. Il sera inscrit au journal d\'audit.';

  @override
  String get action => 'Action';

  @override
  String get database => 'Base de données';

  @override
  String get pendingCafes => 'En attente d\'approbation';

  @override
  String get owner => 'Propriétaire';

  @override
  String get stActive => 'Actif';

  @override
  String get stInactive => 'Inactif';

  @override
  String get stAvailable => 'Disponible';

  @override
  String get stOccupied => 'Occupée';

  @override
  String get stReserved => 'Réservée';

  @override
  String get stCleaning => 'Nettoyage';

  @override
  String get stSuspended => 'Suspendu';

  @override
  String get stRejected => 'Refusé';

  @override
  String get stClosed => 'Fermé';

  @override
  String get stOpen => 'Ouvert';

  @override
  String get stResolved => 'Résolu';

  @override
  String get stInProgress => 'En cours';

  @override
  String get stInvited => 'Invité';

  @override
  String get roleManager => 'Responsable';

  @override
  String get roleCashier => 'Caissier';

  @override
  String get roleWaiter => 'Serveur';

  @override
  String get roleKitchen => 'Personnel de cuisine';

  @override
  String get setPricesIncludeTax => 'Les prix incluent les taxes';

  @override
  String get setRequireAcceptance =>
      'Le personnel accepte d\'abord les commandes';

  @override
  String get setGuestOrdering => 'Autoriser les commandes par QR';

  @override
  String get setStockDeduction => 'Déduire le stock selon les recettes';

  @override
  String get setPaymentPolicy => 'Quand les clients paient';

  @override
  String get policyPrepay => 'Paiement avant préparation';

  @override
  String get policyPostpay => 'Paiement après le repas';

  @override
  String get layoutList => 'Liste';

  @override
  String get layoutGrid => 'Grille';

  @override
  String get layoutCompact => 'Compact';

  @override
  String get periodMonthly => 'Mensuel';

  @override
  String get periodYearly => 'Annuel';

  @override
  String get healthCache => 'Cache';

  @override
  String get healthEvents => 'Événements en attente';

  @override
  String get healthWebhooks => 'Webhooks en échec';

  @override
  String get phone => 'Téléphone';

  @override
  String get notAvailable => 'Sans objet';

  @override
  String get plusTaxes => 'Les taxes sont calculées à la commande';

  @override
  String get variants => 'Variantes';

  @override
  String get addVariant => 'Ajouter une variante';

  @override
  String get addExtras => 'Ajouter des suppléments';

  @override
  String get optionName => 'Nom de l\'option';

  @override
  String get uploadImage => 'Importer une image';

  @override
  String get uploadLogo => 'Importer le logo';

  @override
  String get uploadCover => 'Importer la couverture';

  @override
  String get banners => 'Bannières';

  @override
  String get bannerTitle => 'Titre de la bannière';

  @override
  String get branches => 'Établissements';

  @override
  String get addBranch => 'Ajouter un établissement';

  @override
  String get branchCode => 'Code de l\'établissement';

  @override
  String get businessHours => 'Horaires';

  @override
  String get opensAt => 'Ouverture';

  @override
  String get closesAt => 'Fermeture';

  @override
  String get supportedLanguages => 'Langues clients';

  @override
  String get gatewaySetup => 'Passerelle de paiement';

  @override
  String get provider => 'Fournisseur';

  @override
  String get environment => 'Mode';

  @override
  String get apiKeyId => 'ID de clé API';

  @override
  String get apiKeySecret => 'Secret API';

  @override
  String get webhookSecret => 'Secret du webhook';

  @override
  String get webhookUrl => 'URL du webhook (à ajouter dans votre passerelle)';

  @override
  String get paymentMethods => 'Moyens de paiement';

  @override
  String get subscription => 'Abonnement';

  @override
  String get choosePlan => 'Choisir une formule';

  @override
  String get cancelSubscription => 'Résilier l\'abonnement';

  @override
  String get splitBill => 'Partager l\'addition';

  @override
  String get numberOfParts => 'Nombre de parts';

  @override
  String get transferTable => 'Déplacer vers une table';

  @override
  String get recipe => 'Recette';

  @override
  String get purchaseOrders => 'Bons de commande';

  @override
  String get newPurchaseOrder => 'Nouveau bon de commande';

  @override
  String get receiveGoods => 'Réceptionner';

  @override
  String get supplierInvoices => 'Factures fournisseurs';

  @override
  String get invoiceNumber => 'Numéro de facture';

  @override
  String get recordPayment => 'Enregistrer un paiement';

  @override
  String get expiringStock => 'Stock bientôt périmé';

  @override
  String get trialBalance => 'Balance comptable';

  @override
  String get debit => 'Débit';

  @override
  String get credit => 'Crédit';

  @override
  String get balanceSheet => 'Bilan';

  @override
  String get assets => 'Actifs';

  @override
  String get liabilities => 'Passifs';

  @override
  String get equity => 'Capitaux propres';

  @override
  String get journal => 'Journal';

  @override
  String get reverse => 'Contre-passer';

  @override
  String get periods => 'Périodes';

  @override
  String get closePeriod => 'Clôturer la période';

  @override
  String get cashRegisters => 'Caisses';

  @override
  String get openRegister => 'Ouvrir la caisse';

  @override
  String get closeRegister => 'Fermer la caisse';

  @override
  String get openingFloat => 'Fond de caisse';

  @override
  String get countedCash => 'Espèces comptées';

  @override
  String get expectedCash => 'Espèces attendues';

  @override
  String get variance => 'Écart';

  @override
  String get payroll => 'Paie';

  @override
  String get grossPay => 'Salaire brut';

  @override
  String get deductions => 'Retenues';

  @override
  String get markPaid => 'Marquer payé';

  @override
  String get attendance => 'Présence';

  @override
  String get clockIn => 'Pointer l\'arrivée';

  @override
  String get clockOut => 'Pointer le départ';

  @override
  String get clockedIn => 'Fait';

  @override
  String get promotions => 'Promotions';

  @override
  String get loyalty => 'Fidélité';

  @override
  String get pointsPerUnit => 'Points par unité monétaire';

  @override
  String get valuePerPoint => 'Valeur d\'un point';

  @override
  String get reply => 'Répondre';

  @override
  String get notifications => 'Notifications';

  @override
  String get stations => 'Postes de cuisine';

  @override
  String get routeToStation => 'Envoyer au poste';

  @override
  String get users => 'Utilisateurs';

  @override
  String get disable => 'Désactiver';

  @override
  String get translations => 'Traductions';

  @override
  String get translationKey => 'Clé';

  @override
  String get translationValue => 'Texte';

  @override
  String get countries => 'Pays';

  @override
  String get commissions => 'Commissions';

  @override
  String get announcements => 'Annonces';

  @override
  String get bodyText => 'Texte du message';

  @override
  String get addresses => 'Adresses enregistrées';

  @override
  String get addressLabel => 'Libellé';

  @override
  String get completedOrders => 'Commandes terminées';

  @override
  String get chooseCafe => 'Choisir un café';

  @override
  String get reserveTable => 'Réserver une table';

  @override
  String get tomorrow => 'Demain';

  @override
  String get payments => 'Paiements';

  @override
  String get refunds => 'Remboursements';

  @override
  String get settlements => 'Règlements';

  @override
  String get syncSettlements => 'Récupérer les règlements';

  @override
  String get paymentLink => 'Lien de paiement';

  @override
  String get createPaymentLink => 'Créer un lien de paiement';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get connectionOk => 'Connecté. Les paiements en ligne sont actifs.';

  @override
  String get connectionFailed => 'La passerelle a refusé ces clés.';

  @override
  String get payPart => 'Payer une partie de l\'addition';

  @override
  String get amountToPay => 'Montant à payer';

  @override
  String get paymentSuccessful => 'Paiement reçu. Merci !';

  @override
  String get paymentNotCompleted =>
      'Le paiement n\'a pas abouti. Cette tentative ne vous a pas été facturée.';

  @override
  String get payOnline => 'Payer en ligne';

  @override
  String get gatewayFee => 'Frais de passerelle';

  @override
  String get referenceLabel => 'Référence';

  @override
  String get paymentBreakdown => 'Résumé des paiements';

  @override
  String get approveRefund => 'Approuver le remboursement';

  @override
  String get refundRequested =>
      'Remboursement demandé. Un responsable doit l\'approuver.';

  @override
  String get reconciled => 'Rapproché';

  @override
  String get needsReview => 'À vérifier';

  @override
  String get pendingKeys =>
      'Enregistré. Testez la connexion pour activer les paiements en ligne.';

  @override
  String get openingCheckout => 'Ouverture du paiement sécurisé…';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get revenueTrend => 'Revenus par jour';

  @override
  String get recentOrders => 'Commandes récentes';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get removePhoto => 'Retirer la photo';

  @override
  String get filterAll => 'Tout';

  @override
  String get available => 'Disponible';

  @override
  String get loginTagline =>
      'Gérez votre café avec élégance, depuis un seul endroit.';

  @override
  String get signInSubtitle => 'Connectez-vous pour continuer';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get back => 'Retour';

  @override
  String get adminConsole => 'Console de la plateforme';

  @override
  String get adminLoginTagline =>
      'Tous les cafés de la plateforme, en un coup d\'œil.';

  @override
  String get kitchenDisplay => 'Écran cuisine';

  @override
  String get kitchenLoginTagline =>
      'Chaque ticket lisible d\'un bout à l\'autre de la cuisine.';

  @override
  String get customerLoginTagline =>
      'Enregistrez vos favoris, suivez vos commandes et gagnez des récompenses.';

  @override
  String get signInToOrder => 'Connectez-vous pour commander';

  @override
  String get signInToOrderHint =>
      'Parcourez librement. Pour commander, connectez-vous ou créez un compte.';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get markAvailable => 'Marquer comme libre';

  @override
  String get tableReleased => 'La table est maintenant libre';

  @override
  String get tableHasUnpaid =>
      'Cette table a encore des commandes impayées. Réglez d\'abord l\'addition.';

  @override
  String unpaidForMinutes(int minutes) {
    return 'Impayée depuis $minutes min';
  }

  @override
  String tablePin(String pin) {
    return 'PIN $pin';
  }

  @override
  String get enterTablePin => 'Saisissez le PIN de la table';

  @override
  String get tablePinHint =>
      'Demandez au personnel le PIN à 4 chiffres de votre table.';

  @override
  String get tablePinWrong =>
      'Ce PIN ne correspond pas. Vérifiez auprès du personnel.';

  @override
  String get setTablePin =>
      'Demander un PIN de table aux clients avant de commander';

  @override
  String get setSessionEndAfterPayment =>
      'Fermer la session de table ce délai après le paiement';

  @override
  String get setUnpaidAlert =>
      'Prévenir le personnel des commandes encore impayées après';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPassword => 'Définir un nouveau mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get passwordResetDone =>
      'Mot de passe modifié. Vous pouvez vous connecter.';

  @override
  String get resetLinkInvalid => 'Ce lien a expiré ou a déjà été utilisé.';

  @override
  String get passwordResetUnavailable =>
      'La réinitialisation du mot de passe n\'est pas encore disponible.';

  @override
  String get minutesUnit => 'min';

  @override
  String get resetLinkSent =>
      'Si cette adresse a un compte, un lien est en route.';

  @override
  String countsForDay(String date) {
    return 'compte pour le $date';
  }
}
