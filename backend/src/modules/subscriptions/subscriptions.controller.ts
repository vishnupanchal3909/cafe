import { Body, Controller, Get, Param, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsIn, IsInt, IsOptional, IsString, Length, Matches, MaxLength, Min, ValidateNested } from 'class-validator';
import { Audiences, Requires } from '../../common/http';
import { SubscriptionsService } from './subscriptions.service';

export class SubscribeDto {
  @IsString() @MaxLength(32) planCode: string;
  @IsIn(['monthly', 'yearly']) interval: 'monthly' | 'yearly';
}
export class ChangePlanDto {
  @IsString() @MaxLength(32) planCode: string;
  @IsOptional() @IsIn(['monthly', 'yearly']) interval?: 'monthly' | 'yearly';
}
class PriceDto {
  @IsString() @Length(3, 3) currency: string;
  @IsIn(['monthly', 'yearly']) interval: 'monthly' | 'yearly';
  @Matches(/^\d{1,15}(\.\d{1,4})?$/) amount: string;
}
class EntitlementDto {
  @IsString() @MaxLength(64) feature: string;
  @IsBoolean() enabled: boolean;
  @IsOptional() @IsInt() @Min(0) limit?: number | null;
}
export class SavePlanDto {
  @IsOptional() @IsString() @MaxLength(64) name?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsBoolean() isPublic?: boolean;
  @IsOptional() @IsInt() @Min(0) trialDays?: number;
  @IsOptional() @IsInt() @Min(0) graceDays?: number;
  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => PriceDto) prices?: PriceDto[];
  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => EntitlementDto) entitlements?: EntitlementDto[];
}
export class MarkPaidDto { @IsString() @MaxLength(191) reference: string; }

@ApiTags('cafe-subscription')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe/subscription')
export class CafeSubscriptionController {
  constructor(private readonly svc: SubscriptionsService) {}
  @Get() @Requires('subscription.manage') current() { return this.svc.current(); }
  @Get('plans') @Requires('subscription.manage') plans() { return this.svc.availablePlans(); }
  @Get('invoices') @Requires('subscription.manage') invoices() { return this.svc.invoices(); }
  @Post() @Requires('subscription.manage') subscribe(@Body() d: SubscribeDto) { return this.svc.subscribe(d); }
  @Post('change') @Requires('subscription.manage') change(@Body() d: ChangePlanDto) { return this.svc.changePlan(d); }
  @Post('cancel') @Requires('subscription.manage') cancel() { return this.svc.cancel(); }
}

@ApiTags('platform-plans')
@ApiBearerAuth()
@Audiences('platform')
@Controller('platform')
export class PlatformPlanController {
  constructor(private readonly svc: SubscriptionsService) {}
  @Get('plans') @Requires('platform.plans.manage') plans() { return this.svc.adminPlans(); }
  @Put('plans/:code') @Requires('platform.plans.manage') save(@Param('code') code: string, @Body() d: SavePlanDto) { return this.svc.adminSavePlan(code, d); }
  @Post('subscription-invoices/:id/paid') @Requires('platform.plans.manage') paid(@Param('id') id: string, @Body() d: MarkPaidDto) { return this.svc.adminMarkInvoicePaid(id, d.reference); }
}
