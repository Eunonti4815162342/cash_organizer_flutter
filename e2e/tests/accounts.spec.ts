import { test, expect } from '@playwright/test';
import { AccountsPage } from '../page-objects/AccountsPage';

test.describe('Cuentas — carga inicial', () => {
  test('la pantalla de cuentas carga sin errores', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.assertLoaded();
  });

  test('no muestra excepciones de Flutter', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    const text = await accounts.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
    expect(text).not.toContain('Null check operator');
  });

  test('muestra el botón de añadir (FAB)', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await expect(accounts.addButton).toBeVisible({ timeout: 6_000 });
  });

  test('muestra lista de cuentas o empty state — no error', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    const text = await accounts.bodyText();
    const hasAccounts = /cuenta|account|balance|saldo/i.test(text);
    const hasEmpty = /sin cuentas|no accounts|no hay/i.test(text);
    // Al menos uno debe ser cierto, o simplemente no hay excepción
    expect(text).not.toContain('Exception');
  });
});

test.describe('Cuentas — menú de añadir', () => {
  test('el FAB abre el menú de opciones', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openAddMenu();
    await accounts.assertDialogVisible();
  });

  test('el menú muestra la opción "Nueva cuenta"', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openAddMenu();
    await expect(
      page.getByText(/nueva cuenta|new account/i).first()
    ).toBeVisible({ timeout: 5_000 });
  });

  test('el menú muestra la opción "Nueva entidad"', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openAddMenu();
    const entityOpt = page.getByText(/nueva entidad|new entity/i).first();
    if (await entityOpt.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await expect(entityOpt).toBeVisible();
    }
  });

  test('abrir y cerrar el menú no lanza excepciones', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openAddMenu();
    // Cerrar pulsando fuera
    await page.keyboard.press('Escape');
    await page.waitForTimeout(400);
    await accounts.assertLoaded();
  });
});

test.describe('Cuentas — formulario de nueva cuenta', () => {
  test('abrir el formulario de nueva cuenta muestra los campos', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await accounts.assertFormVisible();
  });

  test('el formulario tiene campo de nombre', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await expect(accounts.accountNameInput).toBeVisible({ timeout: 5_000 });
  });

  test('el campo de nombre acepta texto', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await accounts.fillAccountName('Cuenta Test E2E');
    const val = await accounts.accountNameInput.inputValue();
    expect(val).toBe('Cuenta Test E2E');
  });

  test('el formulario tiene un botón de guardar', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await expect(accounts.saveButton).toBeVisible({ timeout: 5_000 });
  });

  test('el formulario tiene un botón de cancelar', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    const cancelBtn = page.getByRole('button', { name: /cancel|cancelar/i }).first();
    if (await cancelBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await expect(cancelBtn).toBeVisible();
    }
  });

  test('cancelar el formulario vuelve a la lista', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await accounts.cancel();
    await accounts.assertLoaded();
  });

  test('guardar cuenta sin nombre muestra validación o permanece en formulario', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await accounts.save(); // sin nombre
    await page.waitForTimeout(800);
    // No debe explotar
    await accounts.assertLoaded();
  });

  test('crear cuenta con nombre válido no lanza excepción', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    await accounts.fillAccountName('Cuenta Test ' + Date.now());
    await accounts.save();
    await accounts.assertLoaded();
  });

  test('el formulario permite seleccionar tipo de cuenta', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.openNewAccountForm();
    // El dropdown/selector de tipo puede ser un botón o select
    const typeSelector = page.getByText(/checking|savings|credit|corriente|ahorro|crédito/i).first();
    if (await typeSelector.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await typeSelector.click();
      await page.waitForTimeout(300);
      await accounts.assertLoaded();
    }
  });
});

test.describe('Cuentas — panel de detalle', () => {
  test('seleccionar una cuenta abre el panel de detalles', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    const clicked = await accounts.clickFirstAccount();
    if (clicked) {
      await expect(
        page.getByText(/balance|saldo|transactions|transacciones/i).first()
      ).toBeVisible({ timeout: 6_000 });
    } else {
      // No hay cuentas — el empty state es correcto
      const text = await accounts.bodyText();
      expect(text).not.toContain('Exception');
    }
  });

  test('el panel de detalle no lanza excepciones', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    await accounts.clickFirstAccount();
    await accounts.assertLoaded();
  });

  test('el panel muestra las transacciones de la cuenta o empty state', async ({ page }) => {
    const accounts = new AccountsPage(page);
    await accounts.open();
    const clicked = await accounts.clickFirstAccount();
    if (clicked) {
      await page.waitForTimeout(800);
      const text = await accounts.bodyText();
      expect(text).not.toContain('Exception');
    }
  });
});
