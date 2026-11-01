import { connectAdmin, seed } from '../lib.ts';

const conn = await connectAdmin(process.env.DB_NAME ?? 'cafe_platform');
try {
  const files = await seed(conn);
  console.log(`Seeded: ${files.join(', ')}`);
} finally {
  await conn.end();
}
