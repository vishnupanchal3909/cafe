import { Body, Controller, Get, Headers, HttpCode, Param, Post, Put, Query, RawBodyRequest, Req, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsIn, IsInt, IsISO8601, IsOptional, IsString, Length, Matches, Max, MaxLength, Min, MinLength } from 'class-validator';
import type { Request, Response } from 'express';
import { Audiences, Public, RateLimit, RawResponse, Requires } from '../../common/http';
import { TableSessionRoute } from '../identity/auth.guard';
import { InvoicingService } from '../invoicing/invoicing.service';
import { PaymentsService } from './payments.service';

const AMOUNT = /^\d{1,15}(\.\d{1,4})?$/;

export class InitiatePaymentDto {
  @IsString() @MaxLength(32) methodCode: string;
  @IsOptional() @Matches(AMOUNT) amount?: string;
  @IsOptional() @IsString() @Length(26, 26) billId?: string;
  @IsOptional() @IsIn(['checkout', 'link']) flow?: 'checkout' | 'link';
}
export class VerifyCallbackDto {
  @IsString() @MaxLength(191) providerPaymentRef: string;
  @IsString() @MaxLength(191) signature: string;
}
export class PaymentLinkDto { @IsOptional() @Matches(AMOUNT) amount?: string; }
export class CashDto {
  @IsString() @Length(26, 26) orderId: string;
  @IsOptional() @Matches(AMOUNT) amount?: string;
  @IsOptional() @IsString() @Length(26, 26) registerSessionId?: string;
  @IsOptional() @IsString() @Length(26, 26) billId?: string;
}
export class RefundDto {
  @Matches(AMOUNT) amount: string;
  @IsString() @MinLength(3) @MaxLength(500) reason: string;
}
export class GatewayAccountDto {
  @IsString() @MaxLength(32) providerCode: string;
  @IsIn(['sandbox', 'live']) environment: 'sandbox' | 'live';
  @IsOptional() @IsString() @MaxLength(200) keyId?: string;
  @IsString() @MaxLength(500) keySecret: string;
  @IsOptional() @IsString() @MaxLength(500) webhookSecret?: string;
}
export class MethodsDto { @IsArray() @ArrayMaxSize(20) @IsString({ each: true }) methods: string[]; }
export class SplitDto {
  @IsString() @Length(26, 26) orderId: string;
  @IsOptional() @IsInt() @Min(2) @Max(50) equalParts?: number;
  @IsOptional() @IsArray() @ArrayMaxSize(50) @Matches(AMOUNT, { each: true }) amounts?: string[];
}
export class SyncDto {
  @IsISO8601() from: string;
  @IsISO8601() to: string;
}

@ApiTags('webhooks')
@Controller('webhooks/payments')
export class WebhookController {
  constructor(private readonly svc: PaymentsService) {}
  @Post(':provider/:account') @Public() @HttpCode(200) @RateLimit(600)
  handle(@Param('provider') provider: string, @Param('account') account: string, @Req() req: RawBodyRequest<Request>) {
    return this.svc.webhook(provider, account, req.rawBody ?? Buffer.alloc(0), req.headers);
  }
}

@ApiTags('customer-payments')
@Controller('customer')
export class CustomerPaymentController {
  constructor(private readonly svc: PaymentsService) {}
  @Post('orders/:id/payments') @TableSessionRoute() @RateLimit(20)
  pay(@Param('id') id: string, @Body() d: InitiatePaymentDto, @Headers('idempotency-key') key: string) { return this.svc.initiate(id, d, key); }
  @Post('payments/:id/verify') @TableSessionRoute() @HttpCode(200) @RateLimit(30)
  verify(@Param('id') id: string, @Body() d: VerifyCallbackDto) { return this.svc.verifyClientCallback(id, d); }
  @Post('payments/:id/abandon') @TableSessionRoute() @HttpCode(200) @RateLimit(30)
  abandon(@Param('id') id: string) { return this.svc.abandon(id); }
  @Get('payments/:id') @TableSessionRoute()
  status(@Param('id') id: string) { return this.svc.refreshFromProvider(id); }
  @Get('payment-options') @TableSessionRoute()
  async options() { return { methods: await this.svc.methods(), online: await this.svc.activeOnlineProvider() }; }
}

@ApiTags('cafe-payments')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class CafePaymentController {
  constructor(private readonly svc: PaymentsService, private readonly invoices: InvoicingService) {}
  @Get('payments') @Requires('payments.read') list(@Query() q: { status?: string; orderId?: string }) { return this.svc.list(q); }
  @Post('payments/cash') @Requires('payments.cash_confirm') cash(@Body() d: CashDto, @Headers('idempotency-key') key: string) { return this.svc.confirmCash(d, key); }
  @Post('orders/:id/payment-link') @Requires('payments.cash_confirm') link(@Param('id') id: string, @Body() d: PaymentLinkDto, @Headers('idempotency-key') key: string) { return this.svc.createPaymentLink(id, d.amount, key); }
  @Post('payments/:id/refunds') @Requires('refunds.request') refund(@Param('id') id: string, @Body() d: RefundDto, @Headers('idempotency-key') key: string) { return this.svc.requestRefund(id, d, key); }
  @Get('refunds') @Requires('payments.read') refunds() { return this.svc.listRefunds(); }
  @Post('refunds/:id/approve') @Requires('refunds.approve') approve(@Param('id') id: string) { return this.svc.approveRefund(id); }
  @Post('bills/split') @Requires('orders.update') split(@Body() d: SplitDto) { return this.svc.splitBill(d); }
  @Get('gateway-accounts') @Requires('payments.gateway_manage') accounts() { return this.svc.listAccounts(); }
  @Put('gateway-accounts') @Requires('payments.gateway_manage') save(@Body() d: GatewayAccountDto) { return this.svc.saveAccount(d); }
  @Post('gateway-accounts/:id/test') @Requires('payments.gateway_manage') @HttpCode(200) test(@Param('id') id: string) { return this.svc.testAccount(id); }
  @Get('payment-methods') @Requires('payments.read') methods() { return this.svc.methods(); }
  @Put('payment-methods') @Requires('payments.gateway_manage') setMethods(@Body() d: MethodsDto) { return this.svc.setMethods(d.methods); }
  @Get('settlements') @Requires('payments.read') settlements() { return this.svc.listSettlements(); }
  @Post('settlements/sync') @Requires('payments.gateway_manage') sync(@Body() d: SyncDto) { return this.svc.syncSettlements(d.from, d.to); }
  @Get('invoices') @Requires('invoices.read') invoiceList(@Query() q: { from?: string; to?: string }) { return this.invoices.list(q); }
  @Get('invoices/:id') @Requires('invoices.read') invoice(@Param('id') id: string) { return this.invoices.get(id); }
  @Get('invoices/:id/pdf') @Requires('invoices.read') @RawResponse()
  async pdf(@Param('id') id: string, @Res() res: Response) {
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="invoice-${id}.pdf"`);
    res.send(await this.invoices.pdf(id));
  }
}
