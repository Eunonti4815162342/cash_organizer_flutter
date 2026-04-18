import { test, expect } from '@playwright/test';
import { login } from '../fixtures/auth';

test.describe('Cuentas', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    // Navegar a la sección Accounts
    await page.getByText(/accounts|cuentas/i).nth(1).click(); // nth(1) para el menú lateral, no el del dashboard
    await page.waitForTimeout(1_500);
  });

  test('la pantalla de cuentas carga sin errores', async ({ page }) => {
    const bodyText = await page.locator('body').textContent();
    expect(bodyText).not.toContain('Exception');
  });

  test('el FAB abre el menú de añadir', async ({ page }) => {
    await page.getByRole('button', { name: /add|añadir/i }).last().click();
    await page.waitForTimeout(500);

    // Debe aparecer el diálogo con opciones
    await expect(page.getByText(/nueva cuenta|new account/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('abrir formulario de nueva cuenta muestra los campos', async ({ page }) => {
    await page.getByRole('button', { name: /add|añadir/i }).last().click();
    await page.waitForTimeout(500);

    await page.getByText(/nueva cuenta|new account/i).first().click();
    await page.waitForTimeout(800);

    // El formulario debe estar visible con campo de nombre
    await expect(page.getByText(/nombre|name/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('seleccionar una cuenta muestra el panel de detalles', async ({ page }) => {
    // Intentar clicar en la primera cuenta disponible
    const firstAccount = page.getByRole('listitem').first();
    if (await firstAccount.isVisible()) {
      await firstAccount.click();
      await page.waitForTimeout(500);

      // El panel derecho debe mostrar información
      await expect(page.getByText(/balance|saldo/i).first()).toBeVisible({ timeout: 5_000 });
    } else {
      // No hay cuentas — el empty state debe mostrarse
      await expect(page.getByText(/sin cuentas|no accounts/i).first()).toBeVisible({ timeout: 5_000 });
    }
  });
});
