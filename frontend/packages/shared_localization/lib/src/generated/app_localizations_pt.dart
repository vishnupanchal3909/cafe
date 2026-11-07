// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get retry => 'Tentar novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Adicionar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get search => 'Pesquisar';

  @override
  String get close => 'Fechar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get emptyTitle => 'Ainda não há nada aqui';

  @override
  String get errorTitle => 'Algo correu mal';

  @override
  String get networkError =>
      'Não é possível contactar o servidor. Verifique a ligação.';

  @override
  String get invalidCredentials => 'E-mail ou palavra-passe incorretos.';

  @override
  String get accountLocked => 'Demasiadas tentativas. Tente mais tarde.';

  @override
  String get rateLimited => 'Demasiados pedidos. Aguarde um momento.';

  @override
  String get signIn => 'Iniciar sessão';

  @override
  String get signOut => 'Terminar sessão';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Palavra-passe';

  @override
  String get name => 'Nome';

  @override
  String get language => 'Idioma';

  @override
  String get requiredField => 'Obrigatório';

  @override
  String get invalidValue => 'Valor inválido';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Desconto';

  @override
  String get tax => 'Imposto';

  @override
  String get serviceCharge => 'Taxa de serviço';

  @override
  String get status => 'Estado';

  @override
  String get date => 'Data';

  @override
  String get amount => 'Montante';

  @override
  String get quantity => 'Quantidade';

  @override
  String get notes => 'Notas';

  @override
  String get reason => 'Motivo';

  @override
  String get refresh => 'Atualizar';

  @override
  String welcomeTable(String table) {
    return 'Mesa $table';
  }

  @override
  String get menu => 'Menu';

  @override
  String get cart => 'Carrinho';

  @override
  String get addToCart => 'Adicionar ao carrinho';

  @override
  String get viewCart => 'Ver carrinho';

  @override
  String get emptyCart => 'O seu carrinho está vazio';

  @override
  String get chooseOption => 'Escolha uma opção';

  @override
  String get extras => 'Extras';

  @override
  String get specialInstructions => 'Instruções especiais';

  @override
  String get placeOrder => 'Fazer pedido';

  @override
  String get orderPlaced => 'Pedido feito';

  @override
  String orderNumber(int number) {
    return 'Pedido #$number';
  }

  @override
  String get trackOrder => 'Acompanhar pedido';

  @override
  String get payNow => 'Pagar agora';

  @override
  String get payAtCounter => 'Pagar no balcão';

  @override
  String get onlinePaymentUnavailable =>
      'O pagamento online ainda não está disponível aqui. Pague no balcão.';

  @override
  String get paymentPending => 'A aguardar confirmação do pagamento';

  @override
  String get receipt => 'Recibo';

  @override
  String get rateUs => 'Avalie a sua experiência';

  @override
  String get submit => 'Enviar';

  @override
  String get thanks => 'Obrigado!';

  @override
  String get callWaiter => 'Chamar empregado';

  @override
  String get requestBill => 'Pedir a conta';

  @override
  String get callStaff => 'Chamar funcionários';

  @override
  String get requestSent => 'Pedido enviado. Os funcionários foram avisados.';

  @override
  String get favorites => 'Favoritos';

  @override
  String get wishlist => 'Lista de desejos';

  @override
  String get recentlyOrdered => 'Pedidos recentes';

  @override
  String get coupon => 'Código de cupão';

  @override
  String get apply => 'Aplicar';

  @override
  String get couponInvalid => 'Este cupão não pode ser usado';

  @override
  String get veg => 'Vegetariano';

  @override
  String get nonVeg => 'Não vegetariano';

  @override
  String get egg => 'Ovo';

  @override
  String get vegan => 'Vegano';

  @override
  String get outOfStock => 'Esgotado';

  @override
  String get myOrders => 'Os meus pedidos';

  @override
  String get profile => 'Perfil';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get offers => 'Ofertas';

  @override
  String get qrInvalid =>
      'Este código QR já não é válido. Pergunte a um funcionário.';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get allCategories => 'Tudo';

  @override
  String get statusPendingPayment => 'A aguardar pagamento';

  @override
  String get statusPlaced => 'Novo';

  @override
  String get statusAccepted => 'Aceite';

  @override
  String get statusPreparing => 'Em preparação';

  @override
  String get statusReady => 'Pronto';

  @override
  String get statusServed => 'Servido';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get payUnpaid => 'Por pagar';

  @override
  String get payPartial => 'Pago em parte';

  @override
  String get payPaid => 'Pago';

  @override
  String get payPartRefund => 'Reembolsado em parte';

  @override
  String get payRefunded => 'Reembolsado';

  @override
  String get kitchenNew => 'Novos';

  @override
  String get kitchenInProgress => 'Em curso';

  @override
  String get kitchenReady => 'Prontos';

  @override
  String get accept => 'Aceitar';

  @override
  String get startPreparing => 'Iniciar';

  @override
  String get markReady => 'Pronto';

  @override
  String get complete => 'Concluir';

  @override
  String get delayed => 'Atrasado';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get priority => 'Prioridade';

  @override
  String get allStations => 'Todas as estações';

  @override
  String get noTickets => 'Sem pedidos de momento';

  @override
  String get connectionLost => 'Ligação perdida. A religar…';

  @override
  String get takeaway => 'Para levar';

  @override
  String get kitchenBranch => 'Filial';

  @override
  String get dashboard => 'Painel';

  @override
  String get orders => 'Pedidos';

  @override
  String get menuManage => 'Menu';

  @override
  String get tables => 'Mesas';

  @override
  String get staff => 'Funcionários';

  @override
  String get inventory => 'Inventário';

  @override
  String get finance => 'Finanças';

  @override
  String get marketing => 'Marketing';

  @override
  String get settings => 'Definições';

  @override
  String get revenue => 'Receita';

  @override
  String get ordersCount => 'Pedidos';

  @override
  String get averageOrder => 'Pedido médio';

  @override
  String get cancellationRate => 'Taxa de cancelamento';

  @override
  String get topProducts => 'Mais vendidos';

  @override
  String get peakHours => 'Horas de ponta';

  @override
  String get noDataYet => 'Ainda sem dados neste período';

  @override
  String get registerCafe => 'Registe o seu café';

  @override
  String get cafeName => 'Nome do café';

  @override
  String get legalName => 'Denominação legal';

  @override
  String get country => 'País';

  @override
  String get currency => 'Moeda';

  @override
  String get timezone => 'Fuso horário';

  @override
  String get address => 'Morada';

  @override
  String get city => 'Cidade';

  @override
  String get ownerName => 'O seu nome';

  @override
  String get pendingApproval =>
      'O seu café aguarda aprovação. Entretanto pode configurá-lo.';

  @override
  String get categories => 'Categorias';

  @override
  String get products => 'Produtos';

  @override
  String get newCategory => 'Nova categoria';

  @override
  String get newProduct => 'Novo produto';

  @override
  String get price => 'Preço';

  @override
  String get category => 'Categoria';

  @override
  String get tableNumber => 'Número da mesa';

  @override
  String get capacity => 'Capacidade';

  @override
  String get qrCode => 'Código QR';

  @override
  String get regenerateQr => 'Regenerar QR';

  @override
  String get inviteStaff => 'Convidar funcionário';

  @override
  String get role => 'Função';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get suppliers => 'Fornecedores';

  @override
  String get stock => 'Stock';

  @override
  String get unit => 'Unidade';

  @override
  String get unitCost => 'Custo unitário';

  @override
  String get stockIn => 'Entrada de stock';

  @override
  String get expenses => 'Despesas';

  @override
  String get sales => 'Vendas';

  @override
  String get profitLoss => 'Lucros e perdas';

  @override
  String get exportExcel => 'Exportar Excel';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get branding => 'Marca';

  @override
  String get primaryColor => 'Cor principal';

  @override
  String get coupons => 'Cupões';

  @override
  String get code => 'Código';

  @override
  String get percent => 'Percentagem';

  @override
  String get acceptOrder => 'Aceitar';

  @override
  String get markServed => 'Servido';

  @override
  String get confirmCash => 'Confirmar numerário';

  @override
  String get refund => 'Reembolso';

  @override
  String get netProfit => 'Lucro líquido';

  @override
  String get totalRevenue => 'Receita total';

  @override
  String get totalExpenses => 'Despesas totais';

  @override
  String get invitationLink => 'Envie este token de convite ao seu funcionário';

  @override
  String get cancelOrder => 'Cancelar pedido';

  @override
  String get selectBranch => 'Selecionar filial';

  @override
  String get balance => 'Saldo em dívida';

  @override
  String get customers => 'Clientes';

  @override
  String get reservations => 'Reservas';

  @override
  String get partySize => 'Número de pessoas';

  @override
  String get support => 'Apoio';

  @override
  String get subject => 'Assunto';

  @override
  String get message => 'Mensagem';

  @override
  String get cafes => 'Cafés';

  @override
  String get approve => 'Aprovar';

  @override
  String get suspend => 'Suspender';

  @override
  String get activate => 'Ativar';

  @override
  String get plans => 'Planos';

  @override
  String get auditLogs => 'Registos de auditoria';

  @override
  String get health => 'Estado do sistema';

  @override
  String get totalCafes => 'Total de cafés';

  @override
  String get activeCafes => 'Cafés ativos';

  @override
  String get totalCustomers => 'Clientes';

  @override
  String get totalOrders => 'Total de pedidos';

  @override
  String get enrollMfa => 'Configurar início de sessão em dois passos';

  @override
  String get mfaCode => 'Código de 6 dígitos';

  @override
  String get mfaSecret => 'Adicione esta chave à sua app de autenticação';

  @override
  String get grossByCurrency => 'Vendas brutas por moeda';

  @override
  String get cafesByCountry => 'Cafés por país';

  @override
  String get activeSubscriptions => 'Subscrições ativas';

  @override
  String get reasonPrompt => 'Indique um motivo. Fica registado na auditoria.';

  @override
  String get action => 'Ação';

  @override
  String get database => 'Base de dados';

  @override
  String get pendingCafes => 'A aguardar aprovação';

  @override
  String get owner => 'Proprietário';

  @override
  String get stActive => 'Ativo';

  @override
  String get stInactive => 'Inativo';

  @override
  String get stAvailable => 'Disponível';

  @override
  String get stOccupied => 'Ocupada';

  @override
  String get stReserved => 'Reservada';

  @override
  String get stCleaning => 'Em limpeza';

  @override
  String get stSuspended => 'Suspenso';

  @override
  String get stRejected => 'Rejeitado';

  @override
  String get stClosed => 'Fechado';

  @override
  String get stOpen => 'Aberto';

  @override
  String get stResolved => 'Resolvido';

  @override
  String get stInProgress => 'Em curso';

  @override
  String get stInvited => 'Convidado';

  @override
  String get roleManager => 'Gerente';

  @override
  String get roleCashier => 'Caixa';

  @override
  String get roleWaiter => 'Empregado de mesa';

  @override
  String get roleKitchen => 'Pessoal de cozinha';

  @override
  String get setPricesIncludeTax => 'Os preços incluem impostos';

  @override
  String get setRequireAcceptance =>
      'Os funcionários aceitam primeiro os pedidos';

  @override
  String get setGuestOrdering => 'Permitir pedidos por QR';

  @override
  String get setStockDeduction => 'Descontar stock pelas receitas';

  @override
  String get setPaymentPolicy => 'Quando os clientes pagam';

  @override
  String get policyPrepay => 'Pagamento antes da preparação';

  @override
  String get policyPostpay => 'Pagamento depois da refeição';

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutGrid => 'Grelha';

  @override
  String get layoutCompact => 'Compacto';

  @override
  String get periodMonthly => 'Mensal';

  @override
  String get periodYearly => 'Anual';

  @override
  String get healthCache => 'Cache';

  @override
  String get healthEvents => 'Eventos em espera';

  @override
  String get healthWebhooks => 'Webhooks falhados';

  @override
  String get phone => 'Telefone';

  @override
  String get notAvailable => 'Não aplicável';

  @override
  String get plusTaxes => 'Os impostos são calculados ao fazer o pedido';

  @override
  String get variants => 'Variantes';

  @override
  String get addVariant => 'Adicionar variante';

  @override
  String get addExtras => 'Adicionar extras';

  @override
  String get optionName => 'Nome da opção';

  @override
  String get uploadImage => 'Carregar imagem';

  @override
  String get uploadLogo => 'Carregar logótipo';

  @override
  String get uploadCover => 'Carregar capa';

  @override
  String get banners => 'Faixas';

  @override
  String get bannerTitle => 'Título da faixa';

  @override
  String get branches => 'Filiais';

  @override
  String get addBranch => 'Adicionar filial';

  @override
  String get branchCode => 'Código da filial';

  @override
  String get businessHours => 'Horário';

  @override
  String get opensAt => 'Abre';

  @override
  String get closesAt => 'Fecha';

  @override
  String get supportedLanguages => 'Idiomas dos clientes';

  @override
  String get gatewaySetup => 'Gateway de pagamento';

  @override
  String get provider => 'Fornecedor';

  @override
  String get environment => 'Modo';

  @override
  String get apiKeyId => 'ID da chave API';

  @override
  String get apiKeySecret => 'Segredo da API';

  @override
  String get webhookSecret => 'Segredo do webhook';

  @override
  String get webhookUrl => 'URL do webhook (adicione no seu gateway)';

  @override
  String get paymentMethods => 'Métodos de pagamento';

  @override
  String get subscription => 'Subscrição';

  @override
  String get choosePlan => 'Escolher plano';

  @override
  String get cancelSubscription => 'Cancelar subscrição';

  @override
  String get splitBill => 'Dividir conta';

  @override
  String get numberOfParts => 'Número de partes';

  @override
  String get transferTable => 'Mudar para mesa';

  @override
  String get recipe => 'Receita';

  @override
  String get purchaseOrders => 'Ordens de compra';

  @override
  String get newPurchaseOrder => 'Nova ordem de compra';

  @override
  String get receiveGoods => 'Receber mercadoria';

  @override
  String get supplierInvoices => 'Faturas de fornecedor';

  @override
  String get invoiceNumber => 'Número da fatura';

  @override
  String get recordPayment => 'Registar pagamento';

  @override
  String get expiringStock => 'Stock a expirar';

  @override
  String get trialBalance => 'Balancete';

  @override
  String get debit => 'Débito';

  @override
  String get credit => 'Crédito';

  @override
  String get balanceSheet => 'Balanço';

  @override
  String get assets => 'Ativos';

  @override
  String get liabilities => 'Passivos';

  @override
  String get equity => 'Capital próprio';

  @override
  String get journal => 'Diário';

  @override
  String get reverse => 'Reverter';

  @override
  String get periods => 'Períodos';

  @override
  String get closePeriod => 'Fechar período';

  @override
  String get cashRegisters => 'Caixas';

  @override
  String get openRegister => 'Abrir caixa';

  @override
  String get closeRegister => 'Fechar caixa';

  @override
  String get openingFloat => 'Fundo inicial';

  @override
  String get countedCash => 'Numerário contado';

  @override
  String get expectedCash => 'Numerário esperado';

  @override
  String get variance => 'Diferença';

  @override
  String get payroll => 'Salários';

  @override
  String get grossPay => 'Salário bruto';

  @override
  String get deductions => 'Deduções';

  @override
  String get markPaid => 'Marcar como pago';

  @override
  String get attendance => 'Assiduidade';

  @override
  String get clockIn => 'Registar entrada';

  @override
  String get clockOut => 'Registar saída';

  @override
  String get clockedIn => 'Feito';

  @override
  String get promotions => 'Promoções';

  @override
  String get loyalty => 'Fidelização';

  @override
  String get pointsPerUnit => 'Pontos por unidade monetária';

  @override
  String get valuePerPoint => 'Valor de um ponto';

  @override
  String get reply => 'Responder';

  @override
  String get notifications => 'Notificações';

  @override
  String get stations => 'Estações de cozinha';

  @override
  String get routeToStation => 'Enviar para estação';

  @override
  String get users => 'Utilizadores';

  @override
  String get disable => 'Desativar';

  @override
  String get translations => 'Traduções';

  @override
  String get translationKey => 'Chave';

  @override
  String get translationValue => 'Texto';

  @override
  String get countries => 'Países';

  @override
  String get commissions => 'Comissões';

  @override
  String get announcements => 'Anúncios';

  @override
  String get bodyText => 'Texto da mensagem';

  @override
  String get addresses => 'Moradas guardadas';

  @override
  String get addressLabel => 'Etiqueta';

  @override
  String get completedOrders => 'Pedidos concluídos';

  @override
  String get chooseCafe => 'Escolher um café';

  @override
  String get reserveTable => 'Reservar mesa';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get payments => 'Pagamentos';

  @override
  String get refunds => 'Reembolsos';

  @override
  String get settlements => 'Liquidações';

  @override
  String get syncSettlements => 'Obter liquidações';

  @override
  String get paymentLink => 'Link de pagamento';

  @override
  String get createPaymentLink => 'Criar link de pagamento';

  @override
  String get testConnection => 'Testar ligação';

  @override
  String get connectionOk => 'Ligado. Os pagamentos online estão ativos.';

  @override
  String get connectionFailed => 'O gateway recusou estas chaves.';

  @override
  String get payPart => 'Pagar parte da conta';

  @override
  String get amountToPay => 'Montante a pagar';

  @override
  String get paymentSuccessful => 'Pagamento recebido. Obrigado!';

  @override
  String get paymentNotCompleted =>
      'O pagamento não foi concluído. Esta tentativa não foi cobrada.';

  @override
  String get payOnline => 'Pagar online';

  @override
  String get gatewayFee => 'Taxa do gateway';

  @override
  String get referenceLabel => 'Referência';

  @override
  String get paymentBreakdown => 'Resumo de pagamentos';

  @override
  String get approveRefund => 'Aprovar reembolso';

  @override
  String get refundRequested =>
      'Reembolso pedido. Um gerente tem de o aprovar.';

  @override
  String get reconciled => 'Reconciliado';

  @override
  String get needsReview => 'Requer revisão';

  @override
  String get pendingKeys =>
      'Guardado. Teste a ligação para ativar os pagamentos online.';

  @override
  String get openingCheckout => 'A abrir o pagamento seguro…';

  @override
  String get welcomeBack => 'Bem-vindo de volta';

  @override
  String get thisMonth => 'Este mês';

  @override
  String get revenueTrend => 'Receita por dia';

  @override
  String get recentOrders => 'Pedidos recentes';

  @override
  String get addPhoto => 'Adicionar foto';

  @override
  String get changePhoto => 'Alterar foto';

  @override
  String get removePhoto => 'Remover foto';

  @override
  String get filterAll => 'Todos';

  @override
  String get available => 'Disponível';

  @override
  String get loginTagline =>
      'Gira o seu café com elegância, a partir de um só lugar.';

  @override
  String get signInSubtitle => 'Entre para continuar';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get back => 'Voltar';

  @override
  String get adminConsole => 'Console da plataforma';

  @override
  String get adminLoginTagline => 'Todos os cafés da plataforma, num relance.';

  @override
  String get kitchenDisplay => 'Tela da cozinha';

  @override
  String get kitchenLoginTagline =>
      'Cada pedido nítido de qualquer ponto da cozinha.';

  @override
  String get customerLoginTagline =>
      'Salve favoritos, acompanhe pedidos e ganhe recompensas.';

  @override
  String get signInToOrder => 'Entre para pedir';

  @override
  String get signInToOrderHint =>
      'Navegue à vontade. Para fazer um pedido, entre ou crie uma conta.';

  @override
  String get roleOwner => 'Proprietário';

  @override
  String get markAvailable => 'Marcar como livre';

  @override
  String get tableReleased => 'A mesa agora está livre';

  @override
  String get tableHasUnpaid =>
      'Esta mesa ainda tem pedidos não pagos. Feche a conta primeiro.';

  @override
  String unpaidForMinutes(int minutes) {
    return 'Não pago há $minutes min';
  }

  @override
  String tablePin(String pin) {
    return 'PIN $pin';
  }

  @override
  String get enterTablePin => 'Digite o PIN da mesa';

  @override
  String get tablePinHint => 'Peça à equipe o PIN de 4 dígitos da sua mesa.';

  @override
  String get tablePinWrong => 'Esse PIN não confere. Confirme com a equipe.';

  @override
  String get setTablePin => 'Pedir aos clientes um PIN da mesa antes de pedir';

  @override
  String get setSessionEndAfterPayment =>
      'Encerrar a sessão da mesa este tempo após o pagamento';

  @override
  String get setUnpaidAlert =>
      'Avisar a equipe sobre pedidos ainda não pagos após';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get resetPassword => 'Definir nova senha';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get passwordResetDone => 'Senha alterada. Você já pode entrar.';

  @override
  String get resetLinkInvalid => 'Este link expirou ou já foi usado.';

  @override
  String get passwordResetUnavailable =>
      'A redefinição de senha ainda não está disponível.';

  @override
  String get minutesUnit => 'min';

  @override
  String get resetLinkSent =>
      'Se esse e-mail tiver uma conta, um link está a caminho.';

  @override
  String countsForDay(String date) {
    return 'conta para $date';
  }
}
