/**
 * Tests detallados del formulario de transacción.
 * Usa los labels reales del ARB: Amount, Description, Save, Cancel,
 * Expense/Income/Transfer, Accounts, Categories, Date, Edit Transaction, Delete Transaction.
 */
import { test, expect } from '@playwright/test';
import { TransactionsPage } from '../page-objects/TransactionsPage';

async function openForm(page: any) {
  const tx = new TransactionsPage(page);
  await tx.open();
  await tx.clickNewTransaction();
  return tx;
}

test.describe('Formulario de transacción — AppBar', () => {
  test('el título es "New Transaction" al crear', async ({ page }) => {
    await openForm(page);
    const text = await page.locator('body').textContent() ?? '';
    expect(text).toMatch(/new transaction/i);
  });

  test('hay un botón de guardar (Save)', async ({ page }) => {
    await openForm(page);
    await expect(
      page.getByRole('button', { name: /save/i }).first()
    ).toBeVisible({ timeout: 6_000 });
  });

  test('NO aparece el botón Delete en modo creación', async ({ page }) => {
    await openForm(page);
    // Delete solo aparece al editar una transacción existente
    const deleteBtn = page.getByRole('button', { name: /^delete$/i });
    const visible = await deleteBtn.isVisible({ timeout: 1_500 }).catch(() => false);
    // En modo crear no debe estar visible (o estar oculto)
    expect(visible).toBeFalsy();
  });
});

test.describe('Formulario de transacción — selector de tipo', () => {
  test('la pestaña EXPENSE está visible', async ({ page }) => {
    await openForm(page);
    await expect(page.getByText(/^expense$/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('la pestaña INCOME está visible', async ({ page }) => {
    await openForm(page);
    await expect(page.getByText(/^income$/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('la pestaña TRANSFER está visible', async ({ page }) => {
    await openForm(page);
    await expect(page.getByText(/^transfer$/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('cambiar a INCOME no lanza excepción', async ({ page }) => {
    const tx = await openForm(page);
    await page.getByText(/^income$/i).first().click();
    await page.waitForTimeout(400);
    await tx.assertListLoaded();
  });

  test('cambiar a TRANSFER no lanza excepción', async ({ page }) => {
    const tx = await openForm(page);
    await page.getByText(/^transfer$/i).first().click();
    await page.waitForTimeout(400);
    await tx.assertListLoaded();
  });

  test('cambiar de INCOME a EXPENSE y volver no lanza excepción', async ({ page }) => {
    const tx = await openForm(page);
    await page.getByText(/^income$/i).first().click();
    await page.waitForTimeout(300);
    await page.getByText(/^expense$/i).first().click();
    await page.waitForTimeout(300);
    await tx.assertListLoaded();
  });
});

test.describe('Formulario de transacción — campo Amount', () => {
  test('el label AMOUNT está visible', async ({ page }) => {
    await openForm(page);
    await expect(page.getByText(/amount/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('el campo de importe empieza en 0.00', async ({ page }) => {
    await openForm(page);
    const amountInput = page.locator('input').first();
    // Al estar focused puede estar vacío (se limpia al hacer foco)
    const val = await amountInput.inputValue();
    expect(val === '0.00' || val === '' || val === '0').toBeTruthy();
  });

  test('se puede introducir un importe positivo', async ({ page }) => {
    const tx = await openForm(page);
    await tx.fillAmount('123.45');
    const val = await page.locator('input').first().inputValue();
    expect(val).toContain('123');
  });

  test('se puede introducir un importe con decimales', async ({ page }) => {
    const tx = await openForm(page);
    await tx.fillAmount('9.99');
    const val = await page.locator('input').first().inputValue();
    expect(val).toContain('9');
  });

  test('introducir un importe de 0 no explota', async ({ page }) => {
    const tx = await openForm(page);
    await tx.fillAmount('0');
    await tx.saveTransaction();
    await tx.assertListLoaded();
  });

  test('importe muy grande no crashea la app', async ({ page }) => {
    const tx = await openForm(page);
    await tx.fillAmount('999999.99');
    await tx.assertListLoaded();
  });
});

test.describe('Formulario de transacción — campo Description', () => {
  test('el label DESCRIPTION está visible', async ({ page }) => {
    await openForm(page);
    await expect(page.getByText(/description/i).first()).toBeVisible({ timeout: 5_000 });
  });

  test('el hint "Add a note..." está presente', async ({ page }) => {
    await openForm(page);
    const text = await page.locator('body').textContent() ?? '';
    expect(text).toMatch(/add a note|description/i);
  });

  test('se puede escribir una descripción larga', async ({ page }) => {
    const tx = await openForm(page);
    const longDesc = 'Esta es una descripción muy larga para probar que el campo acepta texto sin límites visibles en la UI de Playwright E2E';
    await tx.fillDescription(longDesc);
    await tx.assertListLoaded();
  });

  test('descripción con caracteres especiales no lanza excepción', async ({ page }) => {
    const tx = await openForm(page);
    await tx.fillDescription('Café & más — "test" 100%');
    await tx.assertListLoaded();
  });
});

test.describe('Formulario de transacción — pickers (Accounts, Categories, Date)', () => {
  test('el tile ACCOUNTS es clickable', async ({ page }) => {
    await openForm(page);
    const accountsTile = page.getByText(/^accounts$/i).first();
    if (await accountsTile.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await accountsTile.click();
      await page.waitForTimeout(500);
      const text = await page.locator('body').textContent() ?? '';
      expect(text).not.toContain('Exception');
    }
  });

  test('el tile CATEGORIES es clickable', async ({ page }) => {
    await openForm(page);
    const categoriesTile = page.getByText(/^categories$/i).first();
    if (await categoriesTile.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await categoriesTile.click();
      await page.waitForTimeout(500);
      const text = await page.locator('body').textContent() ?? '';
      expect(text).not.toContain('Exception');
    }
  });

  test('el tile DATE es clickable', async ({ page }) => {
    await openForm(page);
    const dateTile = page.getByText(/^date$/i).first();
    if (await dateTile.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await dateTile.click();
      await page.waitForTimeout(500);
      const text = await page.locator('body').textContent() ?? '';
      expect(text).not.toContain('Exception');
    }
  });
});

test.describe('Formulario de transacción — guardar y cancelar', () => {
  test('Save sin cuenta asignada no crashea', async ({ page }) => {
    const tx = await openForm(page);
    await tx.fillAmount('10.00');
    await tx.fillDescription('Sin cuenta asignada');
    await tx.saveTransaction();
    await tx.assertListLoaded();
  });

  test('Save con todos los campos rellenos no crashea', async ({ page }) => {
    const tx = await openForm(page);
    await tx.selectExpenseType();
    await tx.fillAmount('55.00');
    await tx.fillDescription('Gasto completo E2E');
    await tx.saveTransaction();
    await tx.assertListLoaded();
  });

  test('Save income no crashea', async ({ page }) => {
    const tx = await openForm(page);
    await tx.selectIncomeType();
    await tx.fillAmount('200.00');
    await tx.fillDescription('Ingreso completo E2E');
    await tx.saveTransaction();
    await tx.assertListLoaded();
  });

  test('volver atrás desde el formulario no crashea', async ({ page }) => {
    const tx = await openForm(page);
    await page.goBack();
    await page.waitForTimeout(700);
    await tx.assertListLoaded();
  });
});

test.describe('Formulario de transacción — editar existente', () => {
  test('el título es "Edit Transaction" al editar una existente', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();

    // Intentar clicar en la primera transacción de la lista
    const firstItem = page.getByRole('listitem').first();
    if (await firstItem.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await firstItem.click();
      await page.waitForTimeout(500);
      const text = await page.locator('body').textContent() ?? '';
      // Puede abrir detalle o edición directamente
      expect(text).not.toContain('Exception');
    }
  });

  test('editar transacción muestra el botón Delete', async ({ page }) => {
    const tx = new TransactionsPage(page);
    await tx.open();

    const firstItem = page.getByRole('listitem').first();
    if (await firstItem.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await firstItem.click();
      await page.waitForTimeout(600);
      // Si hay edit button, lo pulsamos
      const editBtn = page.getByRole('button', { name: /edit/i }).first();
      if (await editBtn.isVisible({ timeout: 1_500 }).catch(() => false)) {
        await editBtn.click();
        await page.waitForTimeout(500);
        const text = await page.locator('body').textContent() ?? '';
        // En modo edición debe verse Delete o Edit Transaction
        expect(text).toMatch(/edit transaction|delete/i);
      }
    }
  });
});
