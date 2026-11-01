import { Injectable } from '@nestjs/common';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join, normalize } from 'node:path';
import { GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { config } from '../../common/config';

export interface StoragePort {
  put(key: string, body: Buffer, mimeType: string): Promise<void>;
  get(key: string): Promise<Buffer>;
}

// Used only outside production. S3 is pending configuration until a bucket and credentials exist.
class LocalStorage implements StoragePort {
  private path(key: string) {
    const p = normalize(join(config.storage.localDir, key));
    if (!p.startsWith(normalize(config.storage.localDir))) throw new Error('Invalid storage key');
    return p;
  }
  async put(key: string, body: Buffer) {
    await mkdir(dirname(this.path(key)), { recursive: true });
    await writeFile(this.path(key), body);
  }
  get(key: string) { return readFile(this.path(key)); }
}

class S3Storage implements StoragePort {
  private client = new S3Client({ region: config.storage.s3Region, endpoint: config.storage.s3Endpoint || undefined, forcePathStyle: !!config.storage.s3Endpoint });
  async put(key: string, body: Buffer, mimeType: string) {
    await this.client.send(new PutObjectCommand({ Bucket: config.storage.s3Bucket, Key: key, Body: body, ContentType: mimeType }));
  }
  async get(key: string) {
    const r = await this.client.send(new GetObjectCommand({ Bucket: config.storage.s3Bucket, Key: key }));
    return Buffer.from(await r.Body!.transformToByteArray());
  }
}

@Injectable()
export class StorageService implements StoragePort {
  private impl: StoragePort;
  constructor() {
    if (config.storage.s3Bucket) this.impl = new S3Storage();
    else if (config.env === 'production') throw new Error('S3_BUCKET is required in production');
    else this.impl = new LocalStorage();
  }
  put(key: string, body: Buffer, mimeType: string) { return this.impl.put(key, body, mimeType); }
  get(key: string) { return this.impl.get(key); }
}

// Trust file content, not client-declared types. SVG is excluded because it can carry script.
export function sniffImage(b: Buffer): { mime: string; ext: string } | null {
  if (b.length > 8 && b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return { mime: 'image/png', ext: 'png' };
  if (b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return { mime: 'image/jpeg', ext: 'jpg' };
  if (b.length > 12 && b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP') return { mime: 'image/webp', ext: 'webp' };
  return null;
}
