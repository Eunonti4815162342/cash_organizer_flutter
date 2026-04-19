import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';
import { TEST_USER } from '../fixtures/auth';

export class LoginPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  get emailInput() {
    return this.page.locator('input[type="email"]').first();
  }

  get passwordInput() {
    return this.page.locator('input[type="password"]').first();
  }

  get loginButton() {
    return this.page.getByRole('button', { name: /login|iniciar|entrar/i }).first();
  }

  async fillEmail(email: string) {
    await this.emailInput.fill(email);
  }

  async fillPassword(password: string) {
    await this.passwordInput.fill(password);
  }

  async submit() {
    await this.loginButton.click();
    await this.page.waitForTimeout(2_500);
  }

  async loginAs(email: string, password: string) {
    await this.fillEmail(email);
    await this.fillPassword(password);
    await this.submit();
  }

  async loginWithTestUser() {
    await this.loginAs(TEST_USER.email, TEST_USER.password);
  }

  async assertVisible() {
    await expect(this.loginButton).toBeVisible({ timeout: 8_000 });
  }

  async assertEmailFieldVisible() {
    await expect(this.emailInput).toBeVisible({ timeout: 8_000 });
  }

  async assertPasswordFieldVisible() {
    await expect(this.passwordInput).toBeVisible({ timeout: 8_000 });
  }

  async assertStillOnLoginPage() {
    await expect(this.emailInput).toBeVisible({ timeout: 5_000 });
  }
}
