import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("サーベイ → タスク連携", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("締切済みサーベイの詳細画面に不要アカウントセクションが表示される", async ({
    page,
  }) => {
    // 締切済みサーベイを選択（seedデータにclosedサーベイがある）
    await page.goto("/surveys");
    const closedRow = page.locator("tr", { hasText: "締切済み" }).first();
    await closedRow.locator("a").first().click();
    await expect(page).toHaveURL(/\/surveys\/\d+/);

    // not_using回答があれば不要アカウントセクションが表示される
    const notUsingCard = page.locator(".card.border-danger", {
      has: page.locator("text=不要アカウント"),
    });
    const notUsingCount = await page
      .locator(".badge.bg-danger", { hasText: "利用なし" })
      .count();

    if (notUsingCount > 0) {
      await expect(notUsingCard).toBeVisible();
      await expect(
        notUsingCard.locator('button:has-text("削除タスクを生成")')
      ).toBeVisible();
    }
  });

  test("配信中サーベイの詳細画面で回答ダッシュボードが表示される", async ({
    page,
  }) => {
    await page.goto("/surveys");
    const activeRow = page.locator("tr", { hasText: "配信中" }).first();
    await activeRow.locator("a").first().click();
    await expect(page).toHaveURL(/\/surveys\/\d+/);
    await expect(page.locator("text=対象アカウント数")).toBeVisible();
    await expect(page.locator("text=利用なし回答")).toBeVisible();
  });
});
