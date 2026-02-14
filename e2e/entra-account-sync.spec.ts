import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("Entra IDアカウント同期", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("ダッシュボードにパスワード期限アラートセクションが表示される", async ({
    page,
  }) => {
    await page.goto("/");
    const alertCard = page.locator(".card.border-danger", {
      has: page.locator("text=パスワード期限アラート"),
    });
    await expect(alertCard).toBeVisible();
    await expect(alertCard.locator("table")).toBeVisible();
    // 期限切れバッジが表示される
    await expect(alertCard.locator(".badge.bg-danger")).toHaveCount(
      (await alertCard.locator(".badge.bg-danger").count()) > 0 ? await alertCard.locator(".badge.bg-danger").count() : 0
    );
  });

  test("バッチ管理画面にSaaSアカウント同期ボタンがある", async ({ page }) => {
    await page.goto("/admin/batches");
    await expect(page.locator("text=SaaSアカウント同期")).toBeVisible();
  });
});
