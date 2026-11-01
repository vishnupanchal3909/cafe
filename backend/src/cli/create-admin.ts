// Bootstrap the first Super Admin: ADMIN_EMAIL=... ADMIN_PASSWORD=... npm run admin:create
// No admin account is ever seeded, so no default credential can ship.
import 'reflect-metadata';
import { Db } from '../infra/db/db.service';
import { unscoped } from '../common/context';
import { ulid } from '../common/ids';
import { hashPassword } from '../modules/identity/crypto';

async function main() {
  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password || password.length < 12) throw new Error('Set ADMIN_EMAIL and ADMIN_PASSWORD (12+ characters).');
  const db = new Db();
  await unscoped('bootstrap', () => db.tx(async (tx) => {
    const created = await tx.insertInto('users').values({
      public_id: ulid(), email, password_hash: await hashPassword(password), full_name: process.env.ADMIN_NAME ?? 'Platform Admin', status: 'active', is_platform_user: 1,
    }).executeTakeFirstOrThrow();
    const role = await tx.selectFrom('roles').select('id').where('code', '=', 'super_admin').where('cafe_id', 'is', null).executeTakeFirstOrThrow();
    await tx.insertInto('user_roles').values({ user_id: Number(created.insertId), role_id: role.id }).execute();
  }));
  await db.onModuleDestroy();
  console.log(`Super Admin ${email} created. MFA enrollment is required at first login.`);
}
main().catch((e) => { console.error(e.message); process.exit(1); });
