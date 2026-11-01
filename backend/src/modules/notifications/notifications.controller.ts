import { Body, Controller, Get, Param, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsString, MaxLength } from 'class-validator';
import { Audiences, Requires } from '../../common/http';
import { NotificationsService } from './notifications.service';

export class DeviceDto {
  @IsIn(['android', 'ios', 'web']) platform: 'android' | 'ios' | 'web';
  @IsString() @MaxLength(512) token: string;
}
export class PreferenceDto {
  @IsString() @MaxLength(80) templateKey: string;
  @IsIn(['push', 'in_app', 'email', 'sms', 'whatsapp']) channel: 'push';
  @IsBoolean() isEnabled: boolean;
}

@ApiTags('notifications')
@ApiBearerAuth()
@Audiences('cafe', 'kitchen', 'customer', 'platform')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly svc: NotificationsService) {}
  @Get() list() { return this.svc.list(); }
  @Post(':id/read') read(@Param('id') id: string) { return this.svc.markRead(id); }
  @Post('devices') device(@Body() d: DeviceDto) { return this.svc.registerDevice(d.platform, d.token); }
}

@ApiTags('cafe-notifications')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe/notification-preferences')
export class NotificationPrefsController {
  constructor(private readonly svc: NotificationsService) {}
  @Get() @Requires('cafe.profile.read') get() { return this.svc.preferences(); }
  @Put() @Requires('cafe.profile.manage') set(@Body() d: PreferenceDto) { return this.svc.setPreference(d); }
}
