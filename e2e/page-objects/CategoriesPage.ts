import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

export class CategoriesPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  async open() {
    await this.page.goto('/');
    await this.waitForFlutter();
    await this.navigateTo(/categories|categor/);
    await this.page.waitForTimeout(1_000);
  }

  get addButton() {
    return this.page.getByRole('button', { name: /add|añadir|\+/i }).last();
  }

  get saveButton() {
    return this.page.getByRole('button', { name: /save|guardar|crear|create/i }).first();
  }

  get cancelButton() {
    return this.page.getByRole('button', { name: /cancel|cancelar/i }).first();
  }

  get categoryNameInput() {
    return this.page.locator('input').first();
  }

  get categoriesList() {
    return this.page.getByRole('listitem');
  }

  async openNewCategoryForm() {
    await this.addButton.click();
    await this.page.waitForTimeout(600);
  }

  async fillCategoryName(name: string) {
    await this.categoryNameInput.fill(name);
  }

  async save() {
    await this.saveButton.click();
    await this.page.waitForTimeout(1_000);
  }

  async cancel() {
    await this.cancelButton.click();
    await this.page.waitForTimeout(400);
  }

  async assertLoaded() {
    const text = await this.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
  }

  async assertFormVisible() {
    await expect(this.page.getByText(/nombre|name|categoría|category/i).first()).toBeVisible({ timeout: 6_000 });
  }

  async categoryCount(): Promise<number> {
    return this.categoriesList.count();
  }
}
