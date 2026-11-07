// npm run demo:teahub [slug]. Local data only: refuses production, and refuses a cafe that already has a menu.
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { config } from '../src/common/config';
import { seedTeaHub } from './seed-tea-hub-lib';

async function main() {
  if (config.env === 'production') throw new Error('Refusing to seed demo data in production.');
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  await seedTeaHub(app, process.argv[2] ?? 'tea-hub');
  await app.close();
  console.log('Done.');
  process.exit(0);
}
main().catch((e) => { console.error(`FAILED: ${e.message}`); process.exit(1); });
