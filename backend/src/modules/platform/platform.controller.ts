import { Body, Controller, Get, Headers, Param, Post, Put, Query, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsIn, IsInt, IsISO8601, IsOptional, IsString, Length, Matches, Max, MaxLength, Min, MinLength, ValidateNested } from 'class-validator';
import { currentLang } from '../../common/context';
import { Audiences, Public, Requires } from '../../common/http';
import { PlatformService } from './platform.service';

export class CafeStatusDto {
  @IsIn(['active', 'suspended', 'rejected', 'closed']) status: 'active';
  @IsString() @MinLength(3) @MaxLength(500) reason: string;
}
export class UserStatusDto {
  @IsIn(['active', 'disabled']) status: 'active';
  @IsString() @MinLength(3) @MaxLength(500) reason: string;
}
export class LanguageDto {
  @IsString() @MaxLength(12) code: string;
  @IsString() @MaxLength(64) name: string;
  @IsString() @MaxLength(64) nativeName: string;
  @IsIn(['ltr', 'rtl']) direction: 'ltr';
  @IsOptional() @IsBoolean() isActive?: boolean;
}
export class CurrencyDto {
  @Matches(/^[A-Z]{3}$/) code: string;
  @Matches(/^\d{3}$/) numericCode: string;
  @IsString() @MaxLength(64) name: string;
  @IsString() @MaxLength(8) symbol: string;
  @IsInt() @Min(0) @Max(4) minorUnit: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
export class CountryDto {
  @Matches(/^[A-Z]{2}$/) code: string;
  @IsString() @MaxLength(100) name: string;
  @IsString() @Length(3, 3) defaultCurrency: string;
  @IsString() @MaxLength(12) defaultLanguage: string;
  @IsString() @MaxLength(64) defaultTimezone: string;
  @IsOptional() @IsInt() @Min(1) @Max(12) fiscalYearStartMonth?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
export class ExchangeRateDto {
  @Matches(/^[A-Z]{3}$/) base: string;
  @Matches(/^[A-Z]{3}$/) quote: string;
  @Matches(/^\d{1,14}(\.\d{1,10})?$/) rate: string;
  @IsString() @MaxLength(64) provider: string;
  @IsISO8601() effectiveAt: string;
}
export class TranslationKeyDto {
  @IsString() @MaxLength(64) namespace: string;
  @IsString() @MaxLength(191) key: string;
  @IsString() @MaxLength(12) language: string;
  @IsString() @MaxLength(5000) value: string;
  @IsOptional() @IsBoolean() isReviewed?: boolean;
}
export class SettingDto { value: unknown; @IsOptional() @IsString() @MaxLength(255) description?: string; }
export class CommissionDto {
  @IsOptional() @IsString() @Length(26, 26) cafeId?: string;
  @Matches(/^\d{1,3}(\.\d{1,6})?$/) ratePercent: string;
  @IsISO8601() validFrom: string;
}
class AnnouncementTrDto {
  @IsString() @MaxLength(12) language: string;
  @IsString() @MaxLength(200) title: string;
  @IsString() @MaxLength(5000) body: string;
}
export class AnnouncementDto {
  @IsIn(['all_cafes', 'owners', 'customers']) audience: 'all_cafes';
  @IsISO8601() startsAt: string;
  @IsOptional() @IsISO8601() endsAt?: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => AnnouncementTrDto) translations: AnnouncementTrDto[];
}
export class TicketReplyDto {
  @IsString() @MinLength(1) @MaxLength(5000) body: string;
  @IsOptional() @IsBoolean() internal?: boolean;
  @IsOptional() @IsIn(['open', 'in_progress', 'waiting_on_cafe', 'resolved', 'closed']) status?: 'open';
}
export class NewTicketDto {
  @IsString() @MinLength(3) @MaxLength(200) subject: string;
  @IsString() @MinLength(1) @MaxLength(5000) body: string;
  @IsOptional() @IsIn(['low', 'normal', 'high', 'urgent']) priority?: 'low';
}
export class CafeTicketReplyDto { @IsString() @MinLength(1) @MaxLength(5000) body: string; }

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly svc: PlatformService) {}
  @Get() @Public() ping() { return this.svc.ping(); }
}

@ApiTags('platform')
@ApiBearerAuth()
@Audiences('platform')
@Controller('platform')
export class PlatformController {
  constructor(private readonly svc: PlatformService) {}
  @Get('cafes') @Requires('platform.cafes.read') cafes(@Query() q: Record<string, string>) { return this.svc.listCafes(q); }
  @Get('cafes/:id') @Requires('platform.cafes.read') cafe(@Param('id') id: string, @Headers('x-access-reason') r?: string) { return this.svc.cafeDetail(id, r); }
  @Get('cafes/:id/orders') @Requires('platform.cafes.read') cafeOrders(@Param('id') id: string, @Query() q: Record<string, string>, @Headers('x-access-reason') r?: string) { return this.svc.cafeOrders(id, q, r); }
  @Get('cafes/:id/finance') @Requires('platform.finance.read') cafeFinance(@Param('id') id: string, @Headers('x-access-reason') r?: string) { return this.svc.cafeFinance(id, r); }
  @Post('cafes/:id/status') @Requires('platform.cafes.manage') status(@Param('id') id: string, @Body() d: CafeStatusDto) { return this.svc.setStatus(id, d.status, d.reason); }
  @Get('users') @Requires('platform.users.manage') users(@Query() q: Record<string, string>) { return this.svc.users(q); }
  @Post('users/:id/status') @Requires('platform.users.manage') userStatus(@Param('id') id: string, @Body() d: UserStatusDto) { return this.svc.setUserStatus(id, d.status, d.reason); }
  @Get('languages') @Requires('platform.translations.manage') languages() { return this.svc.languages(); }
  @Put('languages') @Requires('platform.translations.manage') language(@Body() d: LanguageDto) { return this.svc.saveLanguage(d); }
  @Get('currencies') @Requires('platform.settings.manage') currencies() { return this.svc.currencies(); }
  @Put('currencies') @Requires('platform.settings.manage') currency(@Body() d: CurrencyDto) { return this.svc.saveCurrency(d); }
  @Get('countries') @Requires('platform.settings.manage') countries() { return this.svc.countries(); }
  @Put('countries') @Requires('platform.settings.manage') country(@Body() d: CountryDto) { return this.svc.saveCountry(d); }
  @Get('exchange-rates') @Requires('platform.settings.manage') rates(@Query('base') b?: string) { return this.svc.exchangeRates(b); }
  @Post('exchange-rates') @Requires('platform.settings.manage') rate(@Body() d: ExchangeRateDto) { return this.svc.addExchangeRate(d); }
  @Get('translations') @Requires('platform.translations.manage') translations(@Query('namespace') n?: string, @Query('language') l?: string) { return this.svc.translations(n, l); }
  @Put('translations') @Requires('platform.translations.manage') translation(@Body() d: TranslationKeyDto) { return this.svc.saveTranslation(d); }
  @Get('settings') @Requires('platform.settings.manage') settings() { return this.svc.settings(); }
  @Put('settings/:key') @Requires('platform.settings.manage') setting(@Param('key') k: string, @Body() d: SettingDto) { return this.svc.saveSetting(k, d.value, d.description); }
  @Get('commissions') @Requires('platform.commissions.manage') commissions() { return this.svc.commissions(); }
  @Post('commissions') @Requires('platform.commissions.manage') commission(@Body() d: CommissionDto) { return this.svc.addCommission(d); }
  @Get('announcements') @Requires('platform.announcements.manage') announcements() { return this.svc.announcements(); }
  @Post('announcements') @Requires('platform.announcements.manage') announce(@Body() d: AnnouncementDto) { return this.svc.createAnnouncement(d); }
  @Get('support-tickets') @Requires('platform.support.manage') tickets(@Query() q: Record<string, string>) { return this.svc.tickets(q); }
  @Get('support-tickets/:id') @Requires('platform.support.manage') ticket(@Param('id') id: string) { return this.svc.ticket(id); }
  @Post('support-tickets/:id/reply') @Requires('platform.support.manage') reply(@Param('id') id: string, @Body() d: TicketReplyDto) { return this.svc.replyTicket(id, d); }
  @Get('audit-logs') @Requires('platform.audit.read') audit(@Query() q: Record<string, string>) { return this.svc.auditLogs(q); }
  @Get('finance') @Requires('platform.finance.read') finance() { return this.svc.platformFinance(); }
  @Get('health') @Requires('platform.health.read') health() { return this.svc.health(); }
}

@ApiTags('cafe-platform')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class CafePlatformController {
  constructor(private readonly svc: PlatformService) {}
  @Get('announcements') announcements() { return this.svc.activeAnnouncements(currentLang()); }
  @Get('support-tickets') @Requires('support.use') tickets() { return this.svc.cafeTickets(); }
  @Post('support-tickets') @Requires('support.use') create(@Body() d: NewTicketDto) { return this.svc.cafeCreateTicket(d); }
  @Get('support-tickets/:id') @Requires('support.use') ticket(@Param('id') id: string) { return this.svc.cafeTicket(id); }
  @Post('support-tickets/:id/reply') @Requires('support.use') reply(@Param('id') id: string, @Body() d: CafeTicketReplyDto) { return this.svc.cafeReplyTicket(id, d.body); }
}
