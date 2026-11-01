import { Body, Controller, Delete, Get, Param, Patch, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsBoolean, IsIn, IsInt, IsISO8601, IsOptional, IsString, Length, Matches, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { Audiences, RateLimit, Requires } from '../../common/http';
import { TableSessionRoute } from '../identity/auth.guard';
import { MarketingService } from './marketing.service';

const AMOUNT = /^\d{1,15}(\.\d{1,4})?$/;
const PERCENT = /^\d{1,3}(\.\d{1,2})?$/;

export class CouponDto {
  @IsString() @MaxLength(40) code: string;
  @IsIn(['percent', 'fixed']) discountType: 'percent' | 'fixed';
  @IsOptional() @Matches(PERCENT) percentValue?: string;
  @IsOptional() @Matches(AMOUNT) fixedAmount?: string;
  @IsOptional() @Matches(AMOUNT) maxDiscountAmount?: string;
  @IsOptional() @Matches(AMOUNT) minOrderAmount?: string;
  @IsOptional() @IsInt() @Min(1) maxRedemptions?: number;
  @IsOptional() @IsInt() @Min(1) maxPerCustomer?: number;
  @IsOptional() @IsISO8601() startsAt?: string;
  @IsOptional() @IsISO8601() endsAt?: string;
}
export class ToggleDto { @IsBoolean() isActive: boolean; }
class PromoTrDto {
  @IsString() @MaxLength(12) language: string;
  @IsString() @MaxLength(150) title: string;
  @IsOptional() @IsString() @MaxLength(2000) description?: string;
}
export class PromotionDto {
  @IsIn(['percent', 'fixed']) discountType: 'percent' | 'fixed';
  @IsOptional() @Matches(PERCENT) percentValue?: string;
  @IsOptional() @Matches(AMOUNT) fixedAmount?: string;
  @IsOptional() @IsISO8601() startsAt?: string;
  @IsOptional() @IsISO8601() endsAt?: string;
  @IsOptional() @IsInt() priority?: number;
  @IsArray() @ValidateNested({ each: true }) @Type(() => PromoTrDto) translations: PromoTrDto[];
  @IsOptional() @IsArray() @ArrayMaxSize(500) @IsString({ each: true }) productIds?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(100) @IsString({ each: true }) categoryIds?: string[];
}
export class LoyaltyDto {
  @IsBoolean() isActive: boolean;
  @Matches(/^\d{1,8}(\.\d{1,4})?$/) pointsPerCurrencyUnit: string;
  @Matches(AMOUNT) currencyValuePerPoint: string;
  @IsOptional() @IsInt() @Min(0) minRedeemPoints?: number;
  @IsOptional() @IsInt() @Min(1) pointsExpiryDays?: number;
}
export class ReviewDto {
  @IsInt() @Min(1) @Max(5) rating: number;
  @IsOptional() @IsString() @MaxLength(2000) comment?: string;
}
export class ReplyDto { @IsString() @Length(1, 2000) text: string; }

@ApiTags('customer-reviews')
@Controller('customer')
export class CustomerReviewController {
  constructor(private readonly svc: MarketingService) {}
  @Post('orders/:id/review') @TableSessionRoute() @RateLimit(10) review(@Param('id') id: string, @Body() d: ReviewDto) { return this.svc.review(id, d); }
}

@ApiTags('cafe-marketing')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class MarketingController {
  constructor(private readonly svc: MarketingService) {}
  @Get('coupons') @Requires('marketing.manage') coupons() { return this.svc.coupons(); }
  @Post('coupons') @Requires('marketing.manage') coupon(@Body() d: CouponDto) { return this.svc.createCoupon(d); }
  @Patch('coupons/:id') @Requires('marketing.manage') toggle(@Param('id') id: string, @Body() d: ToggleDto) { return this.svc.updateCoupon(id, d.isActive); }
  @Delete('coupons/:id') @Requires('marketing.manage') del(@Param('id') id: string) { return this.svc.deleteCoupon(id); }
  @Get('promotions') @Requires('marketing.manage') promotions() { return this.svc.promotions(); }
  @Post('promotions') @Requires('marketing.manage') promotion(@Body() d: PromotionDto) { return this.svc.createPromotion(d); }
  @Delete('promotions/:id') @Requires('marketing.manage') delPromo(@Param('id') id: string) { return this.svc.deletePromotion(id); }
  @Get('loyalty-program') @Requires('marketing.manage') loyalty() { return this.svc.loyaltyProgram(); }
  @Put('loyalty-program') @Requires('marketing.manage') saveLoyalty(@Body() d: LoyaltyDto) { return this.svc.saveLoyalty(d); }
  @Get('reviews') @Requires('marketing.manage') reviews() { return this.svc.reviews(); }
  @Post('reviews/:id/reply') @Requires('marketing.manage') reply(@Param('id') id: string, @Body() d: ReplyDto) { return this.svc.reply(id, d.text); }
}
