import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsIn, IsInt, IsISO8601, IsOptional, IsString, Length, Matches, MaxLength, Min, MinLength } from 'class-validator';
import { Audiences, Public, RateLimit, Requires } from '../../common/http';
import { TableSessionRoute } from '../identity/auth.guard';
import { TablesService } from './tables.service';

export class CreateTableDto {
  @IsString() @MinLength(1) @MaxLength(20) tableNumber: string;
  @IsOptional() @IsInt() @Min(1) capacity?: number;
  @IsOptional() @IsString() @MaxLength(60) areaName?: string;
}
export class UpdateTableDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(20) tableNumber?: string;
  @IsOptional() @IsInt() @Min(1) capacity?: number;
  @IsOptional() @IsString() @MaxLength(60) areaName?: string;
  @IsOptional() @IsIn(['available', 'occupied', 'reserved', 'cleaning', 'inactive']) status?: 'available';
}
export class MergeDto { @IsString() @Length(26, 26) tableId: string; }
export class TransferDto {
  @IsString() @Length(26, 26) tableId: string;
  @IsString() @MinLength(3) @MaxLength(500) reason: string;
}
export class TablePinDto { @Matches(/^\d{4}$/) pin: string; }
export class ServiceRequestDto { @IsIn(['waiter', 'bill', 'staff']) type: 'waiter' | 'bill' | 'staff'; }
export class ServiceStatusDto { @IsIn(['acknowledged', 'resolved']) status: 'acknowledged' | 'resolved'; }
export class ReservationDto {
  @IsOptional() @IsString() @MaxLength(150) guestName?: string;
  @IsOptional() @IsString() @MaxLength(20) guestPhone?: string;
  @IsInt() @Min(1) partySize: number;
  @IsISO8601() startsAt: string;
  @IsISO8601() endsAt: string;
  @IsOptional() @IsString() @MaxLength(500) notes?: string;
  @IsOptional() @IsString() @Length(26, 26) tableId?: string;
}
export class ReservationStatusDto { @IsIn(['confirmed', 'seated', 'completed', 'cancelled', 'no_show']) status: 'confirmed'; }

@ApiTags('public')
@Controller('public')
export class PublicQrController {
  constructor(private readonly svc: TablesService) {}
  @Get('qr/:token') @Public() @RateLimit(60)
  resolve(@Param('token') token: string, @Query('lang') lang?: string) { return this.svc.resolveQr(token, lang); }
}

@ApiTags('customer')
@Controller('customer')
export class SessionServiceController {
  constructor(private readonly svc: TablesService) {}
  @Post('service-requests') @TableSessionRoute() @RateLimit(20)
  request(@Body() d: ServiceRequestDto) { return this.svc.createServiceRequest(d.type); }
  // Ten tries per ten minutes per address: a four-digit PIN cannot be worked through by guessing.
  @Post('table-pin') @TableSessionRoute() @HttpCode(200) @RateLimit(10, 600)
  pin(@Body() d: TablePinDto) { return this.svc.verifyPin(d.pin); }
}

@ApiTags('cafe-tables')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class TablesController {
  constructor(private readonly svc: TablesService) {}
  @Get('tables') @Requires('tables.read') list() { return this.svc.list(); }
  @Post('tables') @Requires('tables.manage') create(@Body() d: CreateTableDto) { return this.svc.create(d); }
  @Patch('tables/:id') @Requires('tables.manage') update(@Param('id') id: string, @Body() d: UpdateTableDto) { return this.svc.update(id, d); }
  @Delete('tables/:id') @Requires('tables.manage') remove(@Param('id') id: string) { return this.svc.remove(id); }
  @Get('tables/:id/qr') @Requires('tables.read') qr(@Param('id') id: string) { return this.svc.qr(id); }
  @Post('tables/:id/qr/regenerate') @Requires('tables.manage') regen(@Param('id') id: string) { return this.svc.regenerateQr(id); }
  @Get('table-sessions') @Requires('tables.read') sessions() { return this.svc.activeSessions(); }
  @Post('table-sessions/:id/close') @Requires('orders.update') close(@Param('id') id: string) { return this.svc.closeSession(id); }
  @Post('tables/:id/release') @Requires('orders.update') release(@Param('id') id: string) { return this.svc.release(id); }
  @Post('table-sessions/:id/merge') @Requires('tables.transfer') merge(@Param('id') id: string, @Body() d: MergeDto) { return this.svc.merge(id, d.tableId); }
  @Post('orders/:id/transfer') @Requires('tables.transfer') transfer(@Param('id') id: string, @Body() d: TransferDto) { return this.svc.transferOrder(id, d.tableId, d.reason); }
  @Get('service-requests') @Requires('service_requests.manage') requests() { return this.svc.listServiceRequests(); }
  @Patch('service-requests/:id') @Requires('service_requests.manage') updateRequest(@Param('id') id: string, @Body() d: ServiceStatusDto) { return this.svc.updateServiceRequest(id, d.status); }
  @Get('reservations') @Requires('reservations.manage') reservations(@Query('from') from?: string) { return this.svc.listReservations(from); }
  @Post('reservations') @Requires('reservations.manage') reserve(@Body() d: ReservationDto) { return this.svc.createReservation(d); }
  @Patch('reservations/:id') @Requires('reservations.manage') reservationStatus(@Param('id') id: string, @Body() d: ReservationStatusDto) { return this.svc.updateReservation(id, d.status); }
}
