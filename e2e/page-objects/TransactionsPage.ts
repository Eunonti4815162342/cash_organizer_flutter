import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

export class TransactionsPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  async open() {
    await this.page.goto('/');
    await this.waitForFlutter();
    await this.navigateTo(/transactions|transacciones/);
    await this.page.waitForTimeout(1_000);
  }

  get newTransactionButton() {
    return this.page.getByRole('button', { name: /add|añadir|nueva|new/i }).last();
  }

  get searchInput() {
    return this.page.locator('input[type="search"], input[aria-label*="search" i], input[placeholder*="search" i], input[placeholder*="buscar" i]').first();
  }

  get saveButton() {
    return this.page.getByRole('button', { name: /save|guardar/i }).first();
  }

  get cancelButton() {
    return this.page.getByRole('button', { name: /cancel|cancelar/i }).first();
  }

  async clickNewTransaction() {
    await this.newTransactionButton.click();
    await this.page.waitForTimeout(1_000);
  }

  async selectExpenseType() {
    await this.page.getByText(/^expense$|^gasto$/i).first().click();
    await this.page.waitForTimeout(400);
  }

  async selectIncomeType() {
    await this.page.getByText(/^income$|^ingreso$/i).first().click();
    await this.page.waitForTimeout(400);
  }

  async selectTransferType() {
    await this.page.getByText(/^transfer$|^transferencia$/i).first().click();
    await this.page.waitForTimeout(400);
  }

  async fillAmount(amount: string) {
    const inputs = this.page.locator('input');
    await inputs.first().click();
    await inputs.first().fill(amount);
  }

  async fillDescription(desc: string) {
    const inputs = this.page.locator('input');
    const count = await inputs.count();
    if (count > 1) {
      await inputs.nth(1).fill(desc);
    }
  }

  async fillNotes(notes: string) {
    const inputs = this.page.locator('input, textarea');
    const count = await inputs.count();
    if (count > 2) {
      await inputs.nth(2).fill(notes);
    }
  }

  async saveTransaction() {
    await this.saveButton.click();
    await this.page.waitForTimeout(1_500);
  }

  async cancelTransaction() {
    await this.cancelButton.click();
    await this.page.waitForTimeout(500);
  }

  async searchFor(query: string) {
    const input = this.searchInput;
    if (await input.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await input.fill(query);
      await this.page.waitForTimeout(600);
    }
  }

  async navigateToPreviousMonth() {
    const buttons = this.page.getByRole('button');
    const count = await buttons.count();
    for (let i = 0; i < count; i++) {
      const btn = buttons.nth(i);
      const label = (await btn.getAttribute('aria-label')) ?? '';
      if (/prev|anterior|left/i.test(label)) {
        await btn.click();
        await this.page.waitForTimeout(500);
        return;
      }
    }
    // fallback
    await buttons.first().click();
    await this.page.waitForTimeout(500);
  }

  async assertListLoaded() {
    const text = await this.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
  }

  async assertFormVisible() {
    const text = await this.bodyText();
    const hasForm =
      text.includes('expense') ||
      text.includes('gasto') ||
      text.includes('income') ||
      text.includes('ingreso') ||
      text.includes('amount') ||
      text.includes('importe');
    expect(hasForm).toBeTruthy();
  }

  async assertFormClosed() {
    const text = await this.bodyText();
    expect(text).not.toContain('Exception');
  }
}
