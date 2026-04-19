import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

export class AccountsPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  async open() {
    await this.page.goto('/');
    await this.waitForFlutter();
    await this.navigateTo(/^accounts$|^cuentas$/);
    await this.page.waitForTimeout(1_200);
  }

  get addButton() {
    return this.page.getByRole('button', { name: /add|añadir|\+/i }).last();
  }

  get newAccountOption() {
    return this.page.getByText(/nueva cuenta|new account/i).first();
  }

  get newEntityOption() {
    return this.page.getByText(/nueva entidad|new entity/i).first();
  }

  get saveButton() {
    return this.page.getByRole('button', { name: /save|guardar|crear|create/i }).first();
  }

  get cancelButton() {
    return this.page.getByRole('button', { name: /cancel|cancelar/i }).first();
  }

  get accountNameInput() {
    return this.page.locator('input').first();
  }

  get accountsList() {
    return this.page.getByRole('listitem');
  }

  async openAddMenu() {
    await this.addButton.click();
    await this.page.waitForTimeout(500);
  }

  async openNewAccountForm() {
    await this.openAddMenu();
    await this.newAccountOption.click();
    await this.page.waitForTimeout(700);
  }

  async openNewEntityForm() {
    await this.openAddMenu();
    await this.newEntityOption.click();
    await this.page.waitForTimeout(700);
  }

  async fillAccountName(name: string) {
    await this.accountNameInput.fill(name);
  }

  async fillAccountBalance(balance: string) {
    const inputs = this.page.locator('input');
    const count = await inputs.count();
    if (count > 1) {
      await inputs.nth(1).fill(balance);
    }
  }

  async selectAccountType(type: string) {
    await this.page.getByText(new RegExp(type, 'i')).first().click();
    await this.page.waitForTimeout(300);
  }

  async save() {
    await this.saveButton.click();
    await this.page.waitForTimeout(1_200);
  }

  async cancel() {
    await this.cancelButton.click();
    await this.page.waitForTimeout(400);
  }

  async clickFirstAccount() {
    const first = this.accountsList.first();
    if (await first.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await first.click();
      await this.page.waitForTimeout(500);
      return true;
    }
    return false;
  }

  async assertLoaded() {
    const text = await this.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
  }

  async assertFormVisible() {
    await expect(this.page.getByText(/nombre|name|cuenta|account/i).first()).toBeVisible({ timeout: 6_000 });
  }

  async assertDialogVisible() {
    await expect(this.page.getByText(/nueva cuenta|new account|nueva entidad|new entity/i).first()).toBeVisible({ timeout: 6_000 });
  }
}
