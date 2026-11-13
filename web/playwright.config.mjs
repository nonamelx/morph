import { defineConfig } from '@playwright/test';
export default defineConfig({ testDir: './ui-tests', use: { baseURL: 'http://127.0.0.1:4173', browserName: 'chromium' }, webServer: { command: 'npm run dev -- --port 4173 --strictPort', url: 'http://127.0.0.1:4173/morph/', reuseExistingServer: false, timeout: 30000 } });
