// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Añadir';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get search => 'Buscar';

  @override
  String get close => 'Cerrar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get emptyTitle => 'Aún no hay nada aquí';

  @override
  String get errorTitle => 'Algo salió mal';

  @override
  String get networkError =>
      'No se puede conectar con el servidor. Comprueba tu conexión.';

  @override
  String get invalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get accountLocked => 'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get rateLimited => 'Demasiadas solicitudes. Espera un momento.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get email => 'Correo';

  @override
  String get password => 'Contraseña';

  @override
  String get name => 'Nombre';

  @override
  String get language => 'Idioma';

  @override
  String get requiredField => 'Obligatorio';

  @override
  String get invalidValue => 'Valor no válido';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Descuento';

  @override
  String get tax => 'Impuesto';

  @override
  String get serviceCharge => 'Cargo por servicio';

  @override
  String get status => 'Estado';

  @override
  String get date => 'Fecha';

  @override
  String get amount => 'Importe';

  @override
  String get quantity => 'Cantidad';

  @override
  String get notes => 'Notas';

  @override
  String get reason => 'Motivo';

  @override
  String get refresh => 'Actualizar';

  @override
  String welcomeTable(String table) {
    return 'Mesa $table';
  }

  @override
  String get menu => 'Menú';

  @override
  String get cart => 'Carrito';

  @override
  String get addToCart => 'Añadir al carrito';

  @override
  String get viewCart => 'Ver carrito';

  @override
  String get emptyCart => 'Tu carrito está vacío';

  @override
  String get chooseOption => 'Elige una opción';

  @override
  String get extras => 'Extras';

  @override
  String get specialInstructions => 'Instrucciones especiales';

  @override
  String get placeOrder => 'Hacer pedido';

  @override
  String get orderPlaced => 'Pedido realizado';

  @override
  String orderNumber(int number) {
    return 'Pedido #$number';
  }

  @override
  String get trackOrder => 'Seguir pedido';

  @override
  String get payNow => 'Pagar ahora';

  @override
  String get payAtCounter => 'Pagar en caja';

  @override
  String get onlinePaymentUnavailable =>
      'El pago en línea aún no está disponible aquí. Paga en caja.';

  @override
  String get paymentPending => 'Esperando confirmación del pago';

  @override
  String get receipt => 'Recibo';

  @override
  String get rateUs => 'Valora tu experiencia';

  @override
  String get submit => 'Enviar';

  @override
  String get thanks => '¡Gracias!';

  @override
  String get callWaiter => 'Llamar al camarero';

  @override
  String get requestBill => 'Pedir la cuenta';

  @override
  String get callStaff => 'Llamar al personal';

  @override
  String get requestSent => 'Solicitud enviada. Se ha avisado al personal.';

  @override
  String get favorites => 'Favoritos';

  @override
  String get wishlist => 'Lista de deseos';

  @override
  String get recentlyOrdered => 'Pedidos recientes';

  @override
  String get coupon => 'Código de cupón';

  @override
  String get apply => 'Aplicar';

  @override
  String get couponInvalid => 'Este cupón no se puede usar';

  @override
  String get veg => 'Vegetariano';

  @override
  String get nonVeg => 'No vegetariano';

  @override
  String get egg => 'Huevo';

  @override
  String get vegan => 'Vegano';

  @override
  String get outOfStock => 'Agotado';

  @override
  String get myOrders => 'Mis pedidos';

  @override
  String get profile => 'Perfil';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get offers => 'Ofertas';

  @override
  String get qrInvalid =>
      'Este código QR ya no es válido. Pregunta al personal.';

  @override
  String get noResults => 'No hay coincidencias';

  @override
  String get allCategories => 'Todo';

  @override
  String get statusPendingPayment => 'Pendiente de pago';

  @override
  String get statusPlaced => 'Nuevo';

  @override
  String get statusAccepted => 'Aceptado';

  @override
  String get statusPreparing => 'En preparación';

  @override
  String get statusReady => 'Listo';

  @override
  String get statusServed => 'Servido';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get payUnpaid => 'Sin pagar';

  @override
  String get payPartial => 'Pago parcial';

  @override
  String get payPaid => 'Pagado';

  @override
  String get payPartRefund => 'Reembolso parcial';

  @override
  String get payRefunded => 'Reembolsado';

  @override
  String get kitchenNew => 'Nuevo';

  @override
  String get kitchenInProgress => 'En curso';

  @override
  String get kitchenReady => 'Listo';

  @override
  String get accept => 'Aceptar';

  @override
  String get startPreparing => 'Empezar';

  @override
  String get markReady => 'Listo';

  @override
  String get complete => 'Completar';

  @override
  String get delayed => 'Retrasado';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get priority => 'Prioridad';

  @override
  String get allStations => 'Todas las estaciones';

  @override
  String get noTickets => 'Sin pedidos ahora';

  @override
  String get connectionLost => 'Conexión perdida. Reconectando…';

  @override
  String get takeaway => 'Para llevar';

  @override
  String get kitchenBranch => 'Sucursal';

  @override
  String get dashboard => 'Panel';

  @override
  String get orders => 'Pedidos';

  @override
  String get menuManage => 'Menú';

  @override
  String get tables => 'Mesas';

  @override
  String get staff => 'Personal';

  @override
  String get inventory => 'Inventario';

  @override
  String get finance => 'Finanzas';

  @override
  String get marketing => 'Marketing';

  @override
  String get settings => 'Ajustes';

  @override
  String get revenue => 'Ingresos';

  @override
  String get ordersCount => 'Pedidos';

  @override
  String get averageOrder => 'Pedido medio';

  @override
  String get cancellationRate => 'Tasa de cancelación';

  @override
  String get topProducts => 'Más vendidos';

  @override
  String get peakHours => 'Horas punta';

  @override
  String get noDataYet => 'Sin datos para este período';

  @override
  String get registerCafe => 'Registra tu cafetería';

  @override
  String get cafeName => 'Nombre de la cafetería';

  @override
  String get legalName => 'Razón social';

  @override
  String get country => 'País';

  @override
  String get currency => 'Moneda';

  @override
  String get timezone => 'Zona horaria';

  @override
  String get address => 'Dirección';

  @override
  String get city => 'Ciudad';

  @override
  String get ownerName => 'Tu nombre';

  @override
  String get pendingApproval =>
      'Tu cafetería está pendiente de aprobación. Mientras tanto puedes configurarla.';

  @override
  String get categories => 'Categorías';

  @override
  String get products => 'Productos';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get newProduct => 'Nuevo producto';

  @override
  String get price => 'Precio';

  @override
  String get category => 'Categoría';

  @override
  String get tableNumber => 'Número de mesa';

  @override
  String get capacity => 'Capacidad';

  @override
  String get qrCode => 'Código QR';

  @override
  String get regenerateQr => 'Regenerar QR';

  @override
  String get inviteStaff => 'Invitar personal';

  @override
  String get role => 'Rol';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get suppliers => 'Proveedores';

  @override
  String get stock => 'Existencias';

  @override
  String get unit => 'Unidad';

  @override
  String get unitCost => 'Coste unitario';

  @override
  String get stockIn => 'Entrada de stock';

  @override
  String get expenses => 'Gastos';

  @override
  String get sales => 'Ventas';

  @override
  String get profitLoss => 'Pérdidas y ganancias';

  @override
  String get exportExcel => 'Exportar Excel';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get branding => 'Marca';

  @override
  String get primaryColor => 'Color principal';

  @override
  String get coupons => 'Cupones';

  @override
  String get code => 'Código';

  @override
  String get percent => 'Porcentaje';

  @override
  String get acceptOrder => 'Aceptar';

  @override
  String get markServed => 'Servido';

  @override
  String get confirmCash => 'Confirmar efectivo';

  @override
  String get refund => 'Reembolso';

  @override
  String get netProfit => 'Beneficio neto';

  @override
  String get totalRevenue => 'Ingresos totales';

  @override
  String get totalExpenses => 'Gastos totales';

  @override
  String get invitationLink => 'Envía este token de invitación a tu empleado';

  @override
  String get cancelOrder => 'Cancelar pedido';

  @override
  String get selectBranch => 'Seleccionar sucursal';

  @override
  String get balance => 'Saldo pendiente';

  @override
  String get customers => 'Clientes';

  @override
  String get reservations => 'Reservas';

  @override
  String get partySize => 'Comensales';

  @override
  String get support => 'Soporte';

  @override
  String get subject => 'Asunto';

  @override
  String get message => 'Mensaje';

  @override
  String get cafes => 'Cafeterías';

  @override
  String get approve => 'Aprobar';

  @override
  String get suspend => 'Suspender';

  @override
  String get activate => 'Activar';

  @override
  String get plans => 'Planes';

  @override
  String get auditLogs => 'Registro de auditoría';

  @override
  String get health => 'Estado del sistema';

  @override
  String get totalCafes => 'Total de cafeterías';

  @override
  String get activeCafes => 'Cafeterías activas';

  @override
  String get totalCustomers => 'Clientes';

  @override
  String get totalOrders => 'Total de pedidos';

  @override
  String get enrollMfa => 'Configurar verificación en dos pasos';

  @override
  String get mfaCode => 'Código de 6 dígitos';

  @override
  String get mfaSecret => 'Añade esta clave a tu app de autenticación';

  @override
  String get grossByCurrency => 'Ventas brutas por moneda';

  @override
  String get cafesByCountry => 'Cafeterías por país';

  @override
  String get activeSubscriptions => 'Suscripciones activas';

  @override
  String get reasonPrompt =>
      'Indica un motivo. Quedará en el registro de auditoría.';

  @override
  String get action => 'Acción';

  @override
  String get database => 'Base de datos';

  @override
  String get pendingCafes => 'Pendientes de aprobación';

  @override
  String get owner => 'Propietario';

  @override
  String get stActive => 'Activo';

  @override
  String get stInactive => 'Inactivo';

  @override
  String get stAvailable => 'Disponible';

  @override
  String get stOccupied => 'Ocupada';

  @override
  String get stReserved => 'Reservada';

  @override
  String get stCleaning => 'En limpieza';

  @override
  String get stSuspended => 'Suspendida';

  @override
  String get stRejected => 'Rechazada';

  @override
  String get stClosed => 'Cerrada';

  @override
  String get stOpen => 'Abierta';

  @override
  String get stResolved => 'Resuelta';

  @override
  String get stInProgress => 'En curso';

  @override
  String get stInvited => 'Invitado';

  @override
  String get roleManager => 'Encargado';

  @override
  String get roleCashier => 'Cajero';

  @override
  String get roleWaiter => 'Camarero';

  @override
  String get roleKitchen => 'Personal de cocina';

  @override
  String get setPricesIncludeTax => 'Los precios incluyen impuestos';

  @override
  String get setRequireAcceptance => 'El personal acepta primero los pedidos';

  @override
  String get setGuestOrdering => 'Permitir pedidos por QR';

  @override
  String get setStockDeduction => 'Descontar stock según recetas';

  @override
  String get setPaymentPolicy => 'Cuándo pagan los clientes';

  @override
  String get policyPrepay => 'Pago antes de preparar';

  @override
  String get policyPostpay => 'Pago después de comer';

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutGrid => 'Cuadrícula';

  @override
  String get layoutCompact => 'Compacto';

  @override
  String get periodMonthly => 'Mensual';

  @override
  String get periodYearly => 'Anual';

  @override
  String get healthCache => 'Caché';

  @override
  String get healthEvents => 'Eventos en espera';

  @override
  String get healthWebhooks => 'Webhooks fallidos';

  @override
  String get phone => 'Teléfono';

  @override
  String get notAvailable => 'No aplica';

  @override
  String get plusTaxes => 'Los impuestos se calculan al hacer el pedido';

  @override
  String get variants => 'Variantes';

  @override
  String get addVariant => 'Añadir variante';

  @override
  String get addExtras => 'Añadir extras';

  @override
  String get optionName => 'Nombre de la opción';

  @override
  String get uploadImage => 'Subir imagen';

  @override
  String get uploadLogo => 'Subir logotipo';

  @override
  String get uploadCover => 'Subir portada';

  @override
  String get banners => 'Banners';

  @override
  String get bannerTitle => 'Título del banner';

  @override
  String get branches => 'Sucursales';

  @override
  String get addBranch => 'Añadir sucursal';

  @override
  String get branchCode => 'Código de sucursal';

  @override
  String get businessHours => 'Horario';

  @override
  String get opensAt => 'Abre';

  @override
  String get closesAt => 'Cierra';

  @override
  String get supportedLanguages => 'Idiomas para clientes';

  @override
  String get gatewaySetup => 'Pasarela de pago';

  @override
  String get provider => 'Proveedor';

  @override
  String get environment => 'Modo';

  @override
  String get apiKeyId => 'ID de clave API';

  @override
  String get apiKeySecret => 'Secreto de API';

  @override
  String get webhookSecret => 'Secreto de webhook';

  @override
  String get webhookUrl => 'URL de webhook (añádela en tu pasarela)';

  @override
  String get paymentMethods => 'Métodos de pago';

  @override
  String get subscription => 'Suscripción';

  @override
  String get choosePlan => 'Elige un plan';

  @override
  String get cancelSubscription => 'Cancelar suscripción';

  @override
  String get splitBill => 'Dividir cuenta';

  @override
  String get numberOfParts => 'Número de partes';

  @override
  String get transferTable => 'Mover a mesa';

  @override
  String get recipe => 'Receta';

  @override
  String get purchaseOrders => 'Órdenes de compra';

  @override
  String get newPurchaseOrder => 'Nueva orden de compra';

  @override
  String get receiveGoods => 'Recibir mercancía';

  @override
  String get supplierInvoices => 'Facturas de proveedor';

  @override
  String get invoiceNumber => 'Número de factura';

  @override
  String get recordPayment => 'Registrar pago';

  @override
  String get expiringStock => 'Existencias por caducar';

  @override
  String get trialBalance => 'Balance de comprobación';

  @override
  String get debit => 'Debe';

  @override
  String get credit => 'Haber';

  @override
  String get balanceSheet => 'Balance general';

  @override
  String get assets => 'Activos';

  @override
  String get liabilities => 'Pasivos';

  @override
  String get equity => 'Patrimonio';

  @override
  String get journal => 'Diario';

  @override
  String get reverse => 'Revertir';

  @override
  String get periods => 'Períodos';

  @override
  String get closePeriod => 'Cerrar período';

  @override
  String get cashRegisters => 'Cajas';

  @override
  String get openRegister => 'Abrir caja';

  @override
  String get closeRegister => 'Cerrar caja';

  @override
  String get openingFloat => 'Fondo inicial';

  @override
  String get countedCash => 'Efectivo contado';

  @override
  String get expectedCash => 'Efectivo esperado';

  @override
  String get variance => 'Diferencia';

  @override
  String get payroll => 'Nómina';

  @override
  String get grossPay => 'Salario bruto';

  @override
  String get deductions => 'Deducciones';

  @override
  String get markPaid => 'Marcar pagado';

  @override
  String get attendance => 'Asistencia';

  @override
  String get clockIn => 'Fichar entrada';

  @override
  String get clockOut => 'Fichar salida';

  @override
  String get clockedIn => 'Hecho';

  @override
  String get promotions => 'Promociones';

  @override
  String get loyalty => 'Fidelidad';

  @override
  String get pointsPerUnit => 'Puntos por unidad de moneda';

  @override
  String get valuePerPoint => 'Valor de un punto';

  @override
  String get reply => 'Responder';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get stations => 'Estaciones de cocina';

  @override
  String get routeToStation => 'Enviar a estación';

  @override
  String get users => 'Usuarios';

  @override
  String get disable => 'Desactivar';

  @override
  String get translations => 'Traducciones';

  @override
  String get translationKey => 'Clave';

  @override
  String get translationValue => 'Texto';

  @override
  String get countries => 'Países';

  @override
  String get commissions => 'Comisiones';

  @override
  String get announcements => 'Anuncios';

  @override
  String get bodyText => 'Texto del mensaje';

  @override
  String get addresses => 'Direcciones guardadas';

  @override
  String get addressLabel => 'Etiqueta';

  @override
  String get completedOrders => 'Pedidos completados';

  @override
  String get chooseCafe => 'Elige una cafetería';

  @override
  String get reserveTable => 'Reservar mesa';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get payments => 'Pagos';

  @override
  String get refunds => 'Reembolsos';

  @override
  String get settlements => 'Liquidaciones';

  @override
  String get syncSettlements => 'Obtener liquidaciones';

  @override
  String get paymentLink => 'Enlace de pago';

  @override
  String get createPaymentLink => 'Crear enlace de pago';

  @override
  String get testConnection => 'Probar conexión';

  @override
  String get connectionOk => 'Conectado. Los pagos en línea están activos.';

  @override
  String get connectionFailed => 'La pasarela rechazó estas claves.';

  @override
  String get payPart => 'Pagar parte de la cuenta';

  @override
  String get amountToPay => 'Importe a pagar';

  @override
  String get paymentSuccessful => 'Pago recibido. ¡Gracias!';

  @override
  String get paymentNotCompleted =>
      'El pago no se completó. No se te ha cobrado este intento.';

  @override
  String get payOnline => 'Pagar en línea';

  @override
  String get gatewayFee => 'Comisión de pasarela';

  @override
  String get referenceLabel => 'Referencia';

  @override
  String get paymentBreakdown => 'Resumen de pagos';

  @override
  String get approveRefund => 'Aprobar reembolso';

  @override
  String get refundRequested =>
      'Reembolso solicitado. Debe aprobarlo un encargado.';

  @override
  String get reconciled => 'Conciliado';

  @override
  String get needsReview => 'Requiere revisión';

  @override
  String get pendingKeys =>
      'Guardado. Prueba la conexión para activar los pagos en línea.';

  @override
  String get openingCheckout => 'Abriendo el pago seguro…';
}
