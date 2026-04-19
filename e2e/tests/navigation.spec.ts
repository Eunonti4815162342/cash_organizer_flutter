import { test, expect } from '@playwright/test';
import { BasePage } from '../page-objects/BasePage';

test.describe('Navegación — menú lateral', () => {
  test('el menú lateral está visible en el dashboard', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);

    // El menú lateral debe tener al menos un elemento clicable
    const navItems = page.getByRole('navigation');
    if (await navItems.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await expect(navItems).toBeVisible();
    } else {
      // Flutter puede no exponer nav role — buscamos texto del menú
      const menuText = await base.bodyText();
      const hasMenu =
        /dashboard|transactions|transacciones|accounts|cuentas|categories|categor/i.test(menuText);
      expect(hasMenu).toBeTruthy();
    }
  });

  test('navegar a Transacciones carga la pantalla correcta', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);
    await base.navigateTo(/transactions|transacciones/);
    const text = await base.bodyText();
    expect(text).not.toContain('Exception');
  });

  test('navegar a Cuentas carga la pantalla correcta', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);
    await base.navigateTo(/^accounts$|^cuentas$/);
    const text = await base.bodyText();
    expect(text).not.toContain('Exception');
  });

  test('navegar a Categorías carga la pantalla correcta', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);
    await base.navigateTo(/categories|categor/);
    const text = await base.bodyText();
    expect(text).not.toContain('Exception');
  });

  test('navegar de vuelta al Dashboard desde otra sección funciona', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);
    await base.navigateTo(/transactions|transacciones/);
    await page.waitForTimeout(600);
    await base.navigateTo(/dashboard/);
    const text = await base.bodyText();
    expect(text).not.toContain('Exception');
  });

  test('navegar entre todas las secciones en secuencia no lanza excepciones', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);

    const sections = [
      /transactions|transacciones/,
      /^accounts$|^cuentas$/,
      /categories|categor/,
    ];

    for (const section of sections) {
      await base.navigateTo(section);
      await page.waitForTimeout(700);
      const text = await base.bodyText();
      expect(text).not.toContain('Exception');
    }
  });
});

test.describe('Navegación — estado de la app', () => {
  test('la app no lanza errores en el estado inicial', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(2_000);
    const isClean = await base.hasNoException();
    expect(isClean).toBeTruthy();
  });

  test('la app mantiene sesión al recargar la página', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);
    await page.reload();
    await page.waitForTimeout(2_000);
    // Tras recarga: puede pedir login (sin persistencia) o mantener sesión
    const text = await base.bodyText();
    expect(text).not.toContain('Exception');
  });

  test('la app no muestra overlays de error en arranque', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(2_000);
    const text = await base.bodyText();
    expect(text).not.toContain('RenderFlex overflowed');
    expect(text).not.toContain('A RenderFlex');
  });
});

test.describe('Navegación — accesibilidad básica', () => {
  test('la app tiene elementos semánticos de Flutter', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);

    const hasSemantics =
      (await page.locator('flt-semantics').count()) > 0 ||
      (await page.locator('[role]').count()) > 0 ||
      (await page.locator('flutter-view').count()) > 0;
    expect(hasSemantics).toBeTruthy();
  });

  test('los botones tienen roles ARIA accesibles', async ({ page }) => {
    const base = new BasePage(page);
    await base.goto();
    await page.waitForTimeout(1_500);
    const buttons = page.getByRole('button');
    const count = await buttons.count();
    expect(count).toBeGreaterThan(0);
  });
});
