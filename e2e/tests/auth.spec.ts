import { test, expect } from '@playwright/test';
import { waitForFlutter, TEST_USER } from '../fixtures/auth';

test.describe('Autenticación', () => {
  test('muestra la pantalla de login al entrar', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await expect(page.getByRole('button', { name: /login|iniciar|entrar/i }).first()).toBeVisible();
  });

  test('login con credenciales válidas navega al dashboard', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await page.locator('input[type="email"]').first().fill(TEST_USER.email);
    await page.locator('input[type="password"]').first().fill(TEST_USER.password);
    await page.getByRole('button', { name: /login|iniciar|entrar/i }).click();

    // Dashboard debe cargarse — buscamos el título o algún elemento característico
    await expect(page.getByText(/dashboard/i).first()).toBeVisible({ timeout: 10_000 });
  });

  test('login con contraseña incorrecta muestra error', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await page.locator('input[type="email"]').first().fill(TEST_USER.email);
    await page.locator('input[type="password"]').first().fill('wrong_password_123');
    await page.getByRole('button', { name: /login|iniciar|entrar/i }).click();

    // Debe seguir en el login o mostrar mensaje de error
    await page.waitForTimeout(2_000);
    const stillOnLogin = await page.locator('input[type="password"]').first().isVisible();
    expect(stillOnLogin).toBeTruthy();
  });

  test('logout devuelve a la pantalla de login', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await page.locator('input[type="email"]').first().fill(TEST_USER.email);
    await page.locator('input[type="password"]').first().fill(TEST_USER.password);
    await page.getByRole('button', { name: /login|iniciar|entrar/i }).click();
    await page.waitForTimeout(2_000);

    await page.getByText(/logout/i).first().click();
    await page.waitForTimeout(1_000);

    await expect(page.locator('input[type="email"]').first()).toBeVisible({ timeout: 8_000 });
  });
});
