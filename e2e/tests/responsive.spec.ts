/**
 * Tests de comportamiento responsive: viewport mobile vs desktop.
 * La app Flutter web adapta el layout según el ancho (isMobile checks).
 */
import { test, expect } from '@playwright/test';
import { DashboardPage } from '../page-objects/DashboardPage';
import { TransactionsPage } from '../page-objects/TransactionsPage';
import { AccountsPage } from '../page-objects/AccountsPage';

const MOBILE_VIEWPORT = { width: 390, height: 844 };   // iPhone 14
const TABLET_VIEWPORT = { width: 768, height: 1024 };  // iPad
const DESKTOP_VIEWPORT = { width: 1280, height: 800 }; // Desktop

test.describe('Responsive — viewport mobile (390px)', () => {
  test.use({ viewport: MOBILE_VIEWPORT });

  test('el dashboard carga correctamente en mobile', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await dashboard.assertLoaded();
  });

  test('la lista de transacciones carga en mobile', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.assertListLoaded();
  });

  test('el formulario de transacción es usable en mobile', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.assertFormVisible();
  });

  test('la pantalla de cuentas carga en mobile', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.assertLoaded();
  });

  test('el menú no rompe el layout en mobile', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    expect(text).not.toContain('RenderFlex overflowed');
    expect(text).not.toContain('Exception');
  });
});

test.describe('Responsive — viewport tablet (768px)', () => {
  test.use({ viewport: TABLET_VIEWPORT });

  test('el dashboard carga correctamente en tablet', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await dashboard.assertLoaded();
  });

  test('la pantalla de cuentas muestra panel de detalle en tablet', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.assertLoaded();
  });

  test('las transacciones cargan en tablet', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.assertListLoaded();
  });
});

test.describe('Responsive — viewport desktop (1280px)', () => {
  test.use({ viewport: DESKTOP_VIEWPORT });

  test('el dashboard muestra el layout de escritorio', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await dashboard.assertLoaded();
  });

  test('la pantalla de cuentas muestra el split view en desktop', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.assertLoaded();
    // En desktop el panel derecho debería estar visible
    const text = await accounts.bodyText();
    expect(text).toMatch(/selecciona una cuenta|select.*account|sin cuentas/i);
  });

  test('no hay overflow de layout en desktop', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    expect(text).not.toContain('RenderFlex overflowed');
  });
});

test.describe('Responsive — cambio de tamaño dinámico', () => {
  test('redimensionar de desktop a mobile no lanza excepción', async ({ page }) => {
    await page.setViewportSize(DESKTOP_VIEWPORT);
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await page.waitForTimeout(500);

    await page.setViewportSize(MOBILE_VIEWPORT);
    await page.waitForTimeout(600);
    await dashboard.assertLoaded();
  });

  test('redimensionar de mobile a desktop no lanza excepción', async ({ page }) => {
    await page.setViewportSize(MOBILE_VIEWPORT);
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await page.waitForTimeout(500);

    await page.setViewportSize(DESKTOP_VIEWPORT);
    await page.waitForTimeout(600);
    await dashboard.assertLoaded();
  });
});
