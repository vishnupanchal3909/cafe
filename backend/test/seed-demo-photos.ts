// npm run demo:photos [slug]. Local only: refuses production. See .devdata/demo-photos/CREDITS.md.
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { join } from 'node:path';
import { AppModule } from '../src/app.module';
import { config } from '../src/common/config';
import { applyDemoPhotos } from './seed-demo-photos-lib';

async function main() {
  if (config.env === 'production') throw new Error('Refusing to add sample photos in production.');
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  console.log(`Added ${await applyDemoPhotos(app, process.argv[2] ?? 'tea-hub', join(__dirname, '..', '..', '..', '.devdata', 'demo-photos'))} photos to ${config.db.name}.`);
  await app.close();
  process.exit(0);
}
main().catch((e) => { console.error(`FAILED: ${e.message}`); process.exit(1); });
