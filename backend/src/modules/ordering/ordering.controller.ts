import { Body, Controller, Get, Headers, Param, ParseIntPipe, Patch, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsBoolean, IsIn, IsInt, IsObject, IsOptional, IsString, Length, MaxLength, Min, MinLength, ValidateNested } from 'class-validator';
import { principal } from '../../common/context';
import { Audiences, RateLimit, Requires } from '../../common/http';
import { TableSessionRoute } from '../identity/auth.guard';
import { OrderingService, OrderStatus } from './ordering.service';

class AddonChoiceDto {
  @IsString() @Length(26, 26) addonId: string;
  @IsOptional() @IsInt() @Min(1) quantity?: number;
}
// There is deliberately no price field anywhere in these DTOs; unknown fields are rejected outright.
class ItemDto {
  @IsString() @Length(26, 26) productId: string;
  @IsOptional() @IsString() @Length(26, 26) variantId?: string;
  @IsInt() @Min(1) quantity: number;
  @IsOptional() @IsArray() @ArrayMaxSize(30) @ValidateNested({ each: true }) @Type(() => AddonChoiceDto) addons?: AddonChoiceDto[];
  @IsOptional() @IsString() @MaxLength(500) notes?: string;
}
export class PlaceOrderDto {
  @IsArray() @ArrayMinSize(1) @ArrayMaxSize(100) @ValidateNested({ each: true }) @Type(() => ItemDto) items: ItemDto[];
  @IsOptional() @IsString() @MaxLength(1000) notes?: string;
  @IsOptional() @IsString() @MaxLength(40) couponCode?: string;
  @IsOptional() @IsString() @MaxLength(12) language?: string;
  @IsOptional() @IsInt() @Min(1) redeemPoints?: number;
}
export class StaffOrderDto extends PlaceOrderDto {
  @IsOptional() @IsIn(['dine_in', 'takeaway', 'delivery']) orderType?: 'dine_in';
  @IsOptional() @IsString() @Length(26, 26) tableId?: string;
  @IsOptional() @IsObject() deliveryAddress?: Record<string, unknown>;
}
export class TransitionDto {
  @IsIn(['accepted', 'preparing', 'ready', 'served', 'completed', 'cancelled']) status: OrderStatus;
  @IsOptional() @IsString() @MaxLength(500) reason?: string;
}
export class ModifyItemDto {
  @IsOptional() @IsInt() @Min(0) quantity?: number;
  @IsOptional() @IsBoolean() cancel?: boolean;
  @IsString() @MinLength(3) @MaxLength(500) reason: string;
}
export class CouponCheckDto {
  @IsString() @MaxLength(40) code: string;
  @IsString() @MaxLength(24) subtotal: string;
}

@ApiTags('customer-orders')
@Controller('customer')
export class CustomerOrderController {
  constructor(private readonly svc: OrderingService) {}
  @Post('orders') @TableSessionRoute() @RateLimit(30)
  place(@Body() dto: PlaceOrderDto, @Headers('idempotency-key') key?: string) { return this.svc.place(dto, key); }
  @Get('orders') @TableSessionRoute() list() { return this.svc.listForSession(); }
  @Get('orders/:id') @TableSessionRoute() get(@Param('id') id: string) { return this.svc.getForSession(id); }
  @Post('coupons/validate') @TableSessionRoute() @RateLimit(30) coupon(@Body() d: CouponCheckDto) { return this.svc.validateCoupon(d.code, d.subtotal); }
  @Get('recent-items') @TableSessionRoute()
  recent() { const p = principal(); return p.id ? this.svc.recentlyOrdered(p.id) : []; }
}

@ApiTags('customer-history')
@ApiBearerAuth()
@Audiences('customer')
@Controller('customer')
export class CustomerHistoryController {
  constructor(private readonly svc: OrderingService) {}
  @Get('history') history(@Query() q: { page?: string; limit?: string }) { return this.svc.customerHistory(principal().id!, q); }
}

@ApiTags('cafe-orders')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe/orders')
export class CafeOrderController {
  constructor(private readonly svc: OrderingService) {}
  @Get() @Requires('orders.read') list(@Query() q: Record<string, string>) { return this.svc.list(q); }
  @Post() @Requires('orders.create') create(@Body() dto: StaffOrderDto, @Headers('idempotency-key') key?: string) { return this.svc.place(dto, key); }
  @Get(':id') @Requires('orders.read') get(@Param('id') id: string) { return this.svc.getStaff(id); }
  @Post(':id/status') @Requires('orders.update') status(@Param('id') id: string, @Body() d: TransitionDto) { return this.svc.staffTransition(id, d.status, d.reason); }
  @Patch(':id/items/:itemId') @Requires('orders.update') modify(@Param('id') id: string, @Param('itemId', ParseIntPipe) itemId: number, @Body() d: ModifyItemDto) { return this.svc.modifyItem(id, itemId, d); }
}
