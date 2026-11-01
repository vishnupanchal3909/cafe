import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsBoolean, IsDateString, IsEmail, IsIn, IsInt, IsOptional, IsString, Length, Matches, MaxLength, Min, MinLength, ValidateNested } from 'class-validator';
import { Audiences, Requires } from '../../common/http';
import { InventoryService } from './inventory.service';

const QTY = /^\d{1,14}(\.\d{1,4})?$/;
const SIGNED_QTY = /^-?\d{1,14}(\.\d{1,4})?$/;
const COST = /^\d{1,13}(\.\d{1,6})?$/;

export class IngredientDto {
  @IsString() @MinLength(1) @MaxLength(150) name: string;
  @IsString() @MaxLength(12) unitCode: string;
  @IsOptional() @IsString() @MaxLength(64) sku?: string;
  @IsOptional() @IsBoolean() isPerishable?: boolean;
}
class RecipeItemDto {
  @IsString() @Length(26, 26) ingredientId: string;
  @Matches(QTY) quantity: string;
  @IsOptional() @Matches(/^\d{1,3}(\.\d{1,2})?$/) wastePercent?: string;
}
export class RecipeDto {
  @IsOptional() @IsString() @Length(26, 26) variantId?: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => RecipeItemDto) items: RecipeItemDto[];
}
export class StockMoveDto {
  @IsString() @Length(26, 26) ingredientId: string;
  @IsIn(['stock_in', 'stock_out', 'adjustment', 'wastage']) type: 'stock_in';
  @Matches(SIGNED_QTY) quantity: string;
  @IsOptional() @Matches(COST) unitCost?: string;
  @IsOptional() @IsString() @MaxLength(255) reason?: string;
  @IsOptional() @IsDateString() expiresOn?: string;
  @IsOptional() @IsString() @MaxLength(64) batchCode?: string;
}
export class ReorderDto { @IsOptional() @Matches(QTY) level?: string | null; }
export class SupplierDto {
  @IsString() @MinLength(1) @MaxLength(200) name: string;
  @IsOptional() @IsString() @MaxLength(150) contactName?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
  @IsOptional() @IsString() @MaxLength(500) address?: string;
  @IsOptional() @IsString() @MaxLength(64) taxRegistrationNumber?: string;
  @IsOptional() @IsInt() @Min(0) paymentTermsDays?: number;
}
class PoItemDto {
  @IsString() @Length(26, 26) ingredientId: string;
  @Matches(QTY) quantity: string;
  @Matches(COST) unitCost: string;
}
export class PurchaseOrderDto {
  @IsString() @Length(26, 26) supplierId: string;
  @IsOptional() @IsDateString() expectedOn?: string;
  @IsOptional() @IsString() @MaxLength(500) notes?: string;
  @IsArray() @ArrayMinSize(1) @ValidateNested({ each: true }) @Type(() => PoItemDto) items: PoItemDto[];
}
class ReceiveLineDto {
  @IsString() @Length(26, 26) ingredientId: string;
  @Matches(QTY) quantity: string;
  @IsOptional() @IsDateString() expiresOn?: string;
  @IsOptional() @IsString() @MaxLength(64) batchCode?: string;
}
export class ReceiveDto { @IsArray() @ArrayMinSize(1) @ValidateNested({ each: true }) @Type(() => ReceiveLineDto) lines: ReceiveLineDto[]; }
export class SupplierInvoiceDto {
  @IsString() @Length(26, 26) supplierId: string;
  @IsOptional() @IsString() @Length(26, 26) purchaseOrderId?: string;
  @IsString() @MaxLength(64) number: string;
  @Matches(/^\d{1,15}(\.\d{1,4})?$/) subtotal: string;
  @IsOptional() @Matches(/^\d{1,15}(\.\d{1,4})?$/) tax?: string;
  @IsDateString() invoiceDate: string;
  @IsOptional() @IsDateString() dueOn?: string;
}
export class SupplierPaymentDto {
  @Matches(/^\d{1,15}(\.\d{1,4})?$/) amount: string;
  @IsString() @MaxLength(32) methodCode: string;
  @IsOptional() @IsString() @MaxLength(100) reference?: string;
  @IsDateString() paidOn: string;
}

@ApiTags('cafe-inventory')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class InventoryController {
  constructor(private readonly svc: InventoryService) {}
  @Get('ingredients') @Requires('inventory.read') ingredients() { return this.svc.listIngredients(); }
  @Post('ingredients') @Requires('inventory.manage') createIngredient(@Body() d: IngredientDto) { return this.svc.createIngredient(d); }
  @Delete('ingredients/:id') @Requires('inventory.manage') deleteIngredient(@Param('id') id: string) { return this.svc.deleteIngredient(id); }
  @Get('products/:id/recipe') @Requires('inventory.read') recipe(@Param('id') id: string) { return this.svc.getRecipe(id); }
  @Put('products/:id/recipe') @Requires('inventory.manage') setRecipe(@Param('id') id: string, @Body() d: RecipeDto) { return this.svc.setRecipe(id, d.variantId, d.items); }
  @Get('stock') @Requires('inventory.read') stock() { return this.svc.stock(); }
  @Post('stock/movements') @Requires('inventory.manage') move(@Body() d: StockMoveDto) { return this.svc.record(d); }
  @Get('stock/movements') @Requires('inventory.read') movements(@Query('ingredient') i?: string) { return this.svc.movements(i); }
  @Get('stock/valuation') @Requires('inventory.read') valuation() { return this.svc.valuation(); }
  @Get('stock/expiring') @Requires('inventory.read') expiring(@Query('days') d?: string) { return this.svc.expiring(Number(d) || 7); }
  @Patch('stock/:ingredient/reorder-level') @Requires('inventory.manage') reorder(@Param('ingredient') id: string, @Body() d: ReorderDto) { return this.svc.setReorderLevel(id, d.level ?? null); }
  @Get('suppliers') @Requires('inventory.read') suppliers() { return this.svc.suppliers(); }
  @Post('suppliers') @Requires('inventory.manage') supplier(@Body() d: SupplierDto) { return this.svc.createSupplier(d); }
  @Delete('suppliers/:id') @Requires('inventory.manage') delSupplier(@Param('id') id: string) { return this.svc.deleteSupplier(id); }
  @Get('purchase-orders') @Requires('inventory.read') pos() { return this.svc.listPurchaseOrders(); }
  @Post('purchase-orders') @Requires('inventory.manage') po(@Body() d: PurchaseOrderDto) { return this.svc.createPurchaseOrder(d); }
  @Get('purchase-orders/:id') @Requires('inventory.read') getPo(@Param('id') id: string) { return this.svc.getPurchaseOrder(id); }
  @Post('purchase-orders/:id/receive') @Requires('inventory.manage') receive(@Param('id') id: string, @Body() d: ReceiveDto) { return this.svc.receivePurchaseOrder(id, d.lines); }
  @Get('supplier-invoices') @Requires('finance.read') invoices() { return this.svc.listSupplierInvoices(); }
  @Post('supplier-invoices') @Requires('finance.manage') invoice(@Body() d: SupplierInvoiceDto) { return this.svc.createSupplierInvoice(d); }
  @Post('supplier-invoices/:id/payments') @Requires('finance.manage') payInvoice(@Param('id') id: string, @Body() d: SupplierPaymentDto) { return this.svc.paySupplierInvoice(id, d); }
}
