import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { badRequest } from '../../common/errors';
import { Audiences, Requires } from '../../common/http';
import { AnalyticsService } from './analytics.service';

const isDate = (s?: string) => !!s && /^\d{4}-\d{2}-\d{2}$/.test(s);

@ApiTags('cafe-analytics')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe/analytics')
export class CafeAnalyticsController {
  constructor(private readonly svc: AnalyticsService) {}
  @Get() @Requires('reports.read')
  dashboard(@Query('from') f: string, @Query('to') t: string) {
    if (!isDate(f) || !isDate(t)) throw badRequest('DATE_RANGE_REQUIRED');
    return this.svc.cafeDashboard(f, t);
  }
}

@ApiTags('platform-analytics')
@ApiBearerAuth()
@Audiences('platform')
@Controller('platform/analytics')
export class PlatformAnalyticsController {
  constructor(private readonly svc: AnalyticsService) {}
  @Get() @Requires('platform.dashboard.read') dashboard() { return this.svc.platformDashboard(); }
  @Get('consolidated') @Requires('platform.finance.read')
  consolidated(@Query('currency') c: string, @Query('asOf') a: string) {
    if (!/^[A-Z]{3}$/.test(c ?? '') || !isDate(a)) throw badRequest('CONSOLIDATION_PARAMS_REQUIRED');
    return this.svc.consolidated(c, a);
  }
}
