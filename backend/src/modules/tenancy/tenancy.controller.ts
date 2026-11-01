import { Body, Controller, Delete, Get, Headers, Param, Patch, Post, Put, Query, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsEmail, IsIn, IsInt, IsISO8601, IsOptional, IsString, Length, Matches, Max, MaxLength, Min, MinLength, ValidateNested } from 'class-validator';
import type { Response } from 'express';
import { currentLang } from '../../common/context';
import { Audiences, Public, RateLimit, RawResponse, Requires } from '../../common/http';
import { TenancyService } from './tenancy.service';

const HEX = /^#[0-9A-Fa-f]{6}$/;
const TIME = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

class OwnerDto {
  @IsEmail() @MaxLength(254) email: string;
  @IsString() @MinLength(10) @MaxLength(200) password: string;
  @IsString() @MinLength(1) @MaxLength(150) fullName: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
}
class CafeDto {
  @IsString() @MinLength(1) @MaxLength(150) name: string;
  @IsString() @MinLength(1) @MaxLength(200) legalName: string;
  @IsOptional() @IsString() @MaxLength(2000) description?: string;
  @IsString() @Length(2, 2) countryCode: string;
  @IsString() @Length(3, 3) currencyCode: string;
  @IsString() @MaxLength(12) defaultLanguage: string;
  @IsString() @MaxLength(64) timezone: string;
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) supportedLanguages?: string[];
  @IsOptional() @IsEmail() contactEmail?: string;
  @IsOptional() @IsString() @MaxLength(20) contactPhone?: string;
  @IsOptional() @IsString() @MaxLength(64) businessRegistrationNumber?: string;
}
class BranchInitDto {
  @IsString() @MinLength(1) @MaxLength(150) name: string;
  @IsString() @MinLength(1) @MaxLength(200) addressLine1: string;
  @IsOptional() @IsString() @MaxLength(200) addressLine2?: string;
  @IsString() @MinLength(1) @MaxLength(100) city: string;
  @IsOptional() @IsString() @MaxLength(10) stateCode?: string;
  @IsOptional() @IsString() @MaxLength(100) stateName?: string;
  @IsOptional() @IsString() @MaxLength(20) postalCode?: string;
}
export class RegisterCafeDto {
  @ValidateNested() @Type(() => OwnerDto) owner: OwnerDto;
  @ValidateNested() @Type(() => CafeDto) cafe: CafeDto;
  @ValidateNested() @Type(() => BranchInitDto) branch: BranchInitDto;
}
export class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(150) name?: string;
  @IsOptional() @IsString() @MaxLength(200) legalName?: string;
  @IsOptional() @IsString() @MaxLength(2000) description?: string;
  @IsOptional() @IsEmail() contactEmail?: string;
  @IsOptional() @IsString() @MaxLength(20) contactPhone?: string;
  @IsOptional() @IsString() @MaxLength(255) website?: string;
  @IsOptional() @IsString() @MaxLength(64) businessRegistrationNumber?: string;
  @IsOptional() @IsString() @MaxLength(64) timezone?: string;
  @IsOptional() @IsInt() @Min(1) @Max(12) fiscalYearStartMonth?: number;
}
export class CreateBranchDto extends BranchInitDto {
  @IsString() @MinLength(1) @MaxLength(20) code: string;
  @IsOptional() @IsString() @MaxLength(64) timezone?: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
  @IsOptional() @Matches(TIME) businessDayCutoff?: string;
}
export class UpdateBranchDto {
  @IsOptional() @IsString() @MaxLength(150) name?: string;
  @IsOptional() @IsString() @MaxLength(200) addressLine1?: string;
  @IsOptional() @IsString() @MaxLength(100) city?: string;
  @IsOptional() @IsString() @MaxLength(10) stateCode?: string;
  @IsOptional() @IsString() @MaxLength(64) timezone?: string;
  @IsOptional() @Matches(TIME) businessDayCutoff?: string;
  @IsOptional() @IsIn(['active', 'inactive']) status?: 'active' | 'inactive';
}
class HoursDto {
  @IsInt() @Min(0) @Max(6) weekday: number;
  @Matches(TIME) opensAt: string;
  @Matches(TIME) closesAt: string;
  @IsOptional() closesNextDay?: boolean;
}
export class SetHoursDto { @IsArray() @ValidateNested({ each: true }) @Type(() => HoursDto) hours: HoursDto[]; }
export class SetLanguagesDto { @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) languages: string[]; }
export class ThemeDto {
  @IsOptional() @Matches(HEX) primaryColor?: string;
  @IsOptional() @Matches(HEX) secondaryColor?: string;
  @IsOptional() @Matches(HEX) backgroundColor?: string;
  @IsOptional() @Matches(HEX) textColor?: string;
  @IsOptional() @IsIn(['noto_sans', 'noto_serif', 'noto_sans_arabic', 'noto_sans_devanagari', 'noto_sans_jp']) fontKey?: string;
  @IsOptional() @IsIn(['rounded', 'pill', 'square']) buttonStyle?: 'rounded' | 'pill' | 'square';
  @IsOptional() @IsIn(['list', 'grid', 'compact']) menuLayout?: 'list' | 'grid' | 'compact';
  @IsOptional() @IsIn(['light', 'dark', 'system']) themeMode?: 'light' | 'dark' | 'system';
  @IsOptional() @IsString() @Length(26, 26) logoAssetId?: string;
  @IsOptional() @IsString() @Length(26, 26) coverAssetId?: string;
}
class BannerTranslationDto {
  @IsString() @MaxLength(12) language: string;
  @IsString() @MaxLength(150) title: string;
  @IsOptional() @IsString() @MaxLength(300) subtitle?: string;
}
export class CreateBannerDto {
  @IsString() @Length(26, 26) assetId: string;
  @IsOptional() @IsIn(['cover', 'promotional']) placement?: 'cover' | 'promotional';
  @IsArray() @ValidateNested({ each: true }) @Type(() => BannerTranslationDto) translations: BannerTranslationDto[];
  @IsOptional() @IsISO8601() startsAt?: string;
  @IsOptional() @IsISO8601() endsAt?: string;
}

@ApiTags('public')
@Controller('public')
export class PublicCafeController {
  constructor(private readonly svc: TenancyService) {}
  @Post('cafes/register') @Public() @RateLimit(5, 3600)
  register(@Body() dto: RegisterCafeDto) { return this.svc.register(dto); }
  @Get('reference') @Public()
  reference() { return this.svc.referenceData(); }
  @Get('cafes/:slug/config') @Public()
  config(@Param('slug') slug: string, @Query('lang') lang?: string) { return this.svc.publicConfig(slug, lang ?? currentLang()); }
  @Get('media/:id') @Public() @RawResponse()
  async media(@Param('id') id: string, @Res() res: Response) {
    const { body, mime } = await this.svc.publicMedia(id);
    res.setHeader('Content-Type', mime);
    res.setHeader('Cache-Control', 'public, max-age=86400, immutable');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.send(body);
  }
}

@ApiTags('cafe')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class CafeController {
  constructor(private readonly svc: TenancyService) {}
  @Get('profile') @Requires('cafe.profile.read') profile() { return this.svc.profile(); }
  @Patch('profile') @Requires('cafe.profile.manage') update(@Body() dto: UpdateProfileDto) { return this.svc.updateProfile(dto); }
  @Get('branches') @Requires('cafe.profile.read') branches() { return this.svc.branches(); }
  @Post('branches') @Requires('cafe.profile.manage') createBranch(@Body() dto: CreateBranchDto) { return this.svc.createBranch(dto); }
  @Patch('branches/:id') @Requires('cafe.profile.manage')
  updateBranch(@Param('id') id: string, @Body() d: UpdateBranchDto) {
    return this.svc.updateBranch(id, { name: d.name, address_line1: d.addressLine1, city: d.city, state_code: d.stateCode, timezone: d.timezone, business_day_cutoff: d.businessDayCutoff, status: d.status });
  }
  @Get('branches/:id/hours') @Requires('cafe.profile.read') hours(@Param('id') id: string) { return this.svc.hours(id); }
  @Put('branches/:id/hours') @Requires('cafe.profile.manage') setHours(@Param('id') id: string, @Body() dto: SetHoursDto) { return this.svc.setHours(id, dto.hours); }
  @Put('languages') @Requires('cafe.profile.manage') languages(@Body() dto: SetLanguagesDto) { return this.svc.setLanguages(dto.languages); }
  @Get('settings') @Requires('cafe.profile.read') settings() { return this.svc.settings(); }
  @Patch('settings') @Requires('cafe.profile.manage') updateSettings(@Body() body: Record<string, unknown>) { return this.svc.updateSettings(body); }
  @Get('theme') @Requires('cafe.profile.read') theme() { return this.svc.theme(); }
  @Put('theme') @Requires('cafe.branding.manage') setTheme(@Body() dto: ThemeDto) { return this.svc.updateTheme(dto); }
  @Post('banners') @Requires('cafe.branding.manage') banner(@Body() dto: CreateBannerDto) { return this.svc.createBanner(dto); }
  @Delete('banners/:id') @Requires('cafe.branding.manage') delBanner(@Param('id') id: string) { return this.svc.deleteBanner(id); }
  @Post('media') @Requires('cafe.branding.manage') @RateLimit(30)
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  upload(@UploadedFile() file: Express.Multer.File, @Query('kind') kind: string) {
    return this.svc.upload(file, (['logo', 'cover', 'banner', 'product_image'].includes(kind) ? kind : 'product_image') as 'logo');
  }
}
