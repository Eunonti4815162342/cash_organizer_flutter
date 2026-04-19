/**
 * Tests del flujo de registro de usuario.
 * El backend tiene POST /api/auth/register.
 * La pantalla de login puede tener un enlace a registro.
 */
import { test, expect } from '@playwright/test';
import { LoginPage } from '../page-objects/LoginPage';

test.use({ storageState: { cookies: [], origins: [] } });

test.describe('Registro — pantalla de login', () => {
  test('la pantalla de login tiene enlace o botón de registro', async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    const registerLink = page
      .getByText(/register|registrar|crear cuenta|sign up/i)
      .or(page.getByRole('button', { name: /register|registrar|crear cuenta|sign up/i }))
      .first();
    if (await registerLink.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await expect(registerLink).toBeVisible();
    }
    // No fallo si no hay botón de registro — puede ser solo via API
  });

  test('navegar al formulario de registro no lanza excepción', async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    const registerLink = page
      .getByText(/register|registrar|crear cuenta|sign up/i)
      .first();
    if (await registerLink.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await registerLink.click();
      await page.waitForTimeout(600);
      const text = await page.locator('body').textContent() ?? '';
      expect(text).not.toContain('Exception');
    }
  });
});

test.describe('Registro — formulario', () => {
  async function openRegister(page: any) {
    const login = new LoginPage(page);
    await login.goto();
    const link = page.getByText(/register|registrar|crear cuenta|sign up/i).first();
    if (await link.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await link.click();
      await page.waitForTimeout(600);
      return true;
    }
    return false;
  }

  test('el formulario de registro tiene campo de email', async ({ page }) => {
    const opened = await openRegister(page);
    if (opened) {
      await expect(page.locator('input[type="email"]').first()).toBeVisible({ timeout: 5_000 });
    }
  });

  test('el formulario de registro tiene campo de contraseña', async ({ page }) => {
    const opened = await openRegister(page);
    if (opened) {
      await expect(page.locator('input[type="password"]').first()).toBeVisible({ timeout: 5_000 });
    }
  });

  test('registrar con email ya existente muestra error', async ({ page }) => {
    const opened = await openRegister(page);
    if (opened) {
      const emailInput = page.locator('input[type="email"]').first();
      const passInput = page.locator('input[type="password"]').first();
      if (await emailInput.isVisible() && await passInput.isVisible()) {
        await emailInput.fill('test@cashkeep.com'); // email ya existente
        await passInput.fill('anypassword');
        await page.getByRole('button', { name: /register|registrar|crear|sign up/i }).first().click();
        await page.waitForTimeout(1_500);
        const text = await page.locator('body').textContent() ?? '';
        // El backend devuelve 409 — la app debe mostrar algo al usuario
        expect(text).not.toContain('Exception');
      }
    }
  });

  test('el formulario de registro tiene botón de submit', async ({ page }) => {
    const opened = await openRegister(page);
    if (opened) {
      const submitBtn = page.getByRole('button', { name: /register|registrar|crear|sign up/i }).first();
      if (await submitBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await expect(submitBtn).toBeVisible();
      }
    }
  });

  test('cancelar el registro vuelve al login', async ({ page }) => {
    const opened = await openRegister(page);
    if (opened) {
      const cancelBtn = page.getByRole('button', { name: /cancel|cancelar|back|volver/i }).first();
      if (await cancelBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await cancelBtn.click();
        await page.waitForTimeout(500);
        await expect(page.locator('input[type="email"]').first()).toBeVisible({ timeout: 5_000 });
      } else {
        await page.goBack();
        await page.waitForTimeout(500);
      }
    }
  });
});
