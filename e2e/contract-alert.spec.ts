import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("契約更新アラート", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("ダッシュボードに契約更新アラートセクションが表示される", async ({
    page,
  }) => {
    await page.goto("/");
    await expect(page.locator("text=契約更新アラート")).toBeVisible();
  });

  test("期限が近い契約のSaaS名と残日数が表示される", async ({ page }) => {
    await page.goto("/");
    const alertCard = page.locator(".card.border-warning", { has: page.locator("text=契約更新アラート") });
    await expect(alertCard).toBeVisible();
    // テーブルに期限日と残日数バッジが表示される
    await expect(alertCard.locator("table")).toBeVisible();
    await expect(alertCard.locator(".badge")).toHaveCount(
      await alertCard.locator("table tbody tr").count()
    );
  });

  test("バッチ管理画面に契約更新チェックボタンがある", async ({ page }) => {
    await page.goto("/admin/batches");
    await expect(page.locator("text=契約更新チェック")).toBeVisible();
  });
});
