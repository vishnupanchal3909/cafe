import { Body, Controller, Get, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Length, Max, MaxLength, Min, MinLength } from 'class-validator';
import { Audiences, Requires } from '../../common/http';
import { KitchenService } from './kitchen.service';

export class StationDto {
  @IsString() @MinLength(1) @MaxLength(80) name: string;
  @IsOptional() @IsInt() @Min(1) delayThresholdMinutes?: number;
}
export class UpdateStationDto {
  @IsOptional() @IsString() @MaxLength(80) name?: string;
  @IsOptional() @IsInt() @Min(1) delayThresholdMinutes?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
export class RouteDto { @IsOptional() @IsString() @Length(26, 26) stationId?: string | null; }
export class TicketStatusDto { @IsIn(['accepted', 'preparing', 'ready', 'completed']) status: 'accepted'; }
export class PriorityDto { @IsInt() @Min(0) @Max(9) priority: number; }

@ApiTags('kitchen')
@ApiBearerAuth()
@Audiences('kitchen', 'cafe')
@Controller('kitchen')
export class KitchenController {
  constructor(private readonly svc: KitchenService) {}
  @Get('tickets') @Requires('kitchen.read') tickets(@Query() q: { status?: string; station?: string }) { return this.svc.tickets(q); }
  @Post('tickets/:id/status') @Requires('kitchen.operate') status(@Param('id') id: string, @Body() d: TicketStatusDto) { return this.svc.setStatus(id, d.status); }
  @Post('tickets/:id/priority') @Requires('kitchen.operate') priority(@Param('id') id: string, @Body() d: PriorityDto) { return this.svc.prioritize(id, d.priority); }
  @Get('branches') @Requires('kitchen.read') branches() { return this.svc.branches(); }
  @Get('stations') @Requires('kitchen.read') stations() { return this.svc.stations(); }
}

@ApiTags('cafe-kitchen')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe/kitchen')
export class KitchenConfigController {
  constructor(private readonly svc: KitchenService) {}
  @Post('stations') @Requires('kitchen.configure') create(@Body() d: StationDto) { return this.svc.createStation(d); }
  @Patch('stations/:id') @Requires('kitchen.configure') update(@Param('id') id: string, @Body() d: UpdateStationDto) { return this.svc.updateStation(id, d); }
  @Put('products/:id/station') @Requires('kitchen.configure') route(@Param('id') id: string, @Body() d: RouteDto) { return this.svc.routeProduct(id, d.stationId ?? null); }
}
