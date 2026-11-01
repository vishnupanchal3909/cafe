import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsISO8601, IsOptional, IsString, Length, MaxLength, Min } from 'class-validator';
import { Audiences, Requires } from '../../common/http';
import { CustomersService } from './customers.service';

export class ProfileDto {
  @IsOptional() @IsString() @MaxLength(150) fullName?: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
  @IsOptional() @IsString() @MaxLength(12) language?: string;
}
export class AddressDto {
  @IsOptional() @IsString() @MaxLength(40) label?: string;
  @IsString() @MaxLength(200) addressLine1: string;
  @IsOptional() @IsString() @MaxLength(200) addressLine2?: string;
  @IsString() @MaxLength(100) city: string;
  @IsOptional() @IsString() @MaxLength(100) stateName?: string;
  @IsOptional() @IsString() @MaxLength(20) postalCode?: string;
  @IsString() @Length(2, 2) countryCode: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
}
export class CustomerReservationDto {
  @IsString() @Length(26, 26) branchId: string;
  @IsInt() @Min(1) partySize: number;
  @IsISO8601() startsAt: string;
  @IsISO8601() endsAt: string;
  @IsOptional() @IsString() @MaxLength(500) notes?: string;
}

@ApiTags('customer-account')
@ApiBearerAuth()
@Audiences('customer')
@Controller('customer')
export class CustomerAccountController {
  constructor(private readonly svc: CustomersService) {}
  @Get('profile') profile() { return this.svc.profile(); }
  @Patch('profile') update(@Body() d: ProfileDto) { return this.svc.updateProfile(d); }
  @Delete('account') remove() { return this.svc.deleteAccount(); }
  @Get('addresses') addresses() { return this.svc.addresses(); }
  @Post('addresses') addAddress(@Body() d: AddressDto) { return this.svc.addAddress(d); }
  @Delete('addresses/:id') removeAddress(@Param('id') id: string) { return this.svc.removeAddress(id); }
  @Get('favorites') favorites() { return this.svc.favorites(); }
  @Post('favorites/:slug') favorite(@Param('slug') slug: string) { return this.svc.addFavorite(slug); }
  @Delete('favorites/:slug') unfavorite(@Param('slug') slug: string) { return this.svc.removeFavorite(slug); }
  @Get('cafes/:slug/wishlist') wishlist(@Param('slug') slug: string) { return this.svc.wishlist(slug); }
  @Post('cafes/:slug/wishlist/:product') wish(@Param('slug') slug: string, @Param('product') p: string) { return this.svc.addWish(slug, p); }
  @Delete('cafes/:slug/wishlist/:product') unwish(@Param('slug') slug: string, @Param('product') p: string) { return this.svc.removeWish(slug, p); }
  @Get('cafes/:slug/loyalty') loyalty(@Param('slug') slug: string) { return this.svc.loyalty(slug); }
  @Post('cafes/:slug/reservations') reserve(@Param('slug') slug: string, @Body() d: CustomerReservationDto) { return this.svc.reserve(slug, d.branchId, d); }
}

@ApiTags('cafe-customers')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class CafeCustomersController {
  constructor(private readonly svc: CustomersService) {}
  @Get('customers') @Requires('customers.read') list(@Query() q: { page?: string; limit?: string }) { return this.svc.cafeList(q); }
}
