import { Page } from "@playwright/test";

export async function loginAsAdmin(page: Page) {
  await page.goto("/login");
  await page.locator('input[name="display_name"]').fill("管理者 太郎");
  await page.locator('input[name="email"]').fill("admin@example.com");
  await page.locator('select[name="role"]').selectOption("admin");
  await page.locator('button:has-text("開発ログイン")').click();
  await page.waitForURL("**/");
}

export async function loginAsViewer(page: Page) {
  await page.goto("/login");
  await page.locator('input[name="display_name"]').fill("高橋 大輔");
  await page.locator('input[name="email"]').fill("takahashi@example.com");
  await page.locator('select[name="role"]').selectOption("viewer");
  await page.locator('button:has-text("開発ログイン")').click();
  await page.waitForURL("**/");
}
