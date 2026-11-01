import { Injectable } from '@nestjs/common';
import { principal, tenantId, unscoped } from '../../common/context';
import { notFound } from '../../common/errors';
import { sha256 } from '../../common/ids';
import { Db } from '../../infra/db/db.service';

// In-app notifications are implemented. Push, email, SMS and WhatsApp are pending configuration (see KNOWN_ISSUES).
@Injectable()
export class NotificationsService {
  constructor(private readonly db: Db) {}
  private subject() {
    const p = principal();
    return p.type === 'user' ? { column: 'user_id' as const, id: p.id! } : { column: 'customer_id' as const, id: p.id! };
  }
  list() {
    const s = this.subject();
    return unscoped('own inbox', () => this.db.q.selectFrom('notifications').select(['public_id', 'template_key', 'title', 'body', 'data', 'read_at', 'created_at']).where(s.column, '=', s.id).orderBy('id', 'desc').limit(100).execute());
  }
  async markRead(publicId: string) {
    const s = this.subject();
    const r = await unscoped('own inbox', () => this.db.q.updateTable('notifications').set({ read_at: new Date() }).where('public_id', '=', publicId).where(s.column, '=', s.id).executeTakeFirst());
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }
  async registerDevice(platform: 'android' | 'ios' | 'web', token: string) {
    const s = this.subject();
    const hash = sha256(token);
    await unscoped('own device', () => this.db.q.insertInto('device_tokens').values({ [s.column]: s.id, platform, token, token_hash: hash, last_seen_at: new Date() } as never).onDuplicateKeyUpdate({ [s.column]: s.id, last_seen_at: new Date(), revoked_at: null } as never).execute());
    return { ok: true };
  }
  preferences() {
    return this.db.q.selectFrom('notification_preferences').select(['template_key', 'channel', 'is_enabled']).where('cafe_id', '=', tenantId()).where('user_id', 'is', null).execute();
  }
  async setPreference(d: { templateKey: string; channel: 'push' | 'in_app' | 'email' | 'sms' | 'whatsapp'; isEnabled: boolean }) {
    await this.db.q.insertInto('notification_preferences').values({ cafe_id: tenantId(), template_key: d.templateKey, channel: d.channel, is_enabled: d.isEnabled ? 1 : 0 }).onDuplicateKeyUpdate({ is_enabled: d.isEnabled ? 1 : 0 }).execute();
    return { ok: true };
  }
}
