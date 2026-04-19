import { Page, Locator } from '@playwright/test';

export class BasePage {
  constructor(protected page: Page) {}

  async goto() {
    await this.page.goto('/');
    await this.waitForFlutter();
  }

  async waitForFlutter(): Promise<void> {
    await this.page.waitForFunction(() => {
      return (
        document.querySelector('flutter-view') !== null ||
        document.querySelector('flt-glass-pane') !== null
      );
    }, { timeout: 15_000 });
    await this.page.waitForTimeout(800);
  }

  async navigateTo(section: RegExp | string): Promise<void> {
    const pattern = typeof section === 'string' ? new RegExp(section, 'i') : section;
    await this.page
      .getByRole('link', { name: pattern })
      .or(this.page.getByText(pattern))
      .first()
      .click();
    await this.page.waitForTimeout(600);
  }

  async bodyText(): Promise<string> {
    return (await this.page.locator('body').textContent()) ?? '';
  }

  async hasNoException(): Promise<boolean> {
    const text = await this.bodyText();
    return !text.includes('Exception') && !text.includes('flutter: Error');
  }

  button(name: RegExp | string): Locator {
    return this.page.getByRole('button', { name });
  }

  text(pattern: RegExp | string): Locator {
    return this.page.getByText(pattern);
  }
}
