import 'reflect-metadata';
import { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import type { Server } from 'node:http';
import { AppModule } from './app.module';
import { config } from './common/config';
import { RealtimeService } from './modules/realtime/realtime.service';

export async function createApp(options: { logger?: false } = {}): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule, { rawBody: true, logger: options.logger ?? undefined });
  app.setGlobalPrefix('api/v1');
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'same-site' } }));
  app.enableCors({ origin: config.corsOrigins, credentials: true, allowedHeaders: ['Authorization', 'Content-Type', 'Idempotency-Key', 'X-Branch-Id', 'X-Table-Session', 'X-Requested-With', 'X-Access-Reason', 'Accept-Language'] });
  const doc = new DocumentBuilder().setTitle('Cafe Platform API').setVersion('1').addBearerAuth().build();
  if (config.env !== 'production') SwaggerModule.setup('api/docs', app, SwaggerModule.createDocument(app, doc));
  await app.init();
  app.get(RealtimeService).attach(app.getHttpServer() as Server);
  return app;
}
