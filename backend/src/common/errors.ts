import { ArgumentsHost, Catch, ExceptionFilter, HttpException, Injectable, Logger } from '@nestjs/common';
import type { Request, Response } from 'express';
import { MessageCatalog } from './i18n';
import { currentRequestId, currentLang } from './context';

export class AppError extends Error {
  constructor(public readonly status: number, public readonly code: string, public readonly details?: unknown, message?: string) {
    super(message ?? code);
  }
}
export const notFound = (code = 'NOT_FOUND') => new AppError(404, code);
export const forbidden = (code = 'FORBIDDEN') => new AppError(403, code);
export const conflict = (code: string, details?: unknown) => new AppError(409, code, details);
export const badRequest = (code: string, details?: unknown) => new AppError(400, code, details);
export const unauthorized = (code = 'UNAUTHORIZED') => new AppError(401, code);

// Database guards are the last line of defence. Their messages are mapped so they never reach clients raw.
const SIGNAL_TO_CODE: Array<[RegExp, number, string]> = [
  [/illegal payment status/, 409, 'PAYMENT_ILLEGAL_TRANSITION'],
  [/refund total exceeds/, 409, 'REFUND_EXCEEDS_PAYMENT'],
  [/only a successful payment/, 409, 'PAYMENT_NOT_REFUNDABLE'],
  [/do not balance/, 422, 'JOURNAL_UNBALANCED'],
  [/closed financial period/, 409, 'PERIOD_CLOSED'],
  [/outside the financial period/, 422, 'ENTRY_DATE_OUTSIDE_PERIOD'],
  [/at least two lines/, 422, 'JOURNAL_TOO_FEW_LINES'],
  [/immutable/, 409, 'RECORD_IMMUTABLE'],
  [/cannot be deleted/, 409, 'RECORD_IMMUTABLE'],
  [/role belongs to a different cafe|role scope/, 403, 'ROLE_SCOPE_INVALID'],
];

@Injectable()
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exceptions');
  constructor(private readonly messages: MessageCatalog) {}

  async catch(err: unknown, host: ArgumentsHost): Promise<void> {
    const res = host.switchToHttp().getResponse<Response>();
    const req = host.switchToHttp().getRequest<Request>();
    let status = 500;
    let code = 'INTERNAL_ERROR';
    let details: unknown;

    if (err instanceof AppError) {
      ({ status, code, details } = err);
    } else if (err instanceof HttpException) {
      status = err.getStatus();
      const body = err.getResponse() as { message?: unknown };
      if (status === 400) { code = 'VALIDATION_FAILED'; details = body.message; }
      else if (status === 404) code = 'NOT_FOUND';
      else if (status === 413) code = 'PAYLOAD_TOO_LARGE';
      else if (status === 429) code = 'RATE_LIMITED';
      else code = 'HTTP_ERROR';
    } else {
      const e = err as { code?: string; message?: string; sqlState?: string };
      const mapped = e.sqlState === '45000' ? SIGNAL_TO_CODE.find(([re]) => re.test(e.message ?? '')) : undefined;
      if (mapped) { [, status, code] = mapped; }
      else if (e.code === 'ER_DUP_ENTRY') { status = 409; code = 'DUPLICATE'; }
      else if (e.code === 'ER_NO_REFERENCED_ROW_2') { status = 422; code = 'INVALID_REFERENCE'; }
      else if (e.code === 'ER_ROW_IS_REFERENCED_2') { status = 409; code = 'IN_USE'; }
      else if (e.code === 'ER_CHECK_CONSTRAINT_VIOLATED') { status = 422; code = 'CONSTRAINT_VIOLATED'; }
      else this.logger.error(`${req?.method} ${req?.url}: ${e.message}`, (err as Error).stack);
    }
    const message = await this.messages.resolve(code, currentLang());
    res.status(status).json({ error: { code, message, details, requestId: currentRequestId() } });
  }
}
