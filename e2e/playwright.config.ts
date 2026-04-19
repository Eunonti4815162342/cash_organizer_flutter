import { defineConfig, devices } from '@playwright/test';
import path from 'path';

export const AUTH_STATE_PATH = path.join(__dirname, 'fixtures', 'auth-state.json');

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 8_000 },
  fullyParallel: false,
  retries: 1,
  reporter: [['html', { outputFolder: 'playwright-report', open: 'never' }], ['list']],
  globalSetup: './fixtures/global-setup.ts',

  use: {
    baseURL: 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    storageState: AUTH_STATE_PATH,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
});
