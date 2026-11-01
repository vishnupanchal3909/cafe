import { Body, Controller, Get, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsEmail, IsIn, IsOptional, IsString, Length, Matches, MaxLength, MinLength } from 'class-validator';
import { Audiences, Public, RateLimit, Requires } from '../../common/http';
import { StaffService } from './staff.service';

export class InviteDto {
  @IsEmail() @MaxLength(254) email: string;
  @IsString() @MinLength(1) @MaxLength(150) fullName: string;
  @IsString() @MaxLength(40) roleCode: string;
  @IsOptional() @IsString() @Length(26, 26) branchId?: string;
  @IsOptional() @IsString() @MaxLength(100) jobTitle?: string;
  @IsOptional() @IsString() @MaxLength(32) employeeCode?: string;
}
export class UpdateStaffDto {
  @IsOptional() @IsIn(['active', 'inactive']) status?: 'active' | 'inactive';
  @IsOptional() @IsString() @MaxLength(100) jobTitle?: string;
  @IsOptional() @IsString() @MaxLength(32) employeeCode?: string;
  @IsOptional() @IsString() @MaxLength(40) roleCode?: string;
  @IsOptional() @IsString() @Length(26, 26) branchId?: string;
}
export class RoleDto {
  @Matches(/^[a-z0-9_]{2,40}$/) code: string;
  @IsString() @MaxLength(80) name: string;
  @IsArray() @ArrayMaxSize(100) @IsString({ each: true }) permissions: string[];
}
export class AcceptInvitationDto {
  @IsString() @MaxLength(200) token: string;
  @IsString() @MinLength(10) @MaxLength(200) password: string;
}

@ApiTags('auth')
@Controller('auth')
export class InvitationController {
  constructor(private readonly svc: StaffService) {}
  @Post('accept-invitation') @Public() @RateLimit(10)
  accept(@Body() d: AcceptInvitationDto) { return this.svc.acceptInvitation(d.token, d.password); }
}

@ApiTags('cafe-staff')
@ApiBearerAuth()
@Audiences('cafe')
@Controller('cafe')
export class StaffController {
  constructor(private readonly svc: StaffService) {}
  @Get('staff') @Requires('staff.read') list() { return this.svc.list(); }
  @Post('staff') @Requires('staff.manage') invite(@Body() d: InviteDto) { return this.svc.invite(d); }
  @Patch('staff/:id') @Requires('staff.manage') update(@Param('id') id: string, @Body() d: UpdateStaffDto) { return this.svc.update(id, d); }
  @Get('roles') @Requires('staff.read') roles() { return this.svc.roles(); }
  @Put('roles') @Requires('staff.manage') saveRole(@Body() d: RoleDto) { return this.svc.saveRole(d); }
  @Get('permissions') @Requires('staff.read') permissions() { return this.svc.permissions(); }
  @Post('attendance/clock-in') @Requires('attendance.self') clockIn() { return this.svc.clockIn(); }
  @Post('attendance/clock-out') @Requires('attendance.self') clockOut() { return this.svc.clockOut(); }
  @Get('attendance') @Requires('attendance.manage') attendance(@Query('from') f?: string, @Query('to') t?: string) { return this.svc.attendance(f, t); }
  @Get('staff-performance') @Requires('staff.read') performance(@Query('from') f: string, @Query('to') t: string) { return this.svc.performance(f, t); }
}
