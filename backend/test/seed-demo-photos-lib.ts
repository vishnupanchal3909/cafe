// Puts sample photos on products that have none. Goes through the real upload checks. Never replaces an owner's photo.
import type { INestApplicationContext } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { asTenant, unscoped } from '../src/common/context';
import { Db } from '../src/infra/db/db.service';
import { CatalogService } from '../src/modules/catalog/catalog.service';
import { TenancyService } from '../src/modules/tenancy/tenancy.service';

export async function applyDemoPhotos(app: INestApplicationContext, slug: string, dir: string) {
  const db = app.get(Db);
  const cafe = await unscoped('seed', () => db.q.selectFrom('cafes').select('id').where('slug', '=', slug).executeTakeFirstOrThrow());
  const map = JSON.parse(readFileSync(join(dir, 'map.json'), 'utf8')) as Record<string, string>;
  return asTenant(cafe.id, async () => {
    const products = await db.q.selectFrom('products as p').innerJoin('product_translations as t', 't.product_id', 'p.id').select(['p.id', 'p.public_id', 't.name']).where('p.cafe_id', '=', cafe.id).where('t.cafe_id', '=', cafe.id).where('t.language_code', '=', 'en').where('p.deleted_at', 'is', null).execute();
    let added = 0;
    for (const p of products) {
      const file = map[p.name];
      if (!file) continue;
      const has = await db.q.selectFrom('product_images').select('asset_id').where('cafe_id', '=', cafe.id).where('product_id', '=', p.id).executeTakeFirst();
      if (has) continue;
      const buffer = readFileSync(join(dir, file));
      const asset = await app.get(TenancyService).upload({ buffer, size: buffer.length } as Express.Multer.File, 'product_image');
      await app.get(CatalogService).setProductImage(p.public_id, asset.publicId);
      added += 1;
    }
    return added;
  });
}
