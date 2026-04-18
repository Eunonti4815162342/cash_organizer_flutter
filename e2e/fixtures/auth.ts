import { Page } from '@playwright/test';

export const TEST_USER = {
  email: process.env.TEST_EMAIL ?? 'test@cashkeep.com',
  password: process.env.TEST_PASSWORD ?? 'test1234',
};

/**
 * Espera a que Flutter esté completamente renderizado.
 * Flutter web emite un evento 'flutter-initialized' cuando está listo.
 */
export async function waitForFlutter(page: Page): Promise<void> {
  await page.waitForFunction(() => {
    const canvas = document.querySelector('flutter-view') ?? document.querySelector('flt-glass-pane');
    return canvas !== null;
  }, { timeout: 15_000 });
  // Pausa mínima para que los widgets estáticos terminen de pintarse
  await page.waitForTimeout(800);
}

/**
 * Hace login y espera al dashboard.
 */
export async function login(page: Page): Promise<void> {
  await page.goto('/');
  await waitForFlutter(page);

  // Campo email
  await page.locator('input[type="email"], flt-semantics[aria-label*="email" i] input').first().fill(TEST_USER.email);
  // Campo password
  await page.locator('input[type="password"], flt-semantics[aria-label*="password" i] input').first().fill(TEST_USER.password);
  // Botón login
  await page.getByRole('button', { name: /login|iniciar|entrar/i }).click();

  // Esperar a que aparezca el dashboard
  await page.waitForURL(/.*/, { timeout: 10_000 });
  await page.waitForTimeout(1_000);
}

/**
 * Navega a una sección del menú lateral por texto.
 */
export async function navigateTo(page: Page, label: string): Promise<void> {
  await page.getByRole('link', { name: new RegExp(label, 'i') })
    .or(page.getByText(new RegExp(`^${label}$`, 'i')))
    .first()
    .click();
  await page.waitForTimeout(500);
}
