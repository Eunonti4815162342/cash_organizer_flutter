import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

export class DashboardPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  async open() {
    await this.page.goto('/');
    await this.waitForFlutter();
    await this.page.waitForTimeout(1_500);
  }

  get expenseTab() {
    return this.page.getByText(/^expense$|^gasto$/i).first();
  }

  get incomeTab() {
    return this.page.getByText(/^income$|^ingreso$/i).first();
  }

  get accountsFilter() {
    return this.page.getByText(/accounts|cuentas/i).first();
  }

  get prevMonthButton() {
    return this.page.getByRole('button').filter({ hasText: /chevron_left|</ }).first();
  }

  get nextMonthButton() {
    return this.page.getByRole('button').filter({ hasText: /chevron_right|>/ }).last();
  }

  async switchToIncome() {
    await this.incomeTab.click();
    await this.page.waitForTimeout(600);
  }

  async switchToExpense() {
    await this.expenseTab.click();
    await this.page.waitForTimeout(600);
  }

  async goToPreviousMonth() {
    const buttons = this.page.getByRole('button');
    const count = await buttons.count();
    // chevron_left typically first navigation button
    for (let i = 0; i < count; i++) {
      const btn = buttons.nth(i);
      const label = await btn.getAttribute('aria-label') ?? '';
      if (/prev|anterior|left/i.test(label)) {
        await btn.click();
        await this.page.waitForTimeout(600);
        return;
      }
    }
    // fallback: click first small icon-style button
    await buttons.first().click();
    await this.page.waitForTimeout(600);
  }

  async goToNextMonth() {
    const buttons = this.page.getByRole('button');
    const count = await buttons.count();
    for (let i = count - 1; i >= 0; i--) {
      const btn = buttons.nth(i);
      const label = await btn.getAttribute('aria-label') ?? '';
      if (/next|siguiente|right/i.test(label)) {
        await btn.click();
        await this.page.waitForTimeout(600);
        return;
      }
    }
    await buttons.last().click();
    await this.page.waitForTimeout(600);
  }

  async assertLoaded() {
    const text = await this.bodyText();
    expect(text).not.toContain('Exception');
    expect(text).not.toContain('flutter: Error');
  }

  async assertExpenseTabVisible() {
    await expect(this.expenseTab).toBeVisible({ timeout: 6_000 });
  }

  async assertIncomeTabVisible() {
    await expect(this.incomeTab).toBeVisible({ timeout: 6_000 });
  }
}
