import { test, expect } from '@playwright/test';
import { CategoriesPage } from '../page-objects/CategoriesPage';

test.describe('Categorías — carga inicial', () => {
  test('la pantalla de categorías carga sin errores', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.assertLoaded();
  });

  test('no muestra excepciones de Flutter', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    const text = await categories.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
    expect(text).not.toContain('Null check operator');
  });

  test('muestra el botón de añadir categoría', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await expect(categories.addButton).toBeVisible({ timeout: 6_000 });
  });

  test('muestra lista de categorías o empty state sin error', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    const text = await categories.bodyText();
    expect(text).not.toContain('Exception');
  });
});

test.describe('Categorías — formulario', () => {
  test('el botón de añadir abre el formulario', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await categories.assertFormVisible();
  });

  test('el formulario tiene campo de nombre', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await expect(categories.categoryNameInput).toBeVisible({ timeout: 5_000 });
  });

  test('el campo de nombre acepta texto', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await categories.fillCategoryName('Categoría Test E2E');
    const val = await categories.categoryNameInput.inputValue();
    expect(val).toBe('Categoría Test E2E');
  });

  test('cancelar vuelve a la lista sin excepción', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await categories.cancel();
    await categories.assertLoaded();
  });

  test('guardar categoría con nombre válido no lanza excepción', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await categories.fillCategoryName('Cat Test ' + Date.now());
    await categories.save();
    await categories.assertLoaded();
  });

  test('guardar sin nombre no rompe la pantalla', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await categories.save(); // sin nombre
    await page.waitForTimeout(800);
    await categories.assertLoaded();
  });

  test('el formulario tiene botón de guardar', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();
    await categories.openNewCategoryForm();
    await expect(categories.saveButton).toBeVisible({ timeout: 5_000 });
  });
});

test.describe('Categorías — subcategorías', () => {
  test('clicar en una categoría no lanza excepción', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();

    const firstItem = page.getByRole('listitem').first();
    if (await firstItem.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await firstItem.click();
      await page.waitForTimeout(500);
      await categories.assertLoaded();
    }
  });

  test('expandir subcategorías (si existen) no lanza excepción', async ({ page }) => {
    const categories = new CategoriesPage(page);
    await categories.open();

    // Intentar expandir con chevron o botón de expansión
    const expandBtns = page.getByRole('button').filter({ hasText: /expand|chevron|▼|▶/i });
    const count = await expandBtns.count();
    if (count > 0) {
      await expandBtns.first().click();
      await page.waitForTimeout(400);
      await categories.assertLoaded();
    }
  });
});
