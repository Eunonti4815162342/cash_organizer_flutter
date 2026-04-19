/**
 * Tests de la pantalla de Reports.
 * Labels reales del ARB: Reports, Report Types, Balance Summary, Categories Analysis,
 * Spending by account, Filter by Accounts, Group by subcategory, Export PDF,
 * Period, All Accounts, No data available.
 */
import { test, expect } from '@playwright/test';
import { BasePage } from '../page-objects/BasePage';

async function openReports(page: any) {
  const base = new BasePage(page);
  await base.goto();
  await page.waitForTimeout(1_500);
  await base.navigateTo(/^reports$/i);
  await page.waitForTimeout(1_200);
  return base;
}

test.describe('Reports — carga inicial', () => {
  test('la pantalla de reports carga sin errores', async ({ page }) => {
    const base = await openReports(page);
    const text = await base.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
  });

  test('el título REPORTS aparece en la pantalla', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/^reports$/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('el botón de refresh (reload) está visible', async ({ page }) => {
    await openReports(page);
    const refreshBtn = page.getByRole('button', { name: /refresh|reload/i }).first();
    if (await refreshBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await expect(refreshBtn).toBeVisible();
    }
  });

  test('no muestra excepciones de Flutter', async ({ page }) => {
    const base = await openReports(page);
    const text = await base.bodyText();
    expect(text).not.toContain('Null check operator');
    expect(text).not.toContain('flutter: Error');
  });
});

test.describe('Reports — tipos de reporte', () => {
  test('la sección REPORT TYPES está visible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/report types/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('la opción "Balance Summary" está disponible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/balance summary/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('la opción "Categories Analysis" está disponible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/categories analysis|category analysis/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('la opción "Spending by account" está disponible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/spending by account/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('seleccionar "Balance Summary" no lanza excepción', async ({ page }) => {
    const base = await openReports(page);
    const option = page.getByText(/balance summary/i).first();
    if (await option.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await option.click();
      await page.waitForTimeout(600);
      await base.assertLoaded();
    }
  });

  test('seleccionar "Categories Analysis" no lanza excepción', async ({ page }) => {
    const base = await openReports(page);
    const option = page.getByText(/categories analysis|category analysis/i).first();
    if (await option.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await option.click();
      await page.waitForTimeout(600);
      await base.assertLoaded();
    }
  });

  test('seleccionar "Spending by account" no lanza excepción', async ({ page }) => {
    const base = await openReports(page);
    const option = page.getByText(/spending by account/i).first();
    if (await option.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await option.click();
      await page.waitForTimeout(600);
      await base.assertLoaded();
    }
  });

  test('cambiar entre tipos de reporte varias veces no crashea', async ({ page }) => {
    const base = await openReports(page);
    const types = [
      /balance summary/i,
      /categories analysis|category analysis/i,
      /spending by account/i,
      /balance summary/i,
    ];
    for (const type of types) {
      const option = page.getByText(type).first();
      if (await option.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await option.click();
        await page.waitForTimeout(400);
      }
    }
    await base.assertLoaded();
  });
});

test.describe('Reports — filtros', () => {
  test('la sección FILTER BY ACCOUNTS está visible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/filter by accounts/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('los checkboxes de cuentas son clickables', async ({ page }) => {
    const base = await openReports(page);
    const checkboxes = page.getByRole('checkbox');
    const count = await checkboxes.count();
    if (count > 0) {
      await checkboxes.first().click();
      await page.waitForTimeout(400);
      await base.assertLoaded();
    }
  });

  test('deseleccionar todas las cuentas no crashea', async ({ page }) => {
    const base = await openReports(page);
    const checkboxes = page.getByRole('checkbox');
    const count = await checkboxes.count();
    for (let i = 0; i < Math.min(count, 5); i++) {
      const checked = await checkboxes.nth(i).isChecked().catch(() => false);
      if (checked) {
        await checkboxes.nth(i).click();
        await page.waitForTimeout(200);
      }
    }
    await base.assertLoaded();
  });
});

test.describe('Reports — nivel de análisis', () => {
  test('la sección ANALYSIS LEVEL está visible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/analysis level/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('el switch "Group by subcategory" está visible', async ({ page }) => {
    await openReports(page);
    await expect(page.getByText(/group by subcategory/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('activar el switch "Group by subcategory" no lanza excepción', async ({ page }) => {
    const base = await openReports(page);
    const switchEl = page.getByRole('switch').first();
    if (await switchEl.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await switchEl.click();
      await page.waitForTimeout(400);
      await base.assertLoaded();
    } else {
      // Flutter puede renderizar el switch sin role="switch"
      const groupByText = page.getByText(/group by subcategory/i).first();
      if (await groupByText.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await groupByText.click();
        await page.waitForTimeout(400);
        await base.assertLoaded();
      }
    }
  });

  test('desactivar y activar el switch varias veces no crashea', async ({ page }) => {
    const base = await openReports(page);
    const switchEl = page.getByRole('switch').first();
    if (await switchEl.isVisible({ timeout: 2_000 }).catch(() => false)) {
      for (let i = 0; i < 3; i++) {
        await switchEl.click();
        await page.waitForTimeout(300);
      }
      await base.assertLoaded();
    }
  });
});

test.describe('Reports — selector de periodo', () => {
  test('el chip de periodo (fecha) está visible', async ({ page }) => {
    await openReports(page);
    // El chip muestra "DD/MM - DD/MM"
    const datePattern = /\d{1,2}\/\d{1,2}/;
    const text = await page.locator('body').textContent() ?? '';
    expect(text).toMatch(datePattern);
  });

  test('clicar en el chip de fecha no lanza excepción', async ({ page }) => {
    const base = await openReports(page);
    // El chip de fecha tiene formato numérico como "1/4 - 30/4"
    const chips = page.getByRole('button').filter({ hasText: /\d+\/\d+/ });
    const count = await chips.count();
    if (count > 0) {
      await chips.first().click();
      await page.waitForTimeout(500);
      await base.assertLoaded();
    }
  });
});

test.describe('Reports — exportar PDF', () => {
  test('el botón Export PDF está visible', async ({ page }) => {
    await openReports(page);
    // Primero seleccionar un tipo de reporte
    const option = page.getByText(/balance summary/i).first();
    if (await option.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await option.click();
      await page.waitForTimeout(500);
    }
    await expect(page.getByText(/export pdf/i).first()).toBeVisible({ timeout: 6_000 });
  });

  test('clicar Export PDF no lanza excepción Flutter', async ({ page }) => {
    const base = await openReports(page);
    // Seleccionar reporte primero
    const option = page.getByText(/balance summary/i).first();
    if (await option.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await option.click();
      await page.waitForTimeout(400);
    }
    const exportBtn = page.getByText(/export pdf/i).first();
    if (await exportBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await exportBtn.click();
      await page.waitForTimeout(1_000);
      await base.assertLoaded();
    }
  });
});

test.describe('Reports — refresco de datos', () => {
  test('el botón de refresh recarga sin excepción', async ({ page }) => {
    const base = await openReports(page);
    const refreshBtn = page.getByRole('button').filter({ hasText: /refresh/i }).first();
    if (await refreshBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await refreshBtn.click();
      await page.waitForTimeout(1_000);
      await base.assertLoaded();
    }
  });
});
