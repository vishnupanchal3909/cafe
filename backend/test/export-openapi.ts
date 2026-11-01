// Writes the OpenAPI document from the running app's real routes: npm run openapi
import 'reflect-metadata';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { bootstrap } from './harness';

async function main() {
  const { app } = await bootstrap();
  const doc = SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('Cafe Platform API').setVersion('1').addBearerAuth().build());
  writeFileSync(join(__dirname, '..', '..', '..', 'docs', 'openapi.json'), JSON.stringify(doc, null, 1));
  console.log(`${Object.keys(doc.paths).length} paths written`);
  await app.close();
  process.exit(0);
}
main();
