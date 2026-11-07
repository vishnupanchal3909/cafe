#!/usr/bin/env node
// Serves a Flutter web build with SPA fallback, so a QR path like /t/<token> opens the app.
import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize } from 'node:path';

const [root, port = '8083'] = process.argv.slice(2);
if (!root) { console.error('usage: serve-web.mjs <build/web dir> [port]'); process.exit(2); }
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf' };
createServer((req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^(\.\.[/\\])+/, '');
  let file = join(root, path);
  if (!existsSync(file) || statSync(file).isDirectory()) file = join(root, 'index.html');
  res.setHeader('Content-Type', types[extname(file)] ?? 'application/octet-stream');
  createReadStream(file).pipe(res);
})// HOST=0.0.0.0 lets a phone on the same Wi-Fi reach it. The default stays on this computer only.
.listen(Number(port), process.env.HOST ?? '127.0.0.1', () => console.log(`serving on port ${port}`));
