import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("コスト可視化", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("ダッシュボードにコスト概要セクションが表示される", async ({ page }) => {
    await page.goto("/");
    const costCard = page.locator(".card", {
      has: page.locator("text=コスト概要"),
    });
    await expect(costCard).toBeVisible();
    await expect(costCard.getByText("月額コスト", { exact: true })).toBeVisible();
    await expect(costCard.getByText("年額コスト", { exact: true })).toBeVisible();
  });

  test("カテゴリ別コスト内訳が表示される", async ({ page }) => {
    await page.goto("/");
    const costCard = page.locator(".card", {
      has: page.locator("text=コスト概要"),
    });
    // カテゴリ名が表示される
    await expect(costCard.locator("text=一般IT")).toBeVisible();
    // 円グラフのcanvasが存在する
    await expect(costCard.locator("canvas#costChart")).toBeVisible();
  });
});
