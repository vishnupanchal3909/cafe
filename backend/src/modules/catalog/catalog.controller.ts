import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsBoolean, IsDateString, IsDecimal, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, Length, Matches, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { currentLang } from '../../common/context';
import { Audiences, Public, Requires } from '../../common/http';
import { CatalogService } from './catalog.service';

const AMOUNT = /^\d{1,15}(\.\d{1,4})?$/;
const TIME = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

export class TranslationDto {
  @IsString() @MaxLength(12) language: string;
  @IsString() @IsNotEmpty() @MaxLength(200) name: string;
  @IsOptional() @IsString() @MaxLength(4000) description?: string;
}
class Trs { @IsArray() @ArrayMaxSize(50) @ValidateNested({ each: true }) @Type(() => TranslationDto) translations: TranslationDto[]; }
export class CreateCategoryDto extends Trs {
  @IsOptional() @IsInt() sortOrder?: number;
  @IsOptional() @IsString() @Length(26, 26) parentId?: string;
}
export class UpdateCategoryDto {
  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => TranslationDto) translations?: TranslationDto[];
  @IsOptional() @IsInt() sortOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
export class CreateProductDto extends Trs {
  @IsString() @Length(26, 26) categoryId: string;
  @Matches(AMOUNT) basePrice: string;
  @IsOptional() @IsIn(['veg', 'non_veg', 'egg', 'vegan', 'not_applicable']) dietaryClass?: 'veg';
  @IsOptional() @IsString() @MaxLength(32) taxCategoryId?: string;
  @IsOptional() @IsString() @MaxLength(64) sku?: string;
  @IsOptional() @IsInt() @Min(0) @Max(600) prepMinutes?: number;
  @IsOptional() @IsIn(['simple', 'combo']) productType?: 'simple';
  @IsOptional() @IsInt() sortOrder?: number;
}
export class UpdateProductDto {
  @IsOptional() @IsString() @Length(26, 26) categoryId?: string;
  @IsOptional() @Matches(AMOUNT) basePrice?: string;
  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => TranslationDto) translations?: TranslationDto[];
  @IsOptional() @IsIn(['veg', 'non_veg', 'egg', 'vegan', 'not_applicable']) dietaryClass?: 'veg';
  @IsOptional() @IsString() @MaxLength(32) taxCategoryId?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsBoolean() isOutOfStock?: boolean;
  @IsOptional() @IsInt() @Min(0) @Max(600) prepMinutes?: number;
  @IsOptional() @IsInt() sortOrder?: number;
}
export class VariantDto extends Trs {
  @Matches(AMOUNT) price: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsOptional() @IsString() @MaxLength(64) sku?: string;
}
class AddonDto extends Trs { @Matches(AMOUNT) price: string; }
export class AddonGroupDto extends Trs {
  @IsOptional() @IsInt() @Min(0) minSelect?: number;
  @IsOptional() @IsInt() @Min(0) maxSelect?: number;
  @IsArray() @ValidateNested({ each: true }) @Type(() => AddonDto) addons: AddonDto[];
}
export class IdsDto { @IsArray() @ArrayMaxSize(100) @IsString({ each: true }) ids: string[]; }
class ComboItemDto {
  @IsString() @Length(26, 26) productId: string;
  @IsOptional() @IsString() @Length(26, 26) variantId?: string;
  @IsInt() @Min(1) quantity: number;
}
export class ComboDto { @IsArray() @ValidateNested({ each: true }) @Type(() => ComboItemDto) items: ComboItemDto[]; }
class WindowDto {
  @IsOptional() @IsInt() @Min(0) @Max(6) weekday?: number;
  @Matches(TIME) startsAt: string;
  @Matches(TIME) endsAt: string;
}
export class ScheduleDto { @IsArray() @ValidateNested({ each: true }) @Type(() => WindowDto) windows: WindowDto[]; }
export class OverrideDto {
  @IsOptional() @Matches(AMOUNT) price?: string | null;
  @IsOptional() @IsBoolean() isAvailable?: boolean | null;
}
export class AssetDto { @IsString() @Length(26, 26) assetId: string; }
export class TaxCategoryDto {
  @IsString() @MaxLength(32) code: string;
  @IsString() @MaxLength(100) name: string;
  @IsOptional() @IsString() @MaxLength(20) taxCode?: string;
}
export class TaxRateDto {
  @IsString() @MaxLength(16) componentCode: string;
  @IsString() @MaxLength(60) displayName: string;
  @IsDecimal({ decimal_digits: '0,6' }) ratePercent: string;
  @IsOptional() @IsIn(['always', 'intra_region', 'inter_region']) appliesTo?: 'always';
  @IsDateString() validFrom: string;
}
export class TaxRegistrationDto {
  @IsOptional() @IsString() @Length(26, 26) branchId?: string;
  @IsString() @MaxLength(32) taxSystem: string;
  @IsString() @MaxLength(64) registrationNumber: string;
  @IsString() @MaxLength(200) legalName: string;
  @IsOptional() @IsString() @MaxLength(10) regionCode?: string;
  @IsDateString() validFrom: string;
}

@ApiTags('public')
@Controller('public')
export class PublicMenuController {
  constructor(private readonly svc: CatalogService) {}
  @Get('cafes/:slug/menu') @Public()
  menu(@Param('slug') slug: string, @Query('lang') lang?: string, @Query('branch') branch?: string) { return this.svc.publicMenu(slug, lang ?? currentLang(), branch); }
}

@ApiTags('cafe-menu')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class CatalogController {
  constructor(private readonly svc: CatalogService) {}
  @Get('menu') @Requires('menu.read') menu() { return this.svc.staffProducts(); }
  @Get('categories') @Requires('menu.read') categories() { return this.svc.listCategories(); }
  @Post('categories') @Requires('menu.manage') createCategory(@Body() d: CreateCategoryDto) { return this.svc.createCategory(d); }
  @Patch('categories/:id') @Requires('menu.manage') updateCategory(@Param('id') id: string, @Body() d: UpdateCategoryDto) { return this.svc.updateCategory(id, d); }
  @Delete('categories/:id') @Requires('menu.manage') deleteCategory(@Param('id') id: string) { return this.svc.deleteCategory(id); }
  @Post('products') @Requires('menu.manage') createProduct(@Body() d: CreateProductDto) { return this.svc.createProduct(d); }
  @Patch('products/:id') @Requires('menu.manage') updateProduct(@Param('id') id: string, @Body() d: UpdateProductDto) { return this.svc.updateProduct(id, d); }
  @Delete('products/:id') @Requires('menu.manage') deleteProduct(@Param('id') id: string) { return this.svc.deleteProduct(id); }
  @Post('products/:id/variants') @Requires('menu.manage') addVariant(@Param('id') id: string, @Body() d: VariantDto) { return this.svc.addVariant(id, d); }
  @Delete('variants/:id') @Requires('menu.manage') delVariant(@Param('id') id: string) { return this.svc.deleteVariant(id); }
  @Put('products/:id/image') @Requires('menu.manage') setImage(@Param('id') id: string, @Body() d: AssetDto) { return this.svc.setProductImage(id, d.assetId); }
  @Delete('products/:id/image') @Requires('menu.manage') removeImage(@Param('id') id: string) { return this.svc.removeProductImage(id); }
  @Post('products/:id/images') @Requires('menu.manage') addImage(@Param('id') id: string, @Body() d: AssetDto) { return this.svc.addProductImage(id, d.assetId); }
  @Post('addon-groups') @Requires('menu.manage') addonGroup(@Body() d: AddonGroupDto) { return this.svc.createAddonGroup(d); }
  @Put('products/:id/addon-groups') @Requires('menu.manage') linkGroups(@Param('id') id: string, @Body() d: IdsDto) { return this.svc.setProductAddonGroups(id, d.ids); }
  @Put('products/:id/combo-items') @Requires('menu.manage') combo(@Param('id') id: string, @Body() d: ComboDto) { return this.svc.setComboItems(id, d.items); }
  @Put('products/:id/schedules') @Requires('menu.manage') schedules(@Param('id') id: string, @Body() d: ScheduleDto) { return this.svc.setSchedules(id, d.windows); }
  @Put('branches/:branch/product-overrides/:product') @Requires('menu.manage') override(@Param('branch') b: string, @Param('product') p: string, @Body() d: OverrideDto) { return this.svc.setBranchOverride(b, p, d); }
  @Get('tax-categories') @Requires('menu.read') taxCategories() { return this.svc.listTaxCategories(); }
  @Post('tax-categories') @Requires('tax.manage') createTaxCategory(@Body() d: TaxCategoryDto) { return this.svc.createTaxCategory(d); }
  @Post('tax-categories/:code/rates') @Requires('tax.manage') addRate(@Param('code') code: string, @Body() d: TaxRateDto) { return this.svc.addTaxRate(code, d); }
  @Post('tax-registrations') @Requires('tax.manage') addRegistration(@Body() d: TaxRegistrationDto) { return this.svc.addTaxRegistration(d); }
}
