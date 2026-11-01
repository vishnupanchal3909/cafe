import { connectAdmin, ensureDatabase, migrate } from '../lib.ts';

const database = process.env.DB_NAME ?? 'cafe_platform';
const bootstrap = await connectAdmin();
await ensureDatabase(bootstrap, database);
await bootstrap.end();

const conn = await connectAdmin(database);
try {
  const { applied, skipped } = await migrate(conn);
  console.log(`Applied ${applied.length}, already current ${skipped.length}.`);
  for (const file of applied) console.log(`  + ${file}`);
} finally {
  await conn.end();
}
