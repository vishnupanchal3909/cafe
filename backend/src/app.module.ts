import { Global, MiddlewareConsumer, Module, NestModule, ValidationPipe } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { AllExceptionsFilter } from './common/errors';
import { ContextMiddleware, EnvelopeInterceptor, RateLimitGuard } from './common/http';
import { MessageCatalog } from './common/i18n';
import { Db } from './infra/db/db.service';
import { StorageService } from './infra/storage/storage.service';
import { AccountingService } from './modules/accounting/accounting.service';
import { AnalyticsService } from './modules/analytics/analytics.service';
import { CafeAnalyticsController, PlatformAnalyticsController } from './modules/analytics/analytics.controller';
import { CatalogController, PublicMenuController } from './modules/catalog/catalog.controller';
import { CatalogService } from './modules/catalog/catalog.service';
import { CafeCustomersController, CustomerAccountController } from './modules/customers/customers.controller';
import { CustomersService } from './modules/customers/customers.service';
import { FinanceController } from './modules/finance/finance.controller';
import { FinanceService } from './modules/finance/finance.service';
import { AuthController, CustomerAuthController } from './modules/identity/auth.controller';
import { AuthGuard } from './modules/identity/auth.guard';
import { AuthService } from './modules/identity/auth.service';
import { InventoryController } from './modules/inventory/inventory.controller';
import { InventoryService } from './modules/inventory/inventory.service';
import { InvoicingService } from './modules/invoicing/invoicing.service';
import { KitchenConfigController, KitchenController } from './modules/kitchen/kitchen.controller';
import { KitchenService } from './modules/kitchen/kitchen.service';
import { CustomerReviewController, MarketingController } from './modules/marketing/marketing.controller';
import { MarketingService } from './modules/marketing/marketing.service';
import { NotificationPrefsController, NotificationsController } from './modules/notifications/notifications.controller';
import { NotificationsService } from './modules/notifications/notifications.service';
import { CafeOrderController, CustomerHistoryController, CustomerOrderController } from './modules/ordering/ordering.controller';
import { OrderingService } from './modules/ordering/ordering.service';
import { CafePaymentController, CustomerPaymentController, WebhookController } from './modules/payments/payments.controller';
import { PaymentProviderRegistry, PaymentsService } from './modules/payments/payments.service';
import { CafePlatformController, HealthController, PlatformController } from './modules/platform/platform.controller';
import { PlatformService } from './modules/platform/platform.service';
import { RealtimeService } from './modules/realtime/realtime.service';
import { InvitationController, StaffController } from './modules/staff/staff.controller';
import { StaffService } from './modules/staff/staff.service';
import { EntitlementService } from './modules/subscriptions/entitlement.service';
import { CafeSubscriptionController, PlatformPlanController } from './modules/subscriptions/subscriptions.controller';
import { SubscriptionsService } from './modules/subscriptions/subscriptions.service';
import { PublicQrController, SessionServiceController, TablesController } from './modules/tables/tables.controller';
import { TablesService } from './modules/tables/tables.service';
import { CafeController, PublicCafeController } from './modules/tenancy/tenancy.controller';
import { TenancyService } from './modules/tenancy/tenancy.service';
import { WorkersService } from './modules/workers.service';

@Global()
@Module({
  controllers: [
    AuthController, CustomerAuthController, InvitationController, PublicCafeController, CafeController, PublicMenuController, CatalogController, PublicQrController, SessionServiceController, TablesController,
    CustomerOrderController, CustomerHistoryController, CafeOrderController, KitchenController, KitchenConfigController, WebhookController, CustomerPaymentController, CafePaymentController, InventoryController, FinanceController, StaffController,
    CustomerAccountController, CafeCustomersController, MarketingController, CustomerReviewController, NotificationsController, NotificationPrefsController, CafeSubscriptionController, PlatformPlanController, CafeAnalyticsController, PlatformAnalyticsController, HealthController, PlatformController, CafePlatformController,
  ],
  providers: [
    Db, StorageService, MessageCatalog, AuthService, TenancyService, CatalogService, TablesService, AccountingService, InventoryService, EntitlementService, OrderingService, KitchenService, InvoicingService, PaymentProviderRegistry, PaymentsService, FinanceService, StaffService, CustomersService, MarketingService, NotificationsService, SubscriptionsService, AnalyticsService, PlatformService, RealtimeService, WorkersService,
    { provide: APP_GUARD, useClass: RateLimitGuard },
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_INTERCEPTOR, useClass: EnvelopeInterceptor },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_PIPE, useValue: new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }) },
  ],
  exports: [Db],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) { consumer.apply(ContextMiddleware).forRoutes('*'); }
}
