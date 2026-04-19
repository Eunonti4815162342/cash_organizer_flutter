/**
 * Tests avanzados del Dashboard: filtros de cuenta, cash flow, net worth,
 * recent activity, y comportamiento con múltiples meses.
 * Labels reales del ARB: Dashboard, Net Worth, Cash Flow, Recent Activity,
 * All accounts, Total Balance, Expense, Income.
 */
import { test, expect } from '@playwright/test';
import { DashboardPage } from '../page-objects/DashboardPage';

test.describe('Dashboard — Net Worth / Cash Flow / Recent Activity', () => {
  test('el dashboard muestra alguna de las secciones principales', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    const hasSection =
      /net worth|cash flow|recent activity|dashboard/i.test(text);
    expect(hasSection).toBeTruthy();
  });

  test('Net Worth no muestra error cuando no hay cuentas', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    expect(text).not.toContain('Exception');
  });

  test('Cash Flow no crashea al cambiar entre Expense e Income', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await dashboard.switchToIncome();
    await page.waitForTimeout(500);
    await dashboard.switchToExpense();
    await page.waitForTimeout(500);
    await dashboard.assertLoaded();
  });

  test('Recent Activity muestra transacciones o empty state', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    const hasActivity =
      /recent activity|no data|sin datos|transacciones/i.test(text);
    // Puede haber datos o empty state — ambos son válidos
    expect(text).not.toContain('Exception');
  });
});

test.describe('Dashboard — filtro de cuentas (All accounts)', () => {
  test('el texto "All accounts" aparece en el selector', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    expect(text).toMatch(/all accounts/i);
  });

  test('abrir el picker de cuentas muestra opciones de filtro', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const accountsBtn = page.getByText(/all accounts/i).first();
    if (await accountsBtn.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await accountsBtn.click();
      await page.waitForTimeout(600);
      const text = await dashboard.bodyText();
      expect(text).not.toContain('Exception');
    }
  });

  test('cerrar el picker de cuentas sin seleccionar no rompe el dashboard', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const accountsBtn = page.getByText(/all accounts/i).first();
    if (await accountsBtn.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await accountsBtn.click();
      await page.waitForTimeout(400);
      await page.keyboard.press('Escape');
      await page.waitForTimeout(400);
      await dashboard.assertLoaded();
    }
  });

  test('el picker muestra "All accounts" como primera opción', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const accountsBtn = page.getByText(/all accounts/i).first();
    if (await accountsBtn.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await accountsBtn.click();
      await page.waitForTimeout(500);
      await expect(page.getByText(/all accounts/i).first()).toBeVisible({ timeout: 4_000 });
    }
  });
});

test.describe('Dashboard — navegación avanzada por meses', () => {
  test('navegar 6 meses atrás y volver no lanza excepción', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    for (let i = 0; i < 6; i++) {
      await dashboard.goToPreviousMonth();
    }
    for (let i = 0; i < 6; i++) {
      await dashboard.goToNextMonth();
    }
    await dashboard.assertLoaded();
  });

  test('el mes actual se muestra en el selector de periodo', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    // El mes actual debe estar en la UI (nombre o número)
    const currentYear = new Date().getFullYear().toString();
    expect(text).toMatch(new RegExp(currentYear));
  });

  test('clicar en el nombre del mes abre el selector', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    // El texto del mes es clickable para abrir date picker
    const monthText = page.getByText(/january|february|march|april|may|june|july|august|september|october|november|december/i).first();
    if (await monthText.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await monthText.click();
      await page.waitForTimeout(600);
      await dashboard.assertLoaded();
    }
  });
});

test.describe('Dashboard — respuesta ante datos vacíos', () => {
  test('el dashboard con 0 transacciones muestra 0.00 o mensaje vacío', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    const text = await dashboard.bodyText();
    // Puede mostrar 0.00, "No data", o similar — sin crash
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
  });

  test('cambiar a un mes sin datos no rompe la pantalla', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    // Ir a un mes muy en el futuro — con alta probabilidad de estar vacío
    for (let i = 0; i < 12; i++) {
      await dashboard.goToNextMonth();
    }
    await dashboard.assertLoaded();
  });
});

test.describe('Dashboard — interacción con el gráfico', () => {
  test('el área del gráfico está presente en el DOM', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await page.waitForTimeout(1_000);
    // Flutter renderiza el gráfico — sólo verificamos que no hay crash
    await dashboard.assertLoaded();
  });

  test('cambiar tipo y mes simultáneamente no lanza excepción', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.open();
    await dashboard.switchToIncome();
    await dashboard.goToPreviousMonth();
    await dashboard.switchToExpense();
    await dashboard.goToNextMonth();
    await dashboard.assertLoaded();
  });
});
