import { Body, Controller, Get, Param, ParseIntPipe, Post, Query, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsDateString, IsIn, IsInt, IsOptional, IsString, Length, Matches, MaxLength, MinLength, ValidateNested } from 'class-validator';
import type { Response } from 'express';
import { Audiences, RawResponse, Requires } from '../../common/http';
import { AccountingService } from '../accounting/accounting.service';
import { FinanceService } from './finance.service';

const AMOUNT = /^\d{1,15}(\.\d{1,4})?$/;
const SIGNED = /^-?\d{1,15}(\.\d{1,4})?$/;

export class NameDto { @IsString() @MinLength(1) @MaxLength(100) name: string; @IsOptional() @IsString() @MaxLength(20) accountCode?: string; }
export class ExpenseDto {
  @IsInt() categoryId: number;
  @Matches(AMOUNT) amount: string;
  @IsOptional() @Matches(AMOUNT) taxAmount?: string;
  @IsDateString() date: string;
  @IsOptional() @IsString() @MaxLength(500) description?: string;
  @IsOptional() @IsString() @MaxLength(32) methodCode?: string;
}
export class ReasonDto { @IsString() @MinLength(3) @MaxLength(500) reason: string; }
export class ReverseDto extends ReasonDto { @IsOptional() @IsDateString() date?: string; }
export class OpenRegisterDto { @Matches(AMOUNT) floatAmount: string; }
export class RegisterTxDto {
  @IsIn(['pay_in', 'pay_out', 'adjustment']) type: 'pay_in' | 'pay_out' | 'adjustment';
  @Matches(SIGNED) amount: string;
  @IsString() @MinLength(3) @MaxLength(255) reason: string;
}
export class CloseRegisterDto { @Matches(AMOUNT) counted: string; }
export class PayrollDto {
  @IsString() @Length(26, 26) staffId: string;
  @IsDateString() periodStart: string;
  @IsDateString() periodEnd: string;
  @Matches(AMOUNT) gross: string;
  @IsOptional() @Matches(AMOUNT) deductions?: string;
  @IsOptional() @IsString() @MaxLength(500) notes?: string;
}
export class PayPayrollDto { @IsDateString() paidOn: string; @IsIn(['cash', 'bank']) method: 'cash' | 'bank'; }
export class AccountDto {
  @IsString() @MaxLength(20) code: string;
  @IsString() @MaxLength(120) name: string;
  @IsIn(['asset', 'liability', 'equity', 'revenue', 'expense']) accountType: 'asset';
}
export class PeriodDto { @IsString() @MaxLength(40) name: string; @IsDateString() startsOn: string; @IsDateString() endsOn: string; }
class JournalLineDto {
  @IsInt() accountId: number;
  @IsOptional() @Matches(AMOUNT) debit?: string;
  @IsOptional() @Matches(AMOUNT) credit?: string;
  @IsOptional() @IsString() @MaxLength(255) description?: string;
}
export class JournalDto {
  @IsDateString() date: string;
  @IsString() @MinLength(3) @MaxLength(500) memo: string;
  @IsArray() @ArrayMinSize(2) @ValidateNested({ each: true }) @Type(() => JournalLineDto) lines: JournalLineDto[];
}

@ApiTags('cafe-finance')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class FinanceController {
  constructor(private readonly svc: FinanceService, private readonly accounting: AccountingService) {}
  @Get('expense-categories') @Requires('finance.read') cats() { return this.svc.categories(); }
  @Post('expense-categories') @Requires('finance.manage') createCat(@Body() d: NameDto) { return this.svc.createCategory(d.name, d.accountCode); }
  @Get('expenses') @Requires('finance.read') expenses(@Query('from') f?: string, @Query('to') t?: string) { return this.svc.listExpenses(f, t); }
  @Post('expenses') @Requires('finance.manage') expense(@Body() d: ExpenseDto) { return this.svc.createExpense(d); }
  @Post('expenses/:id/void') @Requires('finance.manage') voidExpense(@Param('id') id: string, @Body() d: ReasonDto) { return this.svc.voidExpense(id, d.reason); }

  @Get('cash-registers') @Requires('cash_register.operate') registers() { return this.svc.registers(); }
  @Post('cash-registers') @Requires('finance.manage') createRegister(@Body() d: NameDto) { return this.svc.createRegister(d.name); }
  @Post('cash-registers/:id/open') @Requires('cash_register.operate') open(@Param('id') id: string, @Body() d: OpenRegisterDto) { return this.svc.openRegister(id, d.floatAmount); }
  @Post('cash-register-sessions/:id/transactions') @Requires('cash_register.operate') tx(@Param('id') id: string, @Body() d: RegisterTxDto) { return this.svc.registerTransaction(id, d); }
  @Post('cash-register-sessions/:id/close') @Requires('cash_register.operate') close(@Param('id') id: string, @Body() d: CloseRegisterDto) { return this.svc.closeRegister(id, d.counted); }

  @Get('payroll') @Requires('finance.manage') payroll() { return this.svc.listPayroll(); }
  @Post('payroll') @Requires('finance.manage') createPayroll(@Body() d: PayrollDto) { return this.svc.createPayroll(d); }
  @Post('payroll/:id/pay') @Requires('finance.manage') pay(@Param('id') id: string, @Body() d: PayPayrollDto) { return this.svc.payPayroll(id, d.paidOn, d.method); }

  @Get('accounts') @Requires('finance.read') accounts() { return this.accounting.accounts(); }
  @Post('accounts') @Requires('finance.manage') account(@Body() d: AccountDto) { return this.accounting.createAccount(d); }
  @Get('financial-periods') @Requires('finance.read') periods() { return this.accounting.periods(); }
  @Post('financial-periods') @Requires('finance.manage') period(@Body() d: PeriodDto) { return this.accounting.createPeriod(d); }
  @Post('financial-periods/:id/close') @Requires('finance.manage') closePeriod(@Param('id', ParseIntPipe) id: number) { return this.accounting.closePeriod(id); }
  @Get('journal-entries') @Requires('finance.read') entries(@Query('from') f?: string, @Query('to') t?: string) { return this.accounting.listEntries(f, t); }
  @Post('journal-entries') @Requires('finance.manage') entry(@Body() d: JournalDto) { return this.accounting.manualEntry(d); }
  @Post('journal-entries/:id/reverse') @Requires('finance.manage') reverse(@Param('id', ParseIntPipe) id: number, @Body() d: ReverseDto) { return this.accounting.reverse(id, d.reason, d.date); }

  @Get('reports/sales') @Requires('finance.read') sales(@Query('from') f: string, @Query('to') t: string, @Query('group') g?: string) { return this.svc.salesReport(f, t, (['day', 'week', 'month', 'year'].includes(g ?? '') ? g : 'day') as 'day'); }
  @Get('reports/payments') @Requires('finance.read') payments(@Query('from') f: string, @Query('to') t: string) { return this.svc.paymentBreakdown(f, t); }
  @Get('reports/pnl') @Requires('finance.read') pnl(@Query('from') f: string, @Query('to') t: string) { return this.accounting.profitAndLoss(f, t); }
  @Get('reports/trial-balance') @Requires('finance.read') trial(@Query('from') f: string, @Query('to') t: string) { return this.accounting.trialBalance(f, t); }
  @Get('reports/balance-sheet') @Requires('finance.read') balance(@Query('asOf') a: string) { return this.accounting.balanceSheet(a); }
  @Get('reports/food-cost') @Requires('finance.read') food(@Query('from') f: string, @Query('to') t: string) { return this.svc.foodCost(f, t); }
  @Get('audit-logs') @Requires('audit.read') audit(@Query('from') f?: string) { return this.svc.auditTrail(f); }
  @Get('reports/:type/export') @Requires('finance.read') @RawResponse()
  async exportReport(@Param('type') type: string, @Query('format') format: string, @Query('from') f: string, @Query('to') t: string, @Res() res: Response) {
    const out = await this.svc.export(type, format === 'pdf' ? 'pdf' : 'xlsx', f, t);
    res.setHeader('Content-Type', out.mime);
    res.setHeader('Content-Disposition', `attachment; filename="${out.filename}"`);
    res.send(out.body);
  }
}
