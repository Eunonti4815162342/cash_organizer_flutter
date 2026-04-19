import { chromium, FullConfig } from '@playwright/test';
import { waitForFlutter, TEST_USER } from './auth';
import path from 'path';

export const AUTH_STATE_PATH = path.join(__dirname, 'auth-state.json');

/**
 * Se ejecuta UNA sola vez antes de toda la suite.
 * Hace login y guarda las cookies/localStorage para reutilizarlas en cada test.
 * Así evitamos hacer login en cada spec.
 */
export default async function globalSetup(_config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto('http://localhost:8080');
  await waitForFlutter(page);

  await page.locator('input[type="email"]').first().fill(TEST_USER.email);
  await page.locator('input[type="password"]').first().fill(TEST_USER.password);
  await page.getByRole('button', { name: /login|iniciar|entrar/i }).click();
  await page.waitForTimeout(2_500);

  await page.context().storageState({ path: AUTH_STATE_PATH });
  await browser.close();
}
