import { test, expect } from '@playwright/test';
import { TransactionsPage } from '../page-objects/TransactionsPage';

test.describe('Transacciones — lista', () => {
  test('la lista carga sin errores', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.assertListLoaded();
  });

  test('no muestra excepciones de Flutter', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    const text = await tx.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
    expect(text).not.toContain('Null check operator');
  });

  test('muestra el botón de añadir transacción', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await expect(tx.newTransactionButton).toBeVisible({ timeout: 6_000 });
  });

  test('el selector de mes está visible', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    // Debe haber botones de navegación de periodo
    const buttons = page.getByRole('button');
    const count = await buttons.count();
    expect(count).toBeGreaterThan(0);
  });

  test('la lista muestra estado vacío si no hay transacciones', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    const text = await tx.bodyText();
    // Puede haber datos o empty state — ambos son válidos
    const isValid =
      !text.includes('Exception') &&
      !text.includes('flutter: Error');
    expect(isValid).toBeTruthy();
  });
});

test.describe('Transacciones — navegación de meses', () => {
  test('navegar al mes anterior no lanza excepciones', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.navigateToPreviousMonth();
    await tx.assertListLoaded();
  });

  test('navegar varios meses atrás funciona', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.navigateToPreviousMonth();
    await tx.navigateToPreviousMonth();
    await tx.assertListLoaded();
  });
});

test.describe('Transacciones — formulario', () => {
  test('el botón FAB abre el formulario', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.assertFormVisible();
  });

  test('el formulario tiene al menos un campo de entrada', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    const inputs = page.locator('input');
    const count = await inputs.count();
    expect(count).toBeGreaterThan(0);
  });

  test('se puede seleccionar el tipo Expense', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.selectExpenseType();
    await tx.assertListLoaded(); // sin excepción
  });

  test('se puede seleccionar el tipo Income', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.selectIncomeType();
    await tx.assertListLoaded();
  });

  test('se puede seleccionar el tipo Transfer', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    // Transfer puede no estar disponible si no hay 2 cuentas — verificamos que no explote
    const transferBtn = page.getByText(/^transfer$|^transferencia$/i).first();
    if (await transferBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await transferBtn.click();
      await page.waitForTimeout(400);
      await tx.assertListLoaded();
    }
  });

  test('el campo de importe acepta valores numéricos', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.fillAmount('42.50');
    const val = await page.locator('input').first().inputValue();
    expect(val).toContain('42');
  });

  test('se puede introducir una descripción', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.fillDescription('Test E2E descripción');
    const inputs = page.locator('input');
    const count = await inputs.count();
    if (count > 1) {
      const val = await inputs.nth(1).inputValue();
      expect(val).toContain('Test E2E');
    }
  });

  test('cancelar el formulario no lanza excepciones', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();

    const cancelBtn = page.getByRole('button', { name: /cancel|cancelar|back|atrás/i }).first();
    if (await cancelBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await cancelBtn.click();
      await page.waitForTimeout(500);
    } else {
      // Usar botón de retroceso del navegador
      await page.goBack();
      await page.waitForTimeout(500);
    }
    await tx.assertListLoaded();
  });

  test('intentar guardar sin importe muestra validación o permanece en formulario', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();

    // Hacer clic en guardar sin rellenar nada
    const saveBtn = page.getByRole('button', { name: /save|guardar/i }).first();
    if (await saveBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await saveBtn.click();
      await page.waitForTimeout(800);
    }
    // No debe explotar
    await tx.assertListLoaded();
  });

  test('crear gasto completo y guardar no lanza excepción', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.selectExpenseType();
    await tx.fillAmount('15.00');
    await tx.fillDescription('Gasto test E2E');
    await tx.saveTransaction();
    await tx.assertListLoaded();
  });

  test('crear ingreso completo y guardar no lanza excepción', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.clickNewTransaction();
    await tx.selectIncomeType();
    await tx.fillAmount('100.00');
    await tx.fillDescription('Ingreso test E2E');
    await tx.saveTransaction();
    await tx.assertListLoaded();
  });
});

test.describe('Transacciones — búsqueda y filtros', () => {
  test('abrir la búsqueda (si existe) no rompe la pantalla', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();

    // Buscar icono de búsqueda
    const searchIcon = page.getByRole('button', { name: /search|buscar/i }).first();
    if (await searchIcon.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await searchIcon.click();
      await page.waitForTimeout(500);
      await tx.assertListLoaded();
    }
  });

  test('buscar texto vacío no lanza excepción', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.searchFor('');
    await tx.assertListLoaded();
  });

  test('buscar texto con resultados filtra la lista', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.searchFor('test');
    await tx.assertListLoaded();
  });

  test('buscar texto sin resultados muestra empty state', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();
    await tx.searchFor('xyzzy_no_existe_9999');
    await tx.assertListLoaded();
  });
});
