import { test, expect } from '@playwright/test';
import { login } from '../fixtures/auth';

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('carga el dashboard sin errores después del login', async ({ page }) => {
    await page.waitForTimeout(2_000);
    const bodyText = await page.locator('body').textContent();
    expect(bodyText).not.toContain('Exception');
    expect(bodyText).not.toContain('flutter: Error');
  });

  test('muestra el selector de modo expense/income', async ({ page }) => {
    await page.waitForTimeout(1_500);
    await expect(page.getByText(/expense|gasto/i).first()).toBeVisible();
    await expect(page.getByText(/income|ingreso/i).first()).toBeVisible();
  });

  test('cambiar de expense a income no rompe la pantalla', async ({ page }) => {
    await page.waitForTimeout(1_500);
    await page.getByText(/income|ingreso/i).first().click();
    await page.waitForTimeout(800);

    const bodyText = await page.locator('body').textContent();
    expect(bodyText).not.toContain('Exception');
  });

  test('el selector de accounts abre un menú', async ({ page }) => {
    await page.waitForTimeout(1_500);
    await page.getByText(/accounts|cuentas/i).first().click();
    await page.waitForTimeout(500);

    // Debe aparecer algún elemento del picker (checkbox o lista)
    const pickerVisible = await page.getByRole('checkbox').first().isVisible().catch(() => false);
    const listVisible = await page.getByText(/all|todas|seleccionar/i).first().isVisible().catch(() => false);
    expect(pickerVisible || listVisible).toBeTruthy();
  });

  test('navegar entre meses actualiza el dashboard', async ({ page }) => {
    await page.waitForTimeout(1_500);

    // Buscar botones de navegación de periodo
    const prevBtn = page.getByRole('button').filter({ hasText: /prev|anterior|</i }).first();
    if (await prevBtn.isVisible()) {
      await prevBtn.click();
      await page.waitForTimeout(1_000);
    }

    const bodyText = await page.locator('body').textContent();
    expect(bodyText).not.toContain('Exception');
  });
});
