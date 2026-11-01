import { config } from './common/config';
import { createApp } from './bootstrap';

createApp().then(async (app) => {
  app.enableShutdownHooks();
  await app.listen(config.port);
  console.log(`API on :${config.port}, docs at /api/docs`);
}).catch((e) => { console.error(e); process.exit(1); });
