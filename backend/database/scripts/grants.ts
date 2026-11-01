import { applyGrants, connectAdmin } from '../lib.ts';

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set. See .env.example.`);
  return value;
}

const database = process.env.DB_NAME ?? 'cafe_platform';
const conn = await connectAdmin(database);
try {
  await applyGrants(conn, {
    database,
    migrator: { user: process.env.DB_MIGRATOR_USER ?? 'cafe_migrator', password: required('DB_MIGRATOR_PASSWORD') },
    app: { user: process.env.DB_APP_USER ?? 'cafe_app', password: required('DB_APP_PASSWORD') },
    reporting: { user: process.env.DB_REPORTING_USER ?? 'cafe_reporting', password: required('DB_REPORTING_PASSWORD') },
  });
  console.log(`Grants applied on ${database}.`);
} finally {
  await conn.end();
}
