import { Injectable, Logger, OnApplicationBootstrap, OnApplicationShutdown } from '@nestjs/common';
import { config } from '../common/config';
import { PaymentsService } from './payments/payments.service';
import { RealtimeService } from './realtime/realtime.service';
import { SubscriptionsService } from './subscriptions/subscriptions.service';

// Interval-driven background work in the same image. Each job is safe to run on several instances.
@Injectable()
export class WorkersService implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger('Workers');
  private timers: NodeJS.Timeout[] = [];
  constructor(private readonly realtime: RealtimeService, private readonly payments: PaymentsService, private readonly subs: SubscriptionsService) {}

  private every(ms: number, name: string, job: () => Promise<unknown>) {
    let running = false;
    const t = setInterval(async () => {
      if (running) return;
      running = true;
      try { await job(); } catch (e) { this.logger.error(`${name}: ${(e as Error).message}`); } finally { running = false; }
    }, ms);
    t.unref();
    this.timers.push(t);
  }

  onApplicationBootstrap() {
    if (!config.runWorkers) return;
    this.every(500, 'outbox', () => this.realtime.dispatchOnce());
    this.every(60_000, 'payment-reconcile', () => this.payments.reconcileStale());
    this.every(6 * 3_600_000, 'settlements', () => this.payments.syncAllSettlements());
    this.every(3_600_000, 'subscriptions', () => this.subs.runLifecycle());
    this.every(3_600_000, 'outbox-cleanup', () => this.realtime.cleanup());
  }
  onApplicationShutdown() { this.timers.forEach(clearInterval); }
}
