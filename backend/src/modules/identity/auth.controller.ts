import { Body, Controller, Delete, Get, HttpCode, Param, Post, Req, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsIn, IsOptional, IsString, Length, MaxLength, MinLength } from 'class-validator';
import type { Request, Response } from 'express';
import { principal, unscoped } from '../../common/context';
import { badRequest, unauthorized } from '../../common/errors';
import { Audiences, Public, RateLimit } from '../../common/http';
import { Db } from '../../infra/db/db.service';
import { AllowNoMfa } from './auth.guard';
import { AuthService, TokenPair } from './auth.service';

export class LoginDto {
  @ApiProperty() @IsEmail() @MaxLength(254) email: string;
  @ApiProperty() @IsString() @MaxLength(200) password: string;
  @ApiProperty({ enum: ['platform', 'cafe', 'kitchen'] }) @IsIn(['platform', 'cafe', 'kitchen']) audience: 'platform' | 'cafe' | 'kitchen';
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(26, 26) cafePublicId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(6, 6) totp?: string;
  @ApiPropertyOptional({ enum: ['body', 'cookie'] }) @IsOptional() @IsIn(['body', 'cookie']) transport?: 'body' | 'cookie';
}
export class RefreshDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(200) refreshToken?: string;
  @ApiPropertyOptional({ enum: ['body', 'cookie'] }) @IsOptional() @IsIn(['body', 'cookie']) transport?: 'body' | 'cookie';
}
export class ResetRequestDto { @ApiProperty() @IsEmail() @MaxLength(254) email: string; }
export class ResetConfirmDto {
  @ApiProperty() @IsString() @MinLength(20) @MaxLength(200) token: string;
  @ApiProperty() @IsString() @MinLength(10) @MaxLength(200) password: string;
}
export class CustomerRegisterDto {
  @ApiProperty() @IsEmail() @MaxLength(254) email: string;
  @ApiProperty() @IsString() @MinLength(10) @MaxLength(200) password: string;
  @ApiProperty() @IsString() @MinLength(1) @MaxLength(150) fullName: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(12) language?: string;
  @ApiPropertyOptional({ enum: ['body', 'cookie'] }) @IsOptional() @IsIn(['body', 'cookie']) transport?: 'body' | 'cookie';
}
export class CustomerLoginDto {
  @ApiProperty() @IsEmail() @MaxLength(254) email: string;
  @ApiProperty() @IsString() @MaxLength(200) password: string;
  @ApiPropertyOptional({ enum: ['body', 'cookie'] }) @IsOptional() @IsIn(['body', 'cookie']) transport?: 'body' | 'cookie';
}
export class GoogleDto { @ApiProperty() @IsString() @MaxLength(4096) idToken: string; }
export class TotpDto { @ApiProperty() @IsString() @Length(6, 6) code: string; }

const COOKIE = 'cafe_rt';
const cookieOptions = { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'strict' as const, path: '/api/v1/auth', maxAge: 30 * 86400_000 };

// Web clients receive the refresh token as an HttpOnly cookie, so script injection cannot read it.
function deliver(res: Response, tokens: TokenPair, transport?: 'body' | 'cookie') {
  if (transport !== 'cookie') return tokens;
  res.cookie(COOKIE, tokens.refreshToken, cookieOptions);
  const { refreshToken: _omit, ...rest } = tokens;
  return rest;
}
function cookieToken(req: Request): string | undefined {
  return (req.headers.cookie ?? '').split(';').map((c) => c.trim()).find((c) => c.startsWith(`${COOKIE}=`))?.slice(COOKIE.length + 1);
}

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService, private readonly db: Db) {}

  @Post('login') @Public() @HttpCode(200) @RateLimit(10)
  async login(@Body() dto: LoginDto, @Res({ passthrough: true }) res: Response) {
    const { mfaEnrollmentRequired, ...tokens } = await this.auth.staffLogin(dto);
    return { ...deliver(res, tokens, dto.transport), mfaEnrollmentRequired };
  }

  @Post('refresh') @Public() @HttpCode(200) @RateLimit(60)
  async refresh(@Body() dto: RefreshDto, @Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const fromCookie = cookieToken(req);
    // CSRF: a browser cannot attach this custom header cross-site without a CORS preflight that we would refuse.
    if (!dto.refreshToken && fromCookie && req.headers['x-requested-with'] !== 'cafe-app') throw badRequest('CSRF_HEADER_REQUIRED');
    const token = dto.refreshToken ?? fromCookie;
    if (!token) throw unauthorized('TOKEN_INVALID');
    return deliver(res, await this.auth.refresh(token), fromCookie && !dto.refreshToken ? 'cookie' : dto.transport);
  }

  @Post('logout') @Audiences('platform', 'cafe', 'kitchen', 'customer') @AllowNoMfa() @HttpCode(200) @ApiBearerAuth()
  async logout(@Req() req: Request & { sid?: string }, @Res({ passthrough: true }) res: Response) {
    await this.auth.revokeSession(req.sid!);
    res.clearCookie(COOKIE, { path: cookieOptions.path });
    return { ok: true };
  }

  @Post('logout-all') @Audiences('platform', 'cafe', 'kitchen', 'customer') @AllowNoMfa() @HttpCode(200) @ApiBearerAuth()
  async logoutAll() {
    const p = principal();
    await this.auth.revokeAll(p.type === 'user' ? { userId: p.id! } : { customerId: p.id! });
    return { ok: true };
  }

  @Get('me') @Audiences('platform', 'cafe', 'kitchen') @AllowNoMfa() @ApiBearerAuth()
  async me() {
    const p = principal();
    const u = await unscoped('own profile', () => this.db.q.selectFrom('users').select(['public_id', 'email', 'full_name', 'preferred_language_code', 'mfa_enabled_at']).where('id', '=', p.id!).executeTakeFirstOrThrow());
    return { publicId: u.public_id, email: u.email, fullName: u.full_name, language: u.preferred_language_code, mfaEnabled: !!u.mfa_enabled_at, audience: p.audience, permissions: [...p.permissions], branchIds: p.branchIds };
  }

  @Get('sessions') @Audiences('platform', 'cafe', 'kitchen') @AllowNoMfa() @ApiBearerAuth()
  sessions() { return this.auth.listSessions(principal().id!); }

  @Delete('sessions/:id') @Audiences('platform', 'cafe', 'kitchen') @AllowNoMfa() @ApiBearerAuth()
  async revoke(@Param('id') id: string) {
    const mine = (await this.auth.listSessions(principal().id!)).some((s) => s.public_id === id);
    if (mine) await this.auth.revokeSession(id, 'user_revoked');
    return { ok: true };
  }

  @Post('mfa/enroll') @Audiences('platform') @AllowNoMfa() @HttpCode(200) @ApiBearerAuth()
  mfaEnroll() { return this.auth.mfaBegin(principal().id!); }

  @Post('mfa/confirm') @Audiences('platform') @AllowNoMfa() @HttpCode(200) @ApiBearerAuth()
  mfaConfirm(@Body() dto: TotpDto, @Req() req: Request & { sid?: string }) { return this.auth.mfaConfirm(principal().id!, dto.code, req.sid!); }
}

@ApiTags('customer-auth')
@Controller('customer/auth')
export class CustomerAuthController {
  constructor(private readonly auth: AuthService) {}

  // At most 20 new accounts an hour from one address. Not stricter: guests on a busy cafe's Wi-Fi share one address.
  @Post('register') @Public() @RateLimit(20, 3600)
  async register(@Body() dto: CustomerRegisterDto, @Res({ passthrough: true }) res: Response) {
    return deliver(res, await this.auth.customerRegister(dto), dto.transport);
  }
  @Post('login') @Public() @HttpCode(200) @RateLimit(10)
  async login(@Body() dto: CustomerLoginDto, @Res({ passthrough: true }) res: Response) {
    return deliver(res, await this.auth.customerLogin(dto.email, dto.password), dto.transport);
  }
  @Post('google') @Public() @HttpCode(200) @RateLimit(10)
  google(@Body() dto: GoogleDto) { return this.auth.customerGoogle(dto.idToken); }
  @Post('password-reset/request') @Public() @HttpCode(200) @RateLimit(5, 3600)
  resetRequest(@Body() dto: ResetRequestDto) { return this.auth.requestCustomerPasswordReset(dto.email); }
  @Post('password-reset/confirm') @Public() @HttpCode(200) @RateLimit(10)
  resetConfirm(@Body() dto: ResetConfirmDto) { return this.auth.confirmCustomerPasswordReset(dto.token, dto.password); }
  // What the sign-in screen may offer, so it never shows a button that cannot work.
  @Get('features') @Public()
  features() { return { passwordReset: this.auth.passwordResetAvailable }; }
}
